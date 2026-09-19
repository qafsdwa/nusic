//! Integration tests for `ws://…/ws/player`.
//!
//! These drive the socket with a real `tokio-tungstenite` client, which is the
//! same protocol stack the Flutter `web_socket_channel` client speaks, so the
//! upgrade handshake and frame handling are covered for real.

mod common;

use std::time::Duration;

use common::TestServer;
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio::time::timeout;
use tokio_tungstenite::tungstenite::Message;

/// A connected test client.
struct Client {
    socket: tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
}

impl Client {
    async fn connect(server: &TestServer) -> Self {
        let (socket, response) = tokio_tungstenite::connect_async(&server.ws_url)
            .await
            .expect("websocket handshake");
        assert_eq!(response.status().as_u16(), 101, "expected a 101 upgrade");
        Self { socket }
    }

    /// Sends a raw text frame.
    async fn send(&mut self, text: &str) {
        self.socket
            .send(Message::text(text))
            .await
            .expect("send frame");
    }

    /// Sends a command object.
    async fn command(&mut self, command: Value) {
        self.send(&command.to_string()).await;
    }

    /// Reads the next JSON message, failing the test on timeout.
    async fn next_json(&mut self) -> Value {
        let message = timeout(Duration::from_secs(5), self.socket.next())
            .await
            .expect("a message should arrive before the timeout")
            .expect("the socket should stay open")
            .expect("the frame should be valid");

        match message {
            Message::Text(text) => serde_json::from_str(text.as_str()).expect("frame is JSON"),
            other => panic!("expected a text frame, got {other:?}"),
        }
    }

    /// Reads messages until a `state` push satisfying `predicate` arrives.
    ///
    /// Commands can produce more than one push (the immediate one plus a tick),
    /// so tests wait for the state they care about instead of assuming a count.
    async fn wait_for_state(&mut self, predicate: impl Fn(&Value) -> bool) -> Value {
        for _ in 0..32 {
            let message = self.next_json().await;
            if message["type"] == "state" && predicate(&message) {
                return message;
            }
        }
        panic!("no matching state message arrived");
    }
}

#[tokio::test]
async fn connecting_pushes_the_current_state_immediately() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;

    let state = client.next_json().await;
    assert_eq!(state["type"], "state");
    assert_eq!(state["song_id"], "song_001");
    assert_eq!(state["status"], "paused");
    assert_eq!(state["duration_ms"], 252000);
    assert_eq!(state["queue"].as_array().unwrap().len(), 6);
    assert!(state["updated_at_ms"].as_i64().unwrap() > 0);
}

#[tokio::test]
async fn play_command_switches_track_and_reports_playing() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await; // initial state

    client
        .command(json!({ "type": "play", "song_id": "song_002" }))
        .await;

    let state = client
        .wait_for_state(|state| state["song_id"] == "song_002")
        .await;
    assert_eq!(state["status"], "playing");
    assert_eq!(state["duration_ms"], 308000);
}

#[tokio::test]
async fn pause_stops_position_updates() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client
        .command(json!({ "type": "play", "song_id": "song_001" }))
        .await;
    client
        .wait_for_state(|state| state["status"] == "playing")
        .await;

    // Let the ticker move the position at least once while playing.
    let before = client
        .wait_for_state(|state| state["position_ms"].as_i64().unwrap_or(0) > 0)
        .await;

    client.command(json!({ "type": "pause" })).await;
    let paused = client
        .wait_for_state(|state| state["status"] == "paused")
        .await;
    assert!(paused["position_ms"].as_i64().unwrap() >= before["position_ms"].as_i64().unwrap());

    // A paused player must publish nothing further, so this read has to time
    // out rather than deliver a state with a larger position.
    let next = timeout(Duration::from_millis(700), client.socket.next()).await;
    assert!(
        next.is_err(),
        "a paused player should not push position updates, got {next:?}"
    );
}

#[tokio::test]
async fn seek_sets_the_position() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client
        .command(json!({ "type": "seek", "position_ms": 42000 }))
        .await;

    let state = client
        .wait_for_state(|state| state["position_ms"] == 42000)
        .await;
    assert_eq!(state["position_ms"], 42000);
}

#[tokio::test]
async fn next_advances_the_queue() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client.command(json!({ "type": "next" })).await;
    let state = client
        .wait_for_state(|state| state["song_id"] == "song_002")
        .await;
    assert_eq!(state["status"], "playing");
}

#[tokio::test]
async fn volume_and_repeat_are_additive_fields() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client
        .command(json!({ "type": "set_volume", "volume": 0.25 }))
        .await;
    let state = client
        .wait_for_state(|state| (state["volume"].as_f64().unwrap() - 0.25).abs() < 1e-9)
        .await;
    assert_eq!(state["volume"], 0.25);

    client
        .command(json!({ "type": "set_repeat", "mode": "all" }))
        .await;
    let state = client
        .wait_for_state(|state| state["repeat_mode"] == "all")
        .await;
    assert_eq!(state["repeat_mode"], "all");
}

#[tokio::test]
async fn request_state_returns_a_snapshot() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client.command(json!({ "type": "request_state" })).await;
    let state = client
        .wait_for_state(|state| state["type"] == "state")
        .await;
    assert_eq!(state["song_id"], "song_001");
}

#[tokio::test]
async fn unknown_command_type_reports_an_error() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client.command(json!({ "type": "explode" })).await;

    let error = client.next_json().await;
    assert_eq!(error["type"], "error");
    assert_eq!(error["code"], "invalid_command");
}

#[tokio::test]
async fn malformed_json_reports_an_error_without_closing_the_socket() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client.send("this is not json").await;
    let error = client.next_json().await;
    assert_eq!(error["type"], "error");
    assert_eq!(error["code"], "invalid_command");

    // The connection must survive a bad frame.
    client.command(json!({ "type": "request_state" })).await;
    let state = client
        .wait_for_state(|state| state["type"] == "state")
        .await;
    assert_eq!(state["song_id"], "song_001");
}

#[tokio::test]
async fn unknown_song_id_is_rejected_without_changing_state() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client
        .command(json!({ "type": "play", "song_id": "ghost" }))
        .await;
    let error = client.next_json().await;
    assert_eq!(error["type"], "error");
    assert_eq!(error["code"], "command_rejected");
    assert!(error["message"]
        .as_str()
        .unwrap()
        .contains("unknown song id"));

    client.command(json!({ "type": "request_state" })).await;
    let state = client
        .wait_for_state(|state| state["type"] == "state")
        .await;
    assert_eq!(state["song_id"], "song_001");
}

#[tokio::test]
async fn state_changes_reach_every_connected_client() {
    let server = TestServer::seeded().await;
    let mut first = Client::connect(&server).await;
    let mut second = Client::connect(&server).await;
    first.next_json().await;
    second.next_json().await;

    first
        .command(json!({ "type": "play", "song_id": "song_005" }))
        .await;

    for client in [&mut first, &mut second] {
        let state = client
            .wait_for_state(|state| state["song_id"] == "song_005")
            .await;
        assert_eq!(state["status"], "playing");
    }
}

#[tokio::test]
async fn play_queue_replaces_the_queue() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client
        .command(json!({
            "type": "play_queue",
            "song_ids": ["song_003", "song_004"],
            "start_index": 1
        }))
        .await;

    let state = client
        .wait_for_state(|state| state["queue"].as_array().map(|q| q.len()) == Some(2))
        .await;
    assert_eq!(state["song_id"], "song_004");
    assert_eq!(state["queue"], json!(["song_003", "song_004"]));
}

#[tokio::test]
async fn positions_advance_while_playing() {
    let server = TestServer::seeded().await;
    let mut client = Client::connect(&server).await;
    client.next_json().await;

    client
        .command(json!({ "type": "play", "song_id": "song_006" }))
        .await;
    client
        .wait_for_state(|state| state["status"] == "playing")
        .await;

    // The ticker runs at 250ms, so a few ticks must move the position forward.
    let advanced = client
        .wait_for_state(|state| state["position_ms"].as_i64().unwrap_or(0) > 0)
        .await;
    assert!(advanced["position_ms"].as_i64().unwrap() > 0);
}
