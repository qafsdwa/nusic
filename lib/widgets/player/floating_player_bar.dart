import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/breakpoints.dart';
import '../../app/router.dart';
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
    final PlayerState state = ref.watch(playerProvider);
    final Song? song = state.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final Brightness brightness = theme.brightness;
    final bool isDark = brightness == Brightness.dark;
    final List<BoxShadow> shadow = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
        blurRadius: 28,
        spreadRadius: 1,
        offset: const Offset(0, 8),
      ),
    ];

    return SizedBox(
      height: AppSizes.floatingPlayerBarHeight,
      child: GlassContainer(
        borderRadius: AppSizes.floatingPlayerBarRadius,
        blur: 22,
        opacity: isDark ? 0.72 : 0.68,
        shadow: shadow,
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
                  isDesktop: constraints.maxWidth > AppBreakpoints.tabletMax,
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
