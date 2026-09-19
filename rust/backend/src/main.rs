//! Entry point for the `muse-backend` binary.

use muse_backend::config::Config;
use tokio::sync::watch;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    init_tracing();

    let config = Config::from_env();
    // A watch channel rather than a oneshot: both the server and the player
    // ticker need to observe the same shutdown flag.
    let (_shutdown_tx, shutdown_rx) = watch::channel(false);

    muse_backend::serve(config, shutdown_rx).await
}

/// Installs the tracing subscriber.
///
/// `RUST_LOG` wins when set; otherwise the backend's own modules log at `info`
/// and dependencies stay quiet, so `cargo run` prints the listening address
/// without drowning it in hyper/tower chatter.
fn init_tracing() {
    use tracing_subscriber::EnvFilter;

    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("muse_backend=info,tower_http=warn"));

    tracing_subscriber::fmt().with_env_filter(filter).init();
}
