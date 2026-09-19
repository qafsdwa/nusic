import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/app/theme.dart';
import 'package:muse_player/core/config/app_config.dart';
import 'package:muse_player/core/config/app_config_loader.dart';
import 'package:muse_player/core/config/hero_gradient_config.dart';
import 'package:muse_player/core/config/theme_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppConfig parses nested backend and player config', () {
    final config = AppConfig.fromJson(<String, dynamic>{
      'appName': 'Test Player',
      'environment': 'test',
      'enableMockData': false,
      'enableNetwork': true,
      'backend': <String, dynamic>{
        'baseUrl': 'http://example.test',
        'songsSearchPath': '/custom/search',
        'songPath': '/custom/song',
        'playlistPath': '/custom/playlist',
        'playerWebSocketPath': '/custom/ws',
      },
      'player': <String, dynamic>{
        'initialVolume': 0.35,
        'defaultShuffle': true,
        'defaultRepeatMode': 'one',
      },
      'theme': <String, dynamic>{
        'mode': 'dark',
        'light': <String, dynamic>{
          'primary': '#112233',
          'onPrimary': '#FFFFFF',
          'primaryContainer': '#D2E3FC',
          'onPrimaryContainer': '#202124',
          'background': '#F8F9FA',
          'surface': '#FFFFFF',
          'surfaceContainerLowest': '#FFFFFF',
          'surfaceContainerLow': '#FBFBFC',
          'surfaceContainer': '#F5F6F7',
          'surfaceContainerHigh': '#F1F3F4',
          'surfaceContainerHighest': '#EBEDEF',
          'textPrimary': '#202124',
          'textSecondary': '#5F6368',
          'outline': '#9AA0A6',
          'outlineVariant': '#DADCE0',
        },
        'dark': <String, dynamic>{
          'primary': '#AABBCC',
          'onPrimary': '#202124',
          'primaryContainer': '#174EA6',
          'onPrimaryContainer': '#E8EAED',
          'background': '#202124',
          'surface': '#292A2D',
          'surfaceContainerLowest': '#1B1C1E',
          'surfaceContainerLow': '#242528',
          'surfaceContainer': '#292A2D',
          'surfaceContainerHigh': '#303134',
          'surfaceContainerHighest': '#37383B',
          'textPrimary': '#E8EAED',
          'textSecondary': '#BDC1C6',
          'outline': '#6E7378',
          'outlineVariant': '#3C4043',
        },
        'glass': <String, dynamic>{
          'blur': 30,
          'borderWidth': 2,
          'shadowBlurRadius': 32,
          'shadowSpreadRadius': 2,
          'shadowOffsetY': 10,
          'light': <String, dynamic>{
            'surfaceStart': '#FFFFFF',
            'surfaceStartOpacity': 0.8,
            'surfaceEnd': '#FFFFFF',
            'surfaceEndOpacity': 0.5,
            'borderStart': '#FFFFFF',
            'borderStartOpacity': 0.9,
            'borderMiddle': '#FFFFFF',
            'borderMiddleOpacity': 0.3,
            'borderEnd': '#FFFFFF',
            'borderEndOpacity': 0.7,
            'highlight': '#FFFFFF',
            'highlightOpacity': 0.4,
            'shadow': '#000000',
            'shadowOpacity': 0.1,
          },
          'dark': <String, dynamic>{
            'surfaceStart': '#2A2B2F',
            'surfaceStartOpacity': 0.8,
            'surfaceEnd': '#1F2023',
            'surfaceEndOpacity': 0.6,
            'borderStart': '#FFFFFF',
            'borderStartOpacity': 0.2,
            'borderMiddle': '#FFFFFF',
            'borderMiddleOpacity': 0.05,
            'borderEnd': '#FFFFFF',
            'borderEndOpacity': 0.1,
            'highlight': '#FFFFFF',
            'highlightOpacity': 0.1,
            'shadow': '#000000',
            'shadowOpacity': 0.3,
          },
        },
        'heroGradient': <String, dynamic>{
          'light': <String>['#DCE7FB', '#E8E0FB', '#FBE3EE'],
          'dark': <String>['#1F2A44', '#2E2344', '#3E2135'],
        },
      },
    });

    expect(config.appName, 'Test Player');
    expect(config.environment, 'test');
    expect(config.enableMockData, isFalse);
    expect(config.enableNetwork, isTrue);
    expect(config.backend.baseUrl, 'http://example.test');
    expect(config.backend.songsSearchPath, '/custom/search');
    expect(config.player.initialVolume, 0.35);
    expect(config.player.defaultShuffle, isTrue);
    expect(config.player.defaultRepeatMode, 'one');
    expect(config.theme.mode, 'dark');
    expect(config.theme.light.primary, const Color(0xFF112233));
    expect(config.theme.dark.primary, const Color(0xFFAABBCC));
    expect(config.theme.light.outline, const Color(0xFF9AA0A6));
    expect(config.theme.light.outlineVariant, const Color(0xFFDADCE0));
    expect(
      config.theme.light.outline,
      isNot(config.theme.light.outlineVariant),
      reason: 'outline and outlineVariant are separate M3 roles',
    );
    expect(
      config.theme.light.surfaceContainerHighest,
      isNot(config.theme.light.surfaceContainerHigh),
      reason: 'the tonal surface ramp must not collapse into one value',
    );
    expect(config.theme.glass.blur, 30);
    expect(config.theme.glass.borderWidth, 2);
    expect(config.theme.glass.light.surfaceStartOpacity, 0.8);
    expect(config.theme.glass.dark.shadowOpacity, 0.3);
    expect(config.theme.heroGradient.light, hasLength(3));
    expect(
      config.theme.heroGradient.light.first,
      const Color(0xFFDCE7FB),
      reason: 'hero gradient stops are read from config, not hardcoded',
    );
    expect(config.theme.heroGradient.dark.first, const Color(0xFF1F2A44));
  });

  group('hero gradient parsing', () {
    ThemeConfig parseTheme(Object? heroGradient) {
      return ThemeConfig.fromJson(<String, dynamic>{
        'heroGradient': heroGradient,
      });
    }

    test('falls back when the section is missing', () {
      expect(
        parseTheme(null).heroGradient.light,
        HeroGradientConfig.fallback.light,
      );
    });

    test('falls back when the list is empty', () {
      expect(
        parseTheme(<String, dynamic>{'light': <String>[]}).heroGradient.light,
        HeroGradientConfig.fallback.light,
      );
    });

    test('is all-or-nothing: one bad stop discards the whole gradient', () {
      // A partially parsed gradient would render as neither the configured
      // value nor the fallback, which is worse than either.
      expect(
        parseTheme(<String, dynamic>{
          'light': <String>['#DCE7FB', 'not-a-colour', '#FBE3EE'],
        }).heroGradient.light,
        HeroGradientConfig.fallback.light,
      );
    });

    test('keeps a well-formed gradient', () {
      expect(
        parseTheme(<String, dynamic>{
          'light': <String>['#112233', '#445566'],
        }).heroGradient.light,
        <Color>[const Color(0xFF112233), const Color(0xFF445566)],
      );
    });
  });

  test('AppConfig falls back when nested config is missing', () {
    final config = AppConfig.fromJson(<String, dynamic>{
      'appName': 'Fallback Player',
    });

    expect(config.appName, 'Fallback Player');
    expect(config.backend.baseUrl, AppConfig.fallback.backend.baseUrl);
    expect(
      config.player.initialVolume,
      AppConfig.fallback.player.initialVolume,
    );
    expect(config.player.defaultRepeatMode, 'off');
    expect(config.theme.mode, AppConfig.fallback.theme.mode);
    expect(config.theme.glass.blur, AppConfig.fallback.theme.glass.blur);
  });

  testWidgets('AppConfigLoader loads the bundled asset', (
    WidgetTester tester,
  ) async {
    final config = await const AppConfigLoader().load();

    expect(config.appName, 'Muse Player');
    expect(config.environment, 'development');
    expect(config.enableMockData, isTrue);
    // The backend client is wired up, so the shipped config opts in. Mock data
    // stays available as the offline fallback.
    expect(config.enableNetwork, isTrue);
    expect(config.backend.baseUrl, 'http://127.0.0.1:8080');
    expect(config.backend.playerWebSocketPath, '/ws/player');
    expect(config.player.initialVolume, 0.7);
    expect(config.player.defaultRepeatMode, 'off');
    expect(config.theme.mode, 'system');
    expect(config.theme.light.primary, const Color(0xFF1A73E8));
    expect(config.theme.dark.background, const Color(0xFF202124));
    expect(config.theme.glass.blur, 24);
    expect(config.theme.glass.light.surfaceStartOpacity, 0.76);
    expect(config.theme.glass.dark.shadowOpacity, 0.25);
  });

  test('AppTheme resolves configured ThemeMode', () {
    expect(AppTheme.resolveThemeMode('system'), ThemeMode.system);
    expect(AppTheme.resolveThemeMode('light'), ThemeMode.light);
    expect(AppTheme.resolveThemeMode('dark'), ThemeMode.dark);
  });
}
