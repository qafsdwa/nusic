// Muse Player Rust backend: audio engine, REST / WebSocket surface, and the
// in-process flutter_rust_bridge API the Flutter app links against.
//
// The public surface is [`build_router`] plus [`serve`] for the HTTP front-end,
// and [`api`] for the FFI front-end. Both sit on the same library and player
// implementation, so the two paths cannot behave differently.
//
// The JSON shapes are the contract in `docs/backend-api.md`; where that
// document is silent (volume, shuffle, repeat, error bodies) the shapes are
// additive, so an older client that ignores them keeps working.
//
// `//` comments rather than `//!`: FRB injects `mod frb_generated;` at the top
// of this file, and an inner doc comment after an item is E0753.

mod frb_generated;

pub mod api;
pub mod audio;
pub mod config;
pub mod cover;
pub mod error;
pub mod library;
pub mod models;
pub mod online;
pub mod player;
pub mod routes;

/// Process-wide state behind the FFI surface. Deliberately outside `api/`:
/// everything under `api` is scanned by flutter_rust_bridge and becomes part of
/// the generated Dart API, which this must not.
pub(crate) mod runtime;

use std::path::Path;
use std::sync::Arc;

use anyhow::Context;
use tokio::net::TcpListener;
use tokio::sync::watch;

use crate::audio::{AudioEngine, ClockEngine, RodioEngine};
use crate::config::{AudioMode, Config, ENV_AUDIO};
use crate::library::Library;
use crate::player::PlayerHub;
use crate::routes::AppState;

/// Builds the fully wired router for `config`.
///
/// Split from [`serve`] so tests can build a router without binding a socket.
pub fn build_router(config: &Config) -> axum::Router {
    let library = library::load(config.music_dir.as_deref(), &config.public_base_url);
    build_router_with_library(config, library)
}

/// Builds the router against an explicit library, bypassing the directory scan.
pub fn build_router_with_library(config: &Config, library: Arc<Library>) -> axum::Router {
    let player = PlayerHub::new(library.clone(), open_engine(config));
    routes::router(AppState::new(config, library, player))
}

/// Opens the playback backend selected by `config`.
///
/// Never fails: a backend that cannot start degrades to [`ClockEngine`] so the
/// API stays usable, and the reason is logged.
pub fn open_engine(config: &Config) -> Arc<dyn AudioEngine> {
    match config.audio {
        AudioMode::Silent => {
            tracing::info!(
                variable = ENV_AUDIO,
                "audio output disabled; the playhead is virtual"
            );
            Arc::new(ClockEngine::new())
        }
        AudioMode::Rodio => match RodioEngine::open() {
            Ok(engine) => {
                tracing::info!(engine = engine.name(), "audio output ready");
                Arc::new(engine)
            }
            Err(error) => {
                tracing::error!(
                    %error,
                    "cannot open the audio device; falling back to the silent clock engine"
                );
                Arc::new(ClockEngine::new())
            }
        },
        AudioMode::Auto => audio::open_default_engine(),
    }
}

/// Binds `config.bind` and serves until `shutdown` resolves.
///
/// The player's position ticker is spawned here rather than in the router so a
/// test that never calls [`serve`] does not leave a background task running.
pub async fn serve(config: Config, shutdown: watch::Receiver<bool>) -> anyhow::Result<()> {
    let library = library::load(config.music_dir.as_deref(), &config.public_base_url);
    let player = PlayerHub::new(library.clone(), open_engine(&config));

    let listener = TcpListener::bind(config.bind)
        .await
        .with_context(|| format!("failed to bind {}", config.bind))?;
    let local_addr = listener
        .local_addr()
        .context("failed to read local address")?;
    tracing::info!(
        address = %local_addr,
        songs = library.tracks().len(),
        engine = player.engine_name(),
        "muse backend listening"
    );

    let ticker = tokio::spawn(player.clone().run(shutdown.clone()));

    let router = routes::router(AppState::new(&config, library, player));
    let result = axum::serve(listener, router)
        .with_graceful_shutdown(shutdown_signal(shutdown))
        .await
        .context("http server failed");

    ticker.abort();
    result
}

/// Resolves when `shutdown` is set, or when Ctrl-C is received.
async fn shutdown_signal(mut shutdown: watch::Receiver<bool>) {
    // `changed` resolves on every send, so keep waiting until the flag is
    // actually `true` (or the sender is dropped, which also means shutdown).
    loop {
        tokio::select! {
            result = shutdown.changed() => {
                if result.is_err() || *shutdown.borrow() {
                    break;
                }
            }
            _ = tokio::signal::ctrl_c() => break,
        }
    }
    tracing::info!("shutting down");
}

/// Convenience for `main.rs` and tests: build a library from a music directory.
pub fn library_from_dir(dir: Option<&Path>, public_base_url: &str) -> Arc<Library> {
    library::load(dir, public_base_url)
}
