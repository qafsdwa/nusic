import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/breakpoints.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/page_scaffold.dart';
import 'now_playing_widgets.dart';

/// Full-screen "now playing" view with large cover art, transport controls and
/// a mock lyrics panel. State comes from [playerProvider].
class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerState playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    return Scaffold(
      appBar: AppBar(title: const Text('正在播放')),
      body: SafeArea(
        child: CenteredPage(
          child: song == null
              ? const NoSongMessage()
              : LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isDesktop =
                        constraints.maxWidth >= AppBreakpoints.desktopMin;
                    if (isDesktop) {
                      return NowPlayingDesktopLayout(
                        song: song,
                        playerState: playerState,
                      );
                    }
                    return NowPlayingMobileLayout(
                      song: song,
                      playerState: playerState,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
