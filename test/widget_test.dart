import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/app/app.dart';
import 'package:muse_player/widgets/navigation/desktop_navigation.dart';
import 'package:muse_player/widgets/player/floating_player_bar.dart';

void main() {
  testWidgets('Muse Player renders desktop shell', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: MuseApp()));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsWidgets);
    expect(find.byType(DesktopNavigationPanel), findsOneWidget);
    expect(find.byType(FloatingPlayerBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Muse Player renders tablet navigation rail', (
    WidgetTester tester,
  ) async {
    // 900 sits in M3 `medium`/`expanded` territory — the range the shell now
    // maps to the rail. It used to fall through to the desktop panel.
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: MuseApp()));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsWidgets);
    expect(find.byType(MuseNavigationRail), findsOneWidget);
    expect(find.byType(DesktopNavigationPanel), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingPlayerBar), findsOneWidget);
  });

  testWidgets('Muse Player renders mobile bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: MuseApp()));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingPlayerBar), findsOneWidget);
  });
}
