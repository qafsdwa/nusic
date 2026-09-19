//! `GET /ws/player` — playback state sync over WebSocket.
//!
//! The socket is bidirectional: the client sends [`PlayerCommand`]s and the
//! server pushes [`ServerMessage::State`] whenever the player changes.
//!
//! Each connection runs two independent halves:
//!
//! - a reader that applies incoming commands and queues protocol errors;
//! - a writer that owns the sink and forwards both queued errors and every
//!   published state.
//!
//! They are split because applying a command must not wait on the socket being
//! writable, and a slow client must not block command processing. The reader
//! never touches the sink directly — it hands messages to the writer over a
//! channel — so there is exactly one owner of the socket's write side. Either
//! half ending tears the connection down, so a dropped client cannot leak a
//! task.

use std::sync::Arc;

use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::State;
use axum::response::Response;
use futures_util::stream::{SplitSink, SplitStream};
use futures_util::{SinkExt, StreamExt};
use tokio::sync::{broadcast, mpsc};

use crate::error::ErrorBody;
use crate::models::{PlayerCommand, ServerMessage};
use crate::player::PlayerHub;
use crate::routes::AppState;

/// Depth of the per-connection outbound queue.
///
/// Only error replies go through it, so it is sized for a burst of malformed
/// commands rather than a steady stream.
const OUTBOUND_CAPACITY: usize = 16;

/// Upgrades the request and hands the socket to [`handle_socket`].
pub async fn upgrade(ws: WebSocketUpgrade, State(state): State<AppState>) -> Response {
    ws.on_upgrade(move |socket| handle_socket(socket, state.player))
}

async fn handle_socket(socket: WebSocket, player: Arc<PlayerHub>) {
    let (sender, receiver) = socket.split();
    let (outbound_tx, outbound_rx) = mpsc::channel(OUTBOUND_CAPACITY);
    tracing::debug!("player websocket connected");

    // `select!` on both halves means whichever side ends (client disconnect, or
    // a write failure) tears the whole connection down.
    tokio::select! {
        _ = write_messages(sender, outbound_rx, player.clone()) => {}
        _ = read_commands(receiver, player, outbound_tx) => {}
    }

    tracing::debug!("player websocket disconnected");
}

/// Owns the sink and forwards states plus queued error replies.
///
/// The current state is sent first so a fresh connection is immediately in sync
/// instead of waiting for the next mutation.
async fn write_messages(
    mut sender: SplitSink<WebSocket, Message>,
    mut outbound: mpsc::Receiver<ServerMessage>,
    player: Arc<PlayerHub>,
) {
    let mut states = player.subscribe();

    if !send(&mut sender, &ServerMessage::State(player.snapshot())).await {
        return;
    }

    loop {
        tokio::select! {
            // `recv` only returns `None` once every sender is dropped, which
            // happens when the reader half ends.
            reply = outbound.recv() => match reply {
                Some(message) => {
                    if !send(&mut sender, &message).await {
                        return;
                    }
                }
                None => return,
            },
            state = states.recv() => match state {
                Ok(state) => {
                    if !send(&mut sender, &ServerMessage::State(state)).await {
                        return;
                    }
                }
                // The client fell behind and missed states. Positions are
                // absolute and every push carries the full state, so resyncing
                // from the latest snapshot is enough to recover.
                Err(broadcast::error::RecvError::Lagged(skipped)) => {
                    tracing::warn!(skipped, "websocket client lagged; resending current state");
                    if !send(&mut sender, &ServerMessage::State(player.snapshot())).await {
                        return;
                    }
                }
                // The hub was dropped, which only happens during shutdown.
                Err(broadcast::error::RecvError::Closed) => return,
            },
        }
    }
}

/// Applies commands received from the client.
async fn read_commands(
    mut receiver: SplitStream<WebSocket>,
    player: Arc<PlayerHub>,
    outbound: mpsc::Sender<ServerMessage>,
) {
    while let Some(message) = receiver.next().await {
        let message = match message {
            Ok(message) => message,
            Err(error) => {
                tracing::debug!(%error, "player websocket read error");
                return;
            }
        };

        match message {
            Message::Text(text) => {
                if let Err(reply) = apply_text(text.as_str(), &player) {
                    // If the writer is gone the connection is already closing,
                    // so there is nothing left to do but stop reading.
                    if outbound.send(reply).await.is_err() {
                        return;
                    }
                }
            }
            // Ping/Pong are answered by axum; a close frame ends the loop.
            Message::Close(_) => return,
            _ => {}
        }
    }
}

/// Parses and applies one text frame.
///
/// Returns the message to report back to the client when the command was
/// invalid or rejected.
fn apply_text(text: &str, player: &PlayerHub) -> Result<(), ServerMessage> {
    let command: PlayerCommand = serde_json::from_str(text).map_err(|error| {
        ServerMessage::Error(ErrorBody::new(
            "invalid_command",
            format!("could not parse command: {error}"),
        ))
    })?;

    player
        .apply(command)
        .map(|_| ())
        .map_err(|message| ServerMessage::Error(ErrorBody::new("command_rejected", message)))
}

/// Serializes and sends one message, returning `false` when the socket is gone.
async fn send(sender: &mut SplitSink<WebSocket, Message>, message: &ServerMessage) -> bool {
    let payload = match serde_json::to_string(message) {
        Ok(payload) => payload,
        Err(error) => {
            // Serializing plain structs of owned values cannot realistically
            // fail; log and skip the push rather than kill the connection.
            tracing::error!(%error, "failed to serialize player message");
            return true;
        }
    };

    sender.send(Message::text(payload)).await.is_ok()
}
