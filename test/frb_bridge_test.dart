import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/core/bridge/generated/api/bridge_models.dart';
import 'package:muse_player/core/bridge/generated/api/library.dart';
import 'package:muse_player/core/bridge/generated/api/online.dart';
import 'package:muse_player/core/bridge/generated/api/player.dart';
import 'package:muse_player/core/bridge/generated/frb_generated.dart';

/// In-process bridge tests.
///
/// These load the real `cdylib` and call the real Rust code, so they cover the
/// FFI path end to end: codegen shape, codec, and the engine behind it. No
/// server, no socket, no JSON.
void main() {
  setUpAll(() async {
    // The generated loader already points at
    // `rust/backend/target/release/`, so tests and the app resolve the same
    // `libmuse_backend` the build produced.
    await RustLib.init();
    // No music directory: the seed catalog. Volume 0 so the test is silent.
    await init(volume: 0.0);
  });

  test('search reaches the Rust catalog in-process', () async {
    final List<BridgeTrack> songs = await searchSongs(query: 'midnight');

    expect(songs, hasLength(1));
    expect(songs.first.id, 'song_001');
    expect(songs.first.title, 'Midnight Drive');
    expect(songs.first.durationMs, 252000);
    expect(songs.first.source, BridgeTrackSource.mock);
  });

  test('an empty query returns the whole catalog', () async {
    expect(await searchSongs(query: ''), hasLength(6));
    expect(await playlist(), hasLength(6));
  });

  test('the player starts paused on the first track', () async {
    final BridgePlayerSnapshot state = await snapshot();

    expect(state.currentTrack?.id, 'song_001');
    expect(state.status, BridgePlaybackStatus.paused);
    expect(state.queue, hasLength(6));
    expect(state.currentIndex, 0);
  });

  test('commands drive the Rust player directly', () async {
    final BridgePlayerSnapshot playing = await command(
      command: const BridgePlayerCommand.play(trackId: 'song_002'),
    );

    expect(playing.currentTrack?.id, 'song_002');
    expect(playing.status, BridgePlaybackStatus.playing);
    expect(playing.durationMs, 308000);

    final BridgePlayerSnapshot paused = await command(
      command: const BridgePlayerCommand.pause(),
    );
    expect(paused.status, BridgePlaybackStatus.paused);
  });

  test('seek clamps to the track duration', () async {
    final BridgePlayerSnapshot state = await command(
      command: const BridgePlayerCommand.seek(positionMs: 999999999),
    );
    expect(state.positionMs, state.durationMs);
  });

  test('a rejected command surfaces the Rust error', () async {
    await expectLater(
      command(command: const BridgePlayerCommand.play(trackId: 'ghost')),
      throwsA(anything),
    );
  });

  test('the state stream pushes from Rust', () async {
    // Subscribe first: the stream is live and the first frame is the current
    // state, pushed without any request.
    final Stream<BridgePlayerSnapshot> stream = subscribe();
    final BridgePlayerSnapshot first = await stream.first.timeout(
      const Duration(seconds: 5),
    );
    expect(first.currentTrack, isNotNull);
  });

  test('volume round-trips through the contract', () async {
    final BridgePlayerSnapshot state = await command(
      command: const BridgePlayerCommand.setVolume(volume: 0.25),
    );
    expect(state.volume, closeTo(0.25, 1e-9));
  });

  test('the online layer builds and reports where it caches', () async {
    // Generated from `api::online::status`; `RustPlayer.onlineStatus` wraps it.
    final BridgeOnlineStatus reported = await status();

    // No request is made here: this only constructs the client and its runtime.
    expect(reported.available, isTrue, reason: reported.error ?? 'no reason');
    expect(reported.cacheDir, isNotNull);
  });

  test('a blank online query is rejected before any request', () async {
    // `bpi-rs` validates the keyword locally, so this stays hermetic.
    await expectLater(searchVideos(query: '   ', page: 1), throwsA(anything));
  });

  test('only online ids can be prepared', () async {
    // Both fail on the id, long before a stream would be requested.
    await expectLater(prepareTrack(trackId: 'song_001'), throwsA(anything));
    await expectLater(prepareTrack(trackId: 'bili_nope'), throwsA(anything));
  });
}
