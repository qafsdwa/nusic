import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/core/utils/motion.dart';
import 'package:muse_player/mock/mock_music.dart';
import 'package:muse_player/models/album.dart';
import 'package:muse_player/widgets/album/album_card.dart';
import 'package:muse_player/widgets/song/song_tile.dart';

/// Regression tests for the issues raised in `docs/m3-audit.md`.
///
/// These cover the three accessibility failures the audit scored as blocking:
/// no reduced-motion handling, state communicated by colour alone, and controls
/// that look tappable but do nothing.

/// Minimal scaffolding these widgets need.
Widget _host(Widget child, {bool reduceMotion = false}) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Future<BuildContext> _captureContext(
  WidgetTester tester, {
  required bool reduceMotion,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    _host(
      Builder(
        builder: (BuildContext context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
      reduceMotion: reduceMotion,
    ),
  );
  return captured;
}

void main() {
  group('reduced motion', () {
    testWidgets('durations survive when motion is allowed', (
      WidgetTester tester,
    ) async {
      final BuildContext context = await _captureContext(
        tester,
        reduceMotion: false,
      );

      expect(AppMotion.of(context, AppMotion.fast), AppMotion.fast);
      expect(AppMotion.of(context, AppMotion.standard), AppMotion.standard);
      expect(AppMotion.of(context, AppMotion.emphasized), AppMotion.emphasized);
    });

    testWidgets('durations collapse when the platform asks for less motion', (
      WidgetTester tester,
    ) async {
      final BuildContext context = await _captureContext(
        tester,
        reduceMotion: true,
      );

      expect(AppMotion.of(context, AppMotion.fast), Duration.zero);
      expect(AppMotion.of(context, AppMotion.standard), Duration.zero);
      expect(AppMotion.of(context, AppMotion.emphasized), Duration.zero);
    });
  });

  group('current song indication', () {
    testWidgets('uses a shape, not only a colour', (WidgetTester tester) async {
      // PlayerState starts on the first mock song, paused.
      await tester.pumpWidget(_host(SongTile(song: MockMusic.songs.first)));

      // Asserted on the Icon itself: ListTile merges its children's semantics
      // into a single node, so an exact-label query would not find it even
      // though a screen reader does announce it.
      final Icon indicator = tester.widget<Icon>(
        find.byIcon(Icons.pause_rounded),
      );
      expect(indicator.semanticLabel, '已暂停');
    });

    testWidgets('is absent on every other row', (WidgetTester tester) async {
      await tester.pumpWidget(_host(SongTile(song: MockMusic.songs[1])));

      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
    });
  });

  group('no dead affordances', () {
    testWidgets('AlbumCard without a destination is not tappable', (
      WidgetTester tester,
    ) async {
      final Album album = MockMusic.albums.first;
      await tester.pumpWidget(_host(AlbumCard(album: album, width: 160)));

      final InkWell inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(
        inkWell.onTap,
        isNull,
        reason: 'a card with no destination must not render as a button',
      );
    });

    testWidgets('AlbumCard with a destination is tappable', (
      WidgetTester tester,
    ) async {
      final Album album = MockMusic.albums.first;
      await tester.pumpWidget(
        _host(AlbumCard(album: album, width: 160, onTap: () {})),
      );

      final InkWell inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNotNull);
    });
  });
}
