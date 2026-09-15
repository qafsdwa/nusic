import '../../models/song.dart';
import '../../providers/player_provider.dart';
import 'bridge_models.dart';

/// Maps between UI models (`Song`, `PlayerState`) and the Rust-facing contract.
///
/// Keeping conversion in one place means the generated FRB classes can change
/// later without forcing every widget/provider to know about millisecond
/// timestamps, nullable cover URLs or bridge-only enums.
abstract final class BridgeMapper {
  static BridgeTrack fromSong(Song song) {
    return BridgeTrack(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      coverUrl: song.cover.isEmpty ? null : song.cover,
      durationMs: song.duration.inMilliseconds,
      source: _sourceFromCover(song.cover),
    );
  }

  static Song toSong(BridgeTrack track) {
    return Song(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      cover: track.coverUrl ?? '',
      duration: Duration(milliseconds: track.durationMs),
    );
  }

  static BridgePlayerSnapshot fromPlayerState(PlayerState state) {
    return BridgePlayerSnapshot(
      currentTrack: state.currentSong == null
          ? null
          : fromSong(state.currentSong!),
      status: fromPlayerStatus(state.status),
      positionMs: state.position.inMilliseconds,
      durationMs: state.duration.inMilliseconds,
      volume: state.volume,
      isShuffle: state.isShuffle,
      repeatMode: fromRepeatMode(state.repeatMode),
      queue: state.queue.map(fromSong).toList(growable: false),
      currentIndex: state.currentIndex,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BridgePlaybackStatus fromPlayerStatus(PlayerStatus status) {
    return switch (status) {
      PlayerStatus.idle => BridgePlaybackStatus.idle,
      PlayerStatus.loading => BridgePlaybackStatus.loading,
      PlayerStatus.playing => BridgePlaybackStatus.playing,
      PlayerStatus.paused => BridgePlaybackStatus.paused,
      PlayerStatus.buffering => BridgePlaybackStatus.buffering,
      PlayerStatus.error => BridgePlaybackStatus.error,
    };
  }

  static PlayerStatus toPlayerStatus(BridgePlaybackStatus status) {
    return switch (status) {
      BridgePlaybackStatus.idle => PlayerStatus.idle,
      BridgePlaybackStatus.loading => PlayerStatus.loading,
      BridgePlaybackStatus.playing => PlayerStatus.playing,
      BridgePlaybackStatus.paused => PlayerStatus.paused,
      BridgePlaybackStatus.buffering => PlayerStatus.buffering,
      BridgePlaybackStatus.error => PlayerStatus.error,
    };
  }

  static BridgeRepeatMode fromRepeatMode(RepeatMode mode) {
    return switch (mode) {
      RepeatMode.off => BridgeRepeatMode.off,
      RepeatMode.all => BridgeRepeatMode.all,
      RepeatMode.one => BridgeRepeatMode.one,
    };
  }

  static RepeatMode toRepeatMode(BridgeRepeatMode mode) {
    return switch (mode) {
      BridgeRepeatMode.off => RepeatMode.off,
      BridgeRepeatMode.all => RepeatMode.all,
      BridgeRepeatMode.one => RepeatMode.one,
    };
  }

  static BridgeTrackSource _sourceFromCover(String cover) {
    if (cover.startsWith('mock://')) {
      return BridgeTrackSource.mock;
    }
    if (cover.isEmpty) {
      return BridgeTrackSource.unknown;
    }
    return BridgeTrackSource.remote;
  }
}
