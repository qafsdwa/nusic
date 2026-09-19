//! Shared helpers for the integration tests.
//!
//! The tests drive a real server over a real loopback socket instead of calling
//! handlers directly, so routing, query/path extraction, JSON serialization and
//! the WebSocket upgrade are all covered the way the Flutter client will hit
//! them.

#![allow(dead_code)]

use std::net::SocketAddr;
use std::path::Path;
use std::sync::Arc;

use muse_backend::config::Config;
use muse_backend::library::Library;
use muse_backend::routes::AppState;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;
use tokio::task::JoinHandle;

/// A running backend bound to an ephemeral port.
pub struct TestServer {
    pub base_url: String,
    pub ws_url: String,
    pub library: Arc<Library>,
    server_task: JoinHandle<()>,
    ticker_task: JoinHandle<()>,
    /// Kept alive for the server's lifetime: dropping it is the shutdown
    /// signal, and the ticker would stop on its own.
    _shutdown_tx: tokio::sync::watch::Sender<bool>,
}

impl TestServer {
    /// Starts the server with the built-in seed catalog.
    pub async fn seeded() -> Self {
        Self::start(None).await
    }

    /// Starts the server scanning `dir` for audio files.
    pub async fn with_music_dir(dir: &Path) -> Self {
        Self::start(Some(dir.to_path_buf())).await
    }

    async fn start(music_dir: Option<std::path::PathBuf>) -> Self {
        // Bind first: the library embeds the public base URL in its cover
        // links, and that URL is only known once the port is assigned.
        let listener = TcpListener::bind("127.0.0.1:0")
            .await
            .expect("bind ephemeral port");
        let addr: SocketAddr = listener.local_addr().expect("local addr");

        let config = Config {
            bind: addr,
            music_dir,
            public_base_url: format!("http://{addr}"),
            // The engine is injected explicitly below, so the mode here only
            // affects `Config`-driven paths the tests do not take.
            audio: muse_backend::config::AudioMode::Silent,
        };

        let library =
            muse_backend::library::load(config.music_dir.as_deref(), &config.public_base_url);
        // Tests must never grab the sound card: `ClockEngine` keeps the exact
        // same protocol and timing semantics without making noise.
        let player = muse_backend::player::PlayerHub::new(
            library.clone(),
            Arc::new(muse_backend::audio::ClockEngine::new()),
        );
        let router =
            muse_backend::routes::router(AppState::new(&config, library.clone(), player.clone()));

        // The position ticker is part of the real server, so the tests must run
        // it too; otherwise nothing would ever advance a playing track.
        let (shutdown_tx, shutdown_rx) = tokio::sync::watch::channel(false);
        let ticker_task = tokio::spawn(player.run(shutdown_rx));

        let server_task = tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });

        Self {
            base_url: format!("http://{addr}"),
            ws_url: format!("ws://{addr}/ws/player"),
            library,
            server_task,
            ticker_task,
            _shutdown_tx: shutdown_tx,
        }
    }

    /// GETs `path`, returning the status code and decoded body.
    pub async fn get(&self, path: &str) -> HttpResponse {
        let url = format!("{}{path}", self.base_url);
        http_get(&url).await
    }
}

impl Drop for TestServer {
    fn drop(&mut self) {
        self.server_task.abort();
        self.ticker_task.abort();
    }
}

/// Decoded response returned by [`TestServer::get`].
pub struct HttpResponse {
    pub status: u16,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
}

impl HttpResponse {
    pub fn text(&self) -> String {
        String::from_utf8_lossy(&self.body).to_string()
    }

    /// Deserializes the body as JSON.
    pub fn json(&self) -> serde_json::Value {
        serde_json::from_slice(&self.body)
            .unwrap_or_else(|error| panic!("body is not JSON ({error}): {}", self.text()))
    }

    pub fn header(&self, name: &str) -> Option<&str> {
        self.headers
            .iter()
            .find(|(key, _)| key.eq_ignore_ascii_case(name))
            .map(|(_, value)| value.as_str())
    }
}

/// Minimal HTTP/1.1 GET over a raw socket.
///
/// Avoids pulling a full HTTP client into the test dependencies; the responses
/// under test are small and the client only needs to understand
/// `Content-Length` and chunked bodies.
async fn http_get(url: &str) -> HttpResponse {
    let without_scheme = url.strip_prefix("http://").expect("http:// url");
    let (authority, path) = match without_scheme.find('/') {
        Some(index) => (&without_scheme[..index], &without_scheme[index..]),
        None => (without_scheme, "/"),
    };

    let mut stream = tokio::net::TcpStream::connect(authority)
        .await
        .expect("connect to test server");
    let request = format!("GET {path} HTTP/1.1\r\nHost: {authority}\r\nConnection: close\r\n\r\n");
    stream
        .write_all(request.as_bytes())
        .await
        .expect("write request");

    let mut raw = Vec::new();
    stream.read_to_end(&mut raw).await.expect("read response");

    parse_response(&raw)
}

fn parse_response(raw: &[u8]) -> HttpResponse {
    let split = find_header_end(raw).expect("response has a header terminator");
    let head = String::from_utf8_lossy(&raw[..split]).to_string();
    let body = &raw[split + 4..];

    let mut lines = head.lines();
    let status = lines
        .next()
        .and_then(|line| line.split_whitespace().nth(1))
        .and_then(|code| code.parse::<u16>().ok())
        .expect("status line");

    let headers: Vec<(String, String)> = lines
        .filter_map(|line| line.split_once(':'))
        .map(|(key, value)| (key.trim().to_owned(), value.trim().to_owned()))
        .collect();

    let body = if headers.iter().any(|(key, value)| {
        key.eq_ignore_ascii_case("transfer-encoding") && value.contains("chunked")
    }) {
        decode_chunked(body)
    } else {
        body.to_vec()
    };

    HttpResponse {
        status,
        headers,
        body,
    }
}

fn find_header_end(raw: &[u8]) -> Option<usize> {
    raw.windows(4).position(|window| window == b"\r\n\r\n")
}

/// Decodes a chunked transfer-encoded body.
fn decode_chunked(raw: &[u8]) -> Vec<u8> {
    let mut decoded = Vec::new();
    let mut cursor = 0usize;

    while let Some(line_end) = raw[cursor..].windows(2).position(|w| w == b"\r\n") {
        let size_line = String::from_utf8_lossy(&raw[cursor..cursor + line_end]);
        // Chunk extensions are separated from the size by `;`.
        let size = match usize::from_str_radix(size_line.split(';').next().unwrap_or("").trim(), 16)
        {
            Ok(0) => break,
            Ok(size) => size,
            Err(_) => break,
        };

        let start = cursor + line_end + 2;
        decoded.extend_from_slice(&raw[start..start + size]);
        cursor = start + size + 2;
    }

    decoded
}
