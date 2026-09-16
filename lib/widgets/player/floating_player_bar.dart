import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/breakpoints.dart';
import '../../app/router.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/config/glass_config.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../common/glass_container.dart';
import 'floating_player_bar_layouts.dart';

/// Floating liquid-glass player bar.
///
/// This is the visual core of Muse Player. It is intentionally NOT a bottom
/// navigation bar and never sits flush against the window edge — the shell
/// places it inside a [Stack] with 24px side margins and 20px bottom clearance
/// so it reads as a floating, blurred surface above the page.
class FloatingPlayerBar extends ConsumerWidget {
  const FloatingPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppConfig config = ref.watch(appConfigProvider);
    final PlayerState state = ref.watch(playerProvider);
    final Song? song = state.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final Brightness brightness = theme.brightness;
    final bool isDark = brightness == Brightness.dark;
    final GlassConfig glass = config.theme.glass;
    final GlassPalette palette = isDark ? glass.dark : glass.light;

    final List<BoxShadow> shadow = <BoxShadow>[
      BoxShadow(
        color: palette.shadowColor,
        blurRadius: glass.shadowBlurRadius,
        spreadRadius: glass.shadowSpreadRadius,
        offset: Offset(0, glass.shadowOffsetY),
      ),
    ];

    final LinearGradient glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[palette.surfaceStartColor, palette.surfaceEndColor],
    );

    final LinearGradient glassBorderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        palette.borderStartColor,
        palette.borderMiddleColor,
        palette.borderEndColor,
      ],
    );

    return SizedBox(
      height: AppSizes.floatingPlayerBarHeight,
      child: GlassContainer(
        borderRadius: AppSizes.floatingPlayerBarRadius,
        blur: glass.blur,
        borderWidth: glass.borderWidth,
        shadow: shadow,
        gradient: glassGradient,
        borderGradient: glassBorderGradient,
        highlight: true,
        highlightColor: palette.highlight,
        highlightOpacity: palette.highlightOpacity,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.nowPlaying);
            },
            borderRadius: BorderRadius.circular(
              AppSizes.floatingPlayerBarRadius,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth < AppBreakpoints.tabletMin) {
                  return MobileFloatingPlayerBar(
                    song: song,
                    isPlaying: state.isPlaying,
                    progress: state.position,
                    duration: state.duration,
                    onTogglePlayPause: ref
                        .read(playerProvider.notifier)
                        .togglePlayPause,
                  );
                }

                return DesktopFloatingPlayerBar(
                  song: song,
                  isPlaying: state.isPlaying,
                  progress: state.position,
                  duration: state.duration,
                  isDesktop: constraints.maxWidth >= AppBreakpoints.desktopMin,
                  volume: state.volume,
                  onTogglePlayPause: ref
                      .read(playerProvider.notifier)
                      .togglePlayPause,
                  onPrevious: ref.read(playerProvider.notifier).previous,
                  onNext: ref.read(playerProvider.notifier).next,
                  onSeek: ref.read(playerProvider.notifier).seek,
                  onVolumeChanged: ref.read(playerProvider.notifier).setVolume,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
