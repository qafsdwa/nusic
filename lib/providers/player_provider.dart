import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  PlayerState build() {
    final AppConfig config = ref.read(appConfigProvider);
    final List<Song> songs = MockMusic.songs;
    final Song first = songs.first;

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

  void play(Song song) {
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
      return;
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
  }

  void togglePlayPause() {
    if (state.currentSong == null) {
      play(MockMusic.songs.first);
      return;
    }

    state = state.copyWith(
      status: state.isPlaying ? PlayerStatus.paused : PlayerStatus.playing,
    );
  }

  void next() {
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
    state = state.copyWith(position: position);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void cycleRepeatMode() {
    final RepeatMode nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
  }

  void pause() {
    state = state.copyWith(status: PlayerStatus.paused);
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
