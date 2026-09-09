import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/mock_data.dart';
import '../models/song.dart';

enum PlayerStatus { idle, loading, playing, paused, buffering, error }

/// Immutable player UI state.
///
/// This is deliberately decoupled from any real audio engine. Later it can be
/// hydrated by an `audio_service` / `just_audio` playback controller and synced
/// with the Rust backend over WebSocket.
class PlayerState {
  const PlayerState({
    this.currentSong,
    this.queue = const <Song>[],
    this.currentIndex = -1,
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final PlayerStatus status;
  final Duration position;
  final Duration duration;

  bool get isPlaying => status == PlayerStatus.playing;

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    // Start with the first mock song selected but paused so the desktop/mobile
    // mini-player has meaningful demo content.
    final first = MockData.songs.first;
    return PlayerState(
      queue: MockData.songs,
      currentIndex: 0,
      currentSong: first,
      status: PlayerStatus.paused,
      duration: first.duration,
    );
  }

  void playSong(Song song) {
    final index = state.queue.indexWhere((item) => item.id == song.id);
    if (index >= 0) {
      state = state.copyWith(
        currentIndex: index,
        currentSong: state.queue[index],
        status: PlayerStatus.playing,
        position: Duration.zero,
        duration: state.queue[index].duration,
      );
      return;
    }

    final newQueue = <Song>[...state.queue, song];
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
      final first = MockData.songs.first;
      playSong(first);
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
    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    final song = state.queue[nextIndex];
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
    final previousIndex = state.currentIndex > 0
        ? state.currentIndex - 1
        : state.currentIndex;
    final song = state.queue[previousIndex];
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

  void pause() {
    state = state.copyWith(status: PlayerStatus.paused);
  }

  void reset() {
    state = const PlayerState(queue: <Song>[]);
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
