import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/app/breakpoints.dart';

/// The breakpoints were realigned to Material 3 window size classes, so the
/// boundaries themselves are now load-bearing: a value one pixel either side of
/// 600 or 1200 changes which shell the whole app renders.
void main() {
  group('AppBreakpoints.fromWidth', () {
    test('compact is anything below 600', () {
      expect(AppBreakpoints.fromWidth(320), AppBreakpoint.mobile);
      expect(AppBreakpoints.fromWidth(480), AppBreakpoint.mobile);
      expect(AppBreakpoints.fromWidth(599.99), AppBreakpoint.mobile);
    });

    test('medium and expanded share the rail shell (600 to 1199)', () {
      // The lower edge of M3 `medium`.
      expect(AppBreakpoints.fromWidth(600), AppBreakpoint.tablet);
      expect(AppBreakpoints.fromWidth(839), AppBreakpoint.tablet);
      // The `medium` / `expanded` boundary is internal to the shell.
      expect(AppBreakpoints.fromWidth(840), AppBreakpoint.tablet);
      expect(AppBreakpoints.fromWidth(1100), AppBreakpoint.tablet);
      expect(AppBreakpoints.fromWidth(1199.99), AppBreakpoint.tablet);
    });

    test('large and extra-large share the permanent panel (1200 and up)', () {
      expect(AppBreakpoints.fromWidth(1200), AppBreakpoint.desktop);
      expect(AppBreakpoints.fromWidth(1600), AppBreakpoint.desktop);
      expect(AppBreakpoints.fromWidth(2560), AppBreakpoint.desktop);
    });
  });

  group('threshold constants', () {
    test('sit on the M3 window size class boundaries', () {
      expect(AppBreakpoints.tabletMin, 600);
      expect(AppBreakpoints.desktopMin, 1200);
    });

    test('stay internally consistent', () {
      expect(AppBreakpoints.compactMax, lessThan(AppBreakpoints.tabletMin));
      expect(AppBreakpoints.mediumMax, greaterThan(AppBreakpoints.tabletMin));
      expect(AppBreakpoints.expandedMax, lessThan(AppBreakpoints.desktopMin));
    });

    test('the hero card threshold is narrower than the compact shell', () {
      // It reacts to the card's own width, which is narrower than the viewport
      // because page content is centred.
      expect(AppBreakpoints.heroCompactMax, lessThan(AppBreakpoints.tabletMin));
    });
  });
}
