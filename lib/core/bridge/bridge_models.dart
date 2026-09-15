/// Hand-written Dart mirror of the Rust `bridge_models.rs` contract.
///
/// This gives the Flutter side a stable, testable shape before
/// `flutter_rust_bridge_codegen` generates the final `lib/core/bridge/generated`
/// bindings. Keep the names and field semantics aligned with Rust; the mapper
/// in `bridge_mapper.dart` is the only place that should know how FRB values
/// are adapted to the UI models.
library;

enum BridgeTrackSource { local, remote, mock, unknown }

enum BridgePlaybackStatus { idle, loading, playing, paused, buffering, error }

enum BridgeRepeatMode { off, all, one }

enum BridgeErrorCode {
  unknown,
  notInitialized,
  invalidTrack,
  audioOutput,
  network,
  decode,
  unsupported,
  cancelled,
}

class BridgeTrack {
  const BridgeTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    this.coverUrl,
    this.source = BridgeTrackSource.unknown,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String? coverUrl;
  final int durationMs;
  final BridgeTrackSource source;
}

class BridgePlayerSnapshot {
  const BridgePlayerSnapshot({
    required this.currentTrack,
    required this.status,
    required this.positionMs,
    required this.durationMs,
    required this.volume,
    required this.isShuffle,
    required this.repeatMode,
    required this.queue,
    required this.currentIndex,
    required this.updatedAtMs,
  });

  final BridgeTrack? currentTrack;
  final BridgePlaybackStatus status;
  final int positionMs;
  final int durationMs;
  final double volume;
  final bool isShuffle;
  final BridgeRepeatMode repeatMode;
  final List<BridgeTrack> queue;
  final int currentIndex;
  final int updatedAtMs;

  BridgePlayerSnapshot copyWith({
    BridgeTrack? currentTrack,
    BridgePlaybackStatus? status,
    int? positionMs,
    int? durationMs,
    double? volume,
    bool? isShuffle,
    BridgeRepeatMode? repeatMode,
    List<BridgeTrack>? queue,
    int? currentIndex,
    int? updatedAtMs,
  }) {
    return BridgePlayerSnapshot(
      currentTrack: currentTrack ?? this.currentTrack,
      status: status ?? this.status,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      volume: volume ?? this.volume,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}

class BridgeError {
  const BridgeError({required this.code, required this.message, this.details});

  final BridgeErrorCode code;
  final String message;
  final String? details;
}

class BridgeInitConfig {
  const BridgeInitConfig({
    required this.enableNetwork,
    required this.defaultVolume,
    this.backendBaseUrl,
    this.cacheDir,
  });

  final bool enableNetwork;
  final String? backendBaseUrl;
  final String? cacheDir;
  final double defaultVolume;
}

class BridgeLyricLine {
  const BridgeLyricLine({required this.startMs, required this.text});

  final int startMs;
  final String text;
}

/// Commands sent from Flutter to Rust.
sealed class BridgePlayerCommand {
  const BridgePlayerCommand();
}

class BridgePlayCommand extends BridgePlayerCommand {
  const BridgePlayCommand({required this.trackId});
  final String trackId;
}

class BridgePlayTrackCommand extends BridgePlayerCommand {
  const BridgePlayTrackCommand({required this.track});
  final BridgeTrack track;
}

class BridgePlayQueueCommand extends BridgePlayerCommand {
  const BridgePlayQueueCommand({
    required this.tracks,
    required this.startIndex,
  });
  final List<BridgeTrack> tracks;
  final int startIndex;
}

class BridgePauseCommand extends BridgePlayerCommand {
  const BridgePauseCommand();
}

class BridgeResumeCommand extends BridgePlayerCommand {
  const BridgeResumeCommand();
}

class BridgeToggleCommand extends BridgePlayerCommand {
  const BridgeToggleCommand();
}

class BridgeNextCommand extends BridgePlayerCommand {
  const BridgeNextCommand();
}

class BridgePreviousCommand extends BridgePlayerCommand {
  const BridgePreviousCommand();
}

class BridgeSeekCommand extends BridgePlayerCommand {
  const BridgeSeekCommand({required this.positionMs});
  final int positionMs;
}

class BridgeSetVolumeCommand extends BridgePlayerCommand {
  const BridgeSetVolumeCommand({required this.volume});
  final double volume;
}

class BridgeSetShuffleCommand extends BridgePlayerCommand {
  const BridgeSetShuffleCommand({required this.enabled});
  final bool enabled;
}

class BridgeSetRepeatCommand extends BridgePlayerCommand {
  const BridgeSetRepeatCommand({required this.mode});
  final BridgeRepeatMode mode;
}

class BridgeClearQueueCommand extends BridgePlayerCommand {
  const BridgeClearQueueCommand();
}

class BridgeRequestSnapshotCommand extends BridgePlayerCommand {
  const BridgeRequestSnapshotCommand();
}

/// Events streamed from Rust back to Flutter.
sealed class BridgePlayerEvent {
  const BridgePlayerEvent();
}

class BridgeSnapshotEvent extends BridgePlayerEvent {
  const BridgeSnapshotEvent({required this.snapshot});
  final BridgePlayerSnapshot snapshot;
}

class BridgePositionChangedEvent extends BridgePlayerEvent {
  const BridgePositionChangedEvent({
    required this.positionMs,
    required this.durationMs,
  });
  final int positionMs;
  final int durationMs;
}

class BridgeStatusChangedEvent extends BridgePlayerEvent {
  const BridgeStatusChangedEvent({required this.status});
  final BridgePlaybackStatus status;
}

class BridgeTrackChangedEvent extends BridgePlayerEvent {
  const BridgeTrackChangedEvent({required this.track, required this.index});
  final BridgeTrack track;
  final int index;
}

class BridgeQueueChangedEvent extends BridgePlayerEvent {
  const BridgeQueueChangedEvent({
    required this.tracks,
    required this.currentIndex,
  });
  final List<BridgeTrack> tracks;
  final int currentIndex;
}

class BridgeVolumeChangedEvent extends BridgePlayerEvent {
  const BridgeVolumeChangedEvent({required this.volume});
  final double volume;
}

class BridgeErrorEvent extends BridgePlayerEvent {
  const BridgeErrorEvent({required this.error});
  final BridgeError error;
}
