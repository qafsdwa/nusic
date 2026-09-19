import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/mock/mock_music.dart';
import 'package:muse_player/models/song.dart';
import 'package:muse_player/widgets/common/cover_artwork.dart';
import 'package:muse_player/widgets/common/generated_artwork.dart';

/// Locks down the generated-cover contract.
///
/// The scene order in [GeneratedScene] is load-bearing: the mock library was
/// laid out so each track gets the artwork the design specifies. Reordering the
/// enum silently reshuffles every cover in the app, so it is asserted here
/// rather than left to a comment.
void main() {
  /// The seed `CoverArtwork` builds: `'$coverKey|$title'`.
  String seedFor(Song song) => '${song.cover}|${song.title}';

  group('scene selection', () {
    test('is stable across calls', () {
      const String key = 'mock://midnight-drive|Midnight Drive';
      expect(GeneratedScene.forKey(key), GeneratedScene.forKey(key));
    });

    test('gives every mock song a distinct scene', () {
      final Set<GeneratedScene> scenes = <GeneratedScene>{
        for (final Song song in MockMusic.songs)
          GeneratedScene.forKey(seedFor(song)),
      };

      expect(
        scenes,
        hasLength(MockMusic.songs.length),
        reason: 'two tracks sharing artwork makes the rail read as a mistake',
      );
    });

    test('matches the designed scene per track', () {
      const Map<String, GeneratedScene> expected = <String, GeneratedScene>{
        'Midnight Drive': GeneratedScene.sunsetSea,
        '冬日挽歌': GeneratedScene.winterNight,
        'Lemon': GeneratedScene.warmAbstract,
        '晴天': GeneratedScene.daylight,
        'The Nights': GeneratedScene.nebula,
        'Fix You': GeneratedScene.forestMist,
      };

      for (final Song song in MockMusic.songs) {
        expect(
          GeneratedScene.forKey(seedFor(song)),
          expected[song.title],
          reason: 'artwork for "${song.title}" is part of the design',
        );
      }
    });

    test('the recently played rail is all distinct too', () {
      final Set<GeneratedScene> scenes = <GeneratedScene>{
        for (final Song song in MockMusic.recentlyPlayed)
          GeneratedScene.forKey(seedFor(song)),
      };

      expect(scenes, hasLength(MockMusic.recentlyPlayed.length));
    });
  });

  group('artwork hash', () {
    test('is non-negative and 32-bit', () {
      for (final Song song in MockMusic.songs) {
        final int hash = stableArtworkHash(seedFor(song));
        expect(hash, greaterThanOrEqualTo(0));
        expect(hash, lessThanOrEqualTo(0xFFFFFFFF));
      }
    });

    test('separates similar keys', () {
      expect(
        stableArtworkHash('mock://lemon|Lemon'),
        isNot(stableArtworkHash('mock://lemon|Lemons')),
      );
    });
  });

  group('CoverArtwork', () {
    testWidgets('renders a scene when large enough', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: CoverArtwork(title: 'Lemon', coverKey: 'mock://lemon'),
          ),
        ),
      );

      expect(find.byType(GeneratedArtwork), findsOneWidget);
    });

    testWidgets('degrades to a monogram below the scene threshold', (
      WidgetTester tester,
    ) async {
      // 20dp is under the point where a scene reads as a picture rather than as
      // noise, so the fallback is chosen for legibility, not just for cost.
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: CoverArtwork(
              title: 'Lemon',
              coverKey: 'mock://lemon',
              size: 20,
            ),
          ),
        ),
      );

      expect(find.byType(GeneratedArtwork), findsNothing);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('monogram can be requested explicitly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: CoverArtwork(
              title: '晴天',
              coverKey: 'mock://sunny-day',
              style: CoverArtworkStyle.monogram,
            ),
          ),
        ),
      );

      expect(find.byType(GeneratedArtwork), findsNothing);
    });
  });
}
