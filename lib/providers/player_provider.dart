import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bridge/generated/api/bridge_models.dart';
import '../core/bridge/rust_player.dart';
import '../core/config/app_config.dart';
import '../core/config/app_config_provider.dart';
import '../mock/mock_music.dart';
import '../models/song.dart';

enum PlayerStatus { idle, loading, playing, paused, buffering, error }

enum RepeatMode { off, all, one }

/// Immutable player UI state.
///
/// This is deliberately decoupled from any real audio engine. Later it can be
/// hydrated by a real playback controller and synced with the Rust backend
/// over WebSocket.
class PlayerState {
  const PlayerState({
    this.currentSong,
    this.queue = const <Song>[],
    this.currentIndex = -1,
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 0.7,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.off,
  });

  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isShuffle;
  final RepeatMode repeatMode;

  bool get isPlaying => status == PlayerStatus.playing;

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isShuffle,
    RepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  /// True once the in-process Rust engine is live.
  ///
  /// Until then the notifier owns playback locally, which is both the Phase 1
  /// behaviour and the fallback when the native library cannot be loaded.
  bool _engineReady = false;
  StreamSubscription<BridgePlayerSnapshot>? _remoteSubscription;
  bool _disposed = false;

  /// Online tracks whose audio has already been downloaded this session.
  ///
  /// Rust caches the audio per track as well, so this only avoids a redundant
  /// round trip and the loading flicker that would come with it.
  final Set<String> _preparedTracks = <String>{};

  @override
  PlayerState build() {
    final AppConfig config = ref.read(appConfigProvider);
    final List<Song> songs = MockMusic.songs;
    final Song first = songs.first;

    ref.onDispose(_teardown);

    if (config.enableNetwork) {
      // `build` cannot await, so the local state below is the placeholder until
      // the first backend push arrives — and it is simply what the user keeps
      // if the backend never answers.
      unawaited(_connectToEngine());
    }

    // Phase 1 starts with the first mock song paused so the floating player
    // has meaningful demo content on every platform. Initial volume, shuffle
    // and repeat mode come from the startup config file.
    return PlayerState(
      queue: songs,
      currentIndex: 0,
      currentSong: first,
      status: PlayerStatus.paused,
      duration: first.duration,
      volume: config.player.initialVolume,
      isShuffle: config.player.defaultShuffle,
      repeatMode: _parseRepeatMode(config.player.defaultRepeatMode),
    );
  }

  /// Starts [song].
  ///
  /// Online tracks are prepared first — their audio is downloaded into the Rust
  /// cache before the engine can load it — so the wait happens here, where the
  /// UI can show it. The future completes with a user-facing message when that
  /// preparation failed and with `null` otherwise; callers that can surface the
  /// reason (the search page) await it, and the rest ignore it.
  Future<String?> play(Song song) async {
    if (_engineReady) {
      if (song.isRemote && !_preparedTracks.contains(song.id)) {
        final String? failure = await _prepareOnline(song);
        if (failure != null) {
          return failure;
        }
      }

      // Rust owns the queue, so the resulting state arrives as a push rather
      // than being predicted here.
      _send(BridgePlayerCommand.play(trackId: song.id));
      return null;
    }

    final int index = state.queue.indexWhere((Song item) => item.id == song.id);
    if (index >= 0) {
      final Song queuedSong = state.queue[index];
      state = state.copyWith(
        currentIndex: index,
        currentSong: queuedSong,
        status: PlayerStatus.playing,
        position: Duration.zero,
        duration: queuedSong.duration,
      );
      return null;
    }

    final List<Song> newQueue = <Song>[...state.queue, song];
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newQueue.length - 1,
      currentSong: song,
      status: PlayerStatus.playing,
      position: Duration.zero,
      duration: song.duration,
    );
    return null;
  }

  /// Downloads an online track so the engine can load it.
  ///
  /// Returns a user-facing message on failure, or `null` once the audio is in
  /// the Rust cache.
  Future<String?> _prepareOnline(Song song) async {
    // The engine cannot report "downloading", so the mirrored state carries the
    // hint until the command produces its first push.
    state = state.copyWith(status: PlayerStatus.loading);

    try {
      await const RustPlayer().prepareTrack(song.id);
      _preparedTracks.add(song.id);
      return null;
    } catch (error) {
      state = state.copyWith(status: PlayerStatus.error);
      return '在线播放准备失败：$error';
    }
  }

  /// Queues [song] to play directly after the current track.
  ///
  /// Does not change what is playing. If the song is already in the queue it is
  /// moved rather than duplicated, which is what the menu item reads as.
  void playNext(Song song) {
    if (_engineReady) {
      // The bridge contract has no "insert next" command yet. Editing only the
      // local queue would be silently reverted by the next push, which is worse
      // than doing nothing.
      return;
    }

    if (state.currentSong == null) {
      play(song);
      return;
    }
    if (state.currentSong!.id == song.id) {
      // Already playing: "next" would mean moving the current track past
      // itself, which has no meaning.
      return;
    }

    final List<Song> queue = <Song>[
      for (final Song item in state.queue)
        if (item.id != song.id) item,
    ];

    // The current track is still in [queue] (it was not the song removed), and
    // removing an earlier entry shifts its index down, so the insertion point
    // has to be recomputed rather than reused from [PlayerState.currentIndex].
    final int currentIndex = queue.indexWhere(
      (Song item) => item.id == state.currentSong!.id,
    );

    queue.insert(currentIndex + 1, song);
    state = state.copyWith(queue: queue, currentIndex: currentIndex);
  }

  /// Appends [song] to the end of the queue.
  ///
  /// A song already queued is left alone rather than added twice, so repeated
  /// taps cannot silently bloat the queue.
  void addToQueue(Song song) {
    if (_engineReady) {
      // See `playNext`: no append command in the contract yet.
      return;
    }

    if (state.queue.any((Song item) => item.id == song.id)) {
      return;
    }

    final List<Song> queue = <Song>[...state.queue, song];
    if (state.currentSong != null) {
      state = state.copyWith(queue: queue);
      return;
    }

    // Nothing was playing, so the appended song becomes the current one.
    state = state.copyWith(
      queue: queue,
      currentIndex: queue.length - 1,
      currentSong: song,
      duration: song.duration,
    );
  }

  void togglePlayPause() {
    if (_engineReady) {
      _send(const BridgePlayerCommand.toggle());
      return;
    }

    if (state.currentSong == null) {
      play(MockMusic.songs.first);
      return;
    }

    state = state.copyWith(
      status: state.isPlaying ? PlayerStatus.paused : PlayerStatus.playing,
    );
  }

  void next() {
    if (_engineReady) {
      _send(const BridgePlayerCommand.next());
      return;
    }

    if (state.queue.isEmpty) {
      return;
    }

    if (state.repeatMode == RepeatMode.one && state.currentSong != null) {
      state = state.copyWith(
        status: PlayerStatus.playing,
        position: Duration.zero,
      );
      return;
    }

    final int nextIndex = state.isShuffle
        ? _randomNextIndex()
        : (state.currentIndex + 1) % state.queue.length;
    final Song song = state.queue[nextIndex];
    state = state.copyWith(
      currentIndex: nextIndex,
      currentSong: song,
      status: PlayerStatus.playing,
      position: Duration.zero,
      duration: song.duration,
    );
  }

  void previous() {
    if (_engineReady) {
      _send(const BridgePlayerCommand.previous());
      return;
    }

    if (state.queue.isEmpty) {
      return;
    }

    // When the song has been playing for more than a few seconds, "previous"
    // restarts the current track first — a common music player behavior.
    if (state.position.inSeconds > 3) {
      state = state.copyWith(position: Duration.zero);
      return;
    }

    final int previousIndex = state.currentIndex > 0
        ? state.currentIndex - 1
        : 0;
    final Song song = state.queue[previousIndex];
    state = state.copyWith(
      currentIndex: previousIndex,
      currentSong: song,
      status: PlayerStatus.playing,
      position: Duration.zero,
      duration: song.duration,
    );
  }

  void seek(Duration position) {
    if (_engineReady) {
      _send(BridgePlayerCommand.seek(positionMs: position.inMilliseconds));
      return;
    }

    state = state.copyWith(position: position);
  }

  void setVolume(double volume) {
    final double clamped = volume.clamp(0.0, 1.0);
    if (_engineReady) {
      _send(BridgePlayerCommand.setVolume(volume: clamped));
      return;
    }

    state = state.copyWith(volume: clamped);
  }

  void toggleShuffle() {
    if (_engineReady) {
      // Derived from the last pushed state: Rust is the source of truth, so
      // there is nothing local to flip.
      _send(BridgePlayerCommand.setShuffle(enabled: !state.isShuffle));
      return;
    }

    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void cycleRepeatMode() {
    final RepeatMode nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };

    if (_engineReady) {
      _send(BridgePlayerCommand.setRepeat(mode: _remoteRepeatMode(nextMode)));
      return;
    }

    state = state.copyWith(repeatMode: nextMode);
  }

  void pause() {
    if (_engineReady) {
      _send(const BridgePlayerCommand.pause());
      return;
    }

    state = state.copyWith(status: PlayerStatus.paused);
  }

  /// Loads the native library and mirrors the Rust player's pushes into [state].
  ///
  /// A native library that cannot be loaded is not an error the user needs to
  /// see: the local mock player keeps working, and only a debug log records why.
  Future<void> _connectToEngine() async {
    try {
      await RustPlayer.bootstrap(
        volume: ref.read(appConfigProvider).player.initialVolume,
      );
    } catch (error) {
      // Deliberately catch everything: a missing or ABI-mismatched `cdylib`
      // must still leave the user with a working local player.
      debugPrint(
        'Muse: Rust engine unavailable, using local playback ($error)',
      );
      return;
    }

    if (_disposed) {
      return;
    }

    _engineReady = true;
    _remoteSubscription = const RustPlayer().states.listen(_applyRemote);
  }

  /// Forwards one command to Rust.
  ///
  /// The result arrives through [states], so the return value is only used to
  /// surface failures.
  void _send(BridgePlayerCommand command) {
    unawaited(() async {
      try {
        await const RustPlayer().send(command);
      } catch (error) {
        debugPrint('Muse: player command failed ($error)');
      }
    }());
  }

  /// Replaces the local state with a Rust snapshot.
  ///
  /// Built directly rather than through `copyWith`, because `copyWith` treats
  /// `null` as "keep the existing value" and Rust legitimately reports no
  /// current track for an empty queue.
  void _applyRemote(BridgePlayerSnapshot remote) {
    if (_disposed) {
      return;
    }

    state = PlayerState(
      currentSong: remote.currentTrack == null
          ? null
          : songFromTrack(remote.currentTrack!),
      queue: remote.queue.map(songFromTrack).toList(growable: false),
      currentIndex: remote.currentIndex,
      status: _playerStatusFromRemote(remote.status),
      position: Duration(milliseconds: remote.positionMs.toInt()),
      duration: Duration(milliseconds: remote.durationMs.toInt()),
      volume: remote.volume,
      isShuffle: remote.isShuffle,
      repeatMode: _repeatModeFromRemote(remote.repeatMode),
    );
  }

  void _teardown() {
    _disposed = true;
    _remoteSubscription?.cancel();
    _remoteSubscription = null;
    _engineReady = false;
  }

  PlayerStatus _playerStatusFromRemote(BridgePlaybackStatus status) {
    return switch (status) {
      BridgePlaybackStatus.idle => PlayerStatus.idle,
      BridgePlaybackStatus.loading => PlayerStatus.loading,
      BridgePlaybackStatus.playing => PlayerStatus.playing,
      BridgePlaybackStatus.paused => PlayerStatus.paused,
      BridgePlaybackStatus.buffering => PlayerStatus.buffering,
      BridgePlaybackStatus.error => PlayerStatus.error,
    };
  }

  RepeatMode _repeatModeFromRemote(BridgeRepeatMode mode) {
    return switch (mode) {
      BridgeRepeatMode.off => RepeatMode.off,
      BridgeRepeatMode.all => RepeatMode.all,
      BridgeRepeatMode.one => RepeatMode.one,
    };
  }

  BridgeRepeatMode _remoteRepeatMode(RepeatMode mode) {
    return switch (mode) {
      RepeatMode.off => BridgeRepeatMode.off,
      RepeatMode.all => BridgeRepeatMode.all,
      RepeatMode.one => BridgeRepeatMode.one,
    };
  }

  RepeatMode _parseRepeatMode(String value) {
    return switch (value) {
      'all' => RepeatMode.all,
      'one' => RepeatMode.one,
      _ => RepeatMode.off,
    };
  }

  int _randomNextIndex() {
    if (state.queue.length <= 1) {
      return 0;
    }
    final int next = math.Random().nextInt(state.queue.length);
    return next == state.currentIndex ? (next + 1) % state.queue.length : next;
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
