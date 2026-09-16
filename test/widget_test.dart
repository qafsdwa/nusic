import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/app/app.dart';
import 'package:muse_player/core/constants/app_section.dart';
import 'package:muse_player/pages/search/search_page.dart';
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

  testWidgets('the shell has one destination per AppSection', (
    WidgetTester tester,
  ) async {
    // Ties the rendered navigation to the enum rather than to a magic number,
    // so adding or removing a section cannot silently desync the two.
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: MuseApp()));
    await tester.pumpAndSettle();

    final NavigationBar bar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    expect(bar.destinations, hasLength(AppSection.values.length));
    // M3 recommends 3-5 destinations for a navigation bar.
    expect(AppSection.values.length, inInclusiveRange(3, 5));
  });

  testWidgets('search is not a navigation destination', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: MuseApp()));
    await tester.pumpAndSettle();

    expect(
      AppSection.values.map((AppSection s) => s.id),
      isNot(contains('search')),
    );
    // The search page must not be reachable from the shell itself.
    expect(find.byType(SearchPage), findsNothing);
  });

  testWidgets('the home search field pushes the search route', (
    WidgetTester tester,
  ) async {
    // Search was demoted from a shell destination to a pushed route, so the
    // home header is now its only entry point. This guards that path.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: MuseApp()));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
    // The route has its own app bar, so the user can get back out.
    expect(find.widgetWithText(AppBar, '搜索'), findsOneWidget);
  });
}
