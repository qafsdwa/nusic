import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/core/bridge/bridge_mapper.dart';
import 'package:muse_player/core/bridge/bridge_models.dart';
import 'package:muse_player/models/song.dart';
import 'package:muse_player/providers/player_provider.dart';

void main() {
  test('Song maps to BridgeTrack and back', () {
    const song = Song(
      id: 'song_001',
      title: 'Midnight Drive',
      artist: 'Google Material Orchestra',
      album: 'Synthetic Waves',
      cover: 'mock://midnight-drive',
      duration: Duration(minutes: 4, seconds: 12),
    );

    final bridgeTrack = BridgeMapper.fromSong(song);

    expect(bridgeTrack.id, song.id);
    expect(bridgeTrack.title, song.title);
    expect(bridgeTrack.durationMs, song.duration.inMilliseconds);
    expect(bridgeTrack.source, BridgeTrackSource.mock);

    final roundTrip = BridgeMapper.toSong(bridgeTrack);
    expect(roundTrip.id, song.id);
    expect(roundTrip.title, song.title);
    expect(roundTrip.duration, song.duration);
  });

  test('PlayerState maps to BridgePlayerSnapshot', () {
    const song = Song(
      id: 'song_002',
      title: '冬日挽歌',
      artist: 'Cytus II',
      album: 'Cytus II Original Soundtrack',
      cover: 'mock://winter-elegy',
      duration: Duration(minutes: 5, seconds: 8),
    );
    final playerState = PlayerState(
      currentSong: song,
      queue: const <Song>[song],
      currentIndex: 0,
      status: PlayerStatus.playing,
      position: const Duration(seconds: 42),
      duration: song.duration,
      volume: 0.8,
      isShuffle: true,
      repeatMode: RepeatMode.all,
    );

    final snapshot = BridgeMapper.fromPlayerState(playerState);

    expect(snapshot.currentTrack?.id, 'song_002');
    expect(snapshot.status, BridgePlaybackStatus.playing);
    expect(snapshot.positionMs, 42000);
    expect(snapshot.durationMs, song.duration.inMilliseconds);
    expect(snapshot.volume, 0.8);
    expect(snapshot.isShuffle, isTrue);
    expect(snapshot.repeatMode, BridgeRepeatMode.all);
    expect(snapshot.queue.single.id, 'song_002');
    expect(snapshot.updatedAtMs, greaterThan(0));
  });
}
