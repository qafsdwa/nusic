import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/mock/mock_music.dart';
import 'package:muse_player/models/song.dart';
import 'package:muse_player/providers/player_provider.dart';

/// Queue manipulation behind the home rail's action menu.
///
/// These actions are reachable straight from the home page, so "play next" that
/// silently plays immediately — or appends twice — is user-visible, not an
/// internal detail.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  PlayerNotifier notifier() => container.read(playerProvider.notifier);
  PlayerState state() => container.read(playerProvider);

  /// A song that is deliberately not part of the mock queue.
  const Song outsider = Song(
    id: 'song_999',
    title: 'Not In Queue',
    artist: 'Nobody',
    album: 'Nowhere',
    cover: 'mock://not-in-queue',
    duration: Duration(minutes: 3),
  );

  group('playNext', () {
    test(
      'inserts directly after the current track without switching to it',
      () {
        final Song current = state().currentSong!;
        final Song target = MockMusic.songs[4];

        notifier().playNext(target);

        final PlayerState after = state();
        expect(
          after.currentSong?.id,
          current.id,
          reason: '"play next" must not start playing',
        );
        expect(after.queue[after.currentIndex + 1].id, target.id);
      },
    );

    test('moves an already queued song instead of duplicating it', () {
      final int before = state().queue.length;
      final Song target = MockMusic.songs[3];
      expect(
        state().queue.where((Song s) => s.id == target.id),
        hasLength(1),
        reason: 'precondition: the target starts queued exactly once',
      );

      notifier().playNext(target);

      final PlayerState after = state();
      expect(after.queue, hasLength(before));
      expect(after.queue.where((Song s) => s.id == target.id), hasLength(1));
      expect(after.queue[after.currentIndex + 1].id, target.id);
    });

    test('keeps currentIndex pointing at the same song when an earlier entry moves', () {
      // Move a song that sits before the current track: the removal shifts every
      // later index down, so a stale index would point at the wrong song.
      notifier().play(MockMusic.songs[3]);
      final String playing = state().currentSong!.id;

      notifier().playNext(MockMusic.songs[0]);

      final PlayerState after = state();
      expect(after.currentSong?.id, playing);
      expect(after.queue[after.currentIndex].id, playing);
      expect(after.queue[after.currentIndex + 1].id, MockMusic.songs[0].id);
    });

    test('is a no-op for the song already playing', () {
      final Song playing = state().currentSong!;
      final List<Song> before = state().queue;

      notifier().playNext(playing);

      expect(state().queue, before);
      expect(state().currentIndex, 0);
    });
  });

  group('addToQueue', () {
    test('appends a new song to the end', () {
      final int before = state().queue.length;

      notifier().addToQueue(outsider);

      final PlayerState after = state();
      expect(after.queue, hasLength(before + 1));
      expect(after.queue.last.id, outsider.id);
      expect(
        after.currentSong?.id,
        MockMusic.songs.first.id,
        reason: 'queueing must not change what is playing',
      );
    });

    test('ignores a song that is already queued', () {
      final List<Song> before = state().queue;

      notifier().addToQueue(MockMusic.songs[2]);

      expect(state().queue, before);
    });
  });
}
