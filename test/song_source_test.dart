import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/core/bridge/generated/api/bridge_models.dart';
import 'package:muse_player/core/bridge/rust_player.dart';
import 'package:muse_player/models/song.dart';

/// The UI only has to tell "can the engine load this now" apart, which is what
/// [Song.isRemote] answers; these tests pin the mapping it is derived from.
void main() {
  BridgeTrack track(BridgeTrackSource source) {
    return BridgeTrack(
      id: 'bili_BV1xx411c7mD',
      title: '示例曲目',
      artist: 'UP',
      album: '分区',
      coverUrl: 'https://i0.hdslb.com/a.jpg',
      durationMs: 205000,
      source: source,
    );
  }

  test('every contract source maps onto a UI source', () {
    expect(
      songFromTrack(track(BridgeTrackSource.local)).source,
      SongSource.local,
    );
    expect(
      songFromTrack(track(BridgeTrackSource.remote)).source,
      SongSource.remote,
    );
    expect(
      songFromTrack(track(BridgeTrackSource.mock)).source,
      SongSource.mock,
    );
    expect(
      songFromTrack(track(BridgeTrackSource.unknown)).source,
      SongSource.unknown,
    );
  });

  test('the online fields survive the projection', () {
    final Song song = songFromTrack(track(BridgeTrackSource.remote));

    expect(song.id, 'bili_BV1xx411c7mD');
    expect(song.cover, 'https://i0.hdslb.com/a.jpg');
    expect(song.duration, const Duration(milliseconds: 205000));
  });

  test('only online tracks need preparing before playback', () {
    expect(songFromTrack(track(BridgeTrackSource.remote)).isRemote, isTrue);
    expect(songFromTrack(track(BridgeTrackSource.local)).isRemote, isFalse);
    expect(songFromTrack(track(BridgeTrackSource.mock)).isRemote, isFalse);

    // Hand-written entries keep the default and never take the online path.
    const Song handwritten = Song(
      id: 'song_001',
      title: 'Midnight Drive',
      artist: 'Google Material Orchestra',
      album: 'Synthetic Waves',
      cover: 'mock://midnight-drive',
      duration: Duration(minutes: 4, seconds: 12),
    );
    expect(handwritten.source, SongSource.local);
    expect(handwritten.isRemote, isFalse);
  });
}
