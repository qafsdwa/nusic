import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bridge/generated/api/online.dart';
import '../../core/bridge/rust_player.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/song/song_tile.dart';

/// Where the search page looks for results.
enum _SearchSource {
  /// Bilibili, through the Rust online layer.
  online,

  /// The in-process Rust catalog, or [MockMusic] when the native library is
  /// not loaded.
  local,
}

/// Search page.
///
/// With the Rust engine available the page can search Bilibili as well as the
/// local catalog; without it the query is answered by filtering
/// [MockMusic.songs], which keeps the page usable (and the widget tests
/// hermetic) when the native library cannot be loaded.
///
/// Online results are prepared before playback — the Rust player only accepts a
/// track whose audio is already cached — so a tap can spend a moment
/// downloading, which the progress bar reports.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  /// Keystroke-to-request delay. Long enough that typing a word does not fire a
  /// request per character, short enough that results feel immediate.
  static const Duration _debounceDelay = Duration(milliseconds: 250);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<Song> _results = MockMusic.songs;
  _SearchSource _source = _SearchSource.local;
  bool _loading = false;
  String? _error;

  /// Set while an online track is being downloaded, which also blocks a second
  /// tap from queueing the same download twice.
  String? _preparingId;

  /// Whether the Rust online layer could be built at all.
  bool _onlineAvailable = false;

  /// One-line explanation of the online mode, shown under the search field.
  String? _onlineNotice;

  bool get _usesBackend => ref.read(appConfigProvider).enableNetwork;

  bool get _onlineMode =>
      _usesBackend && _onlineAvailable && _source == _SearchSource.online;

  @override
  void initState() {
    super.initState();

    if (_usesBackend) {
      // Online search needs a keyword, so the page opens on the local list and
      // switches once the online layer has been checked.
      _loading = true;
      // Deferred to after the first frame because `_probeOnline` calls
      // setState, which is not allowed while initState is still running.
      WidgetsBinding.instance.addPostFrameCallback((_) => _probeOnline());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Checks whether online search is usable and points the page at it if so.
  Future<void> _probeOnline() async {
    try {
      final BridgeOnlineStatus status = await ref
          .read(rustPlayerProvider)
          .onlineStatus();
      if (!mounted) {
        return;
      }

      setState(() {
        _onlineAvailable = status.available;
        _onlineNotice = switch (status) {
          BridgeOnlineStatus(available: false, :final String? error) =>
            '在线搜索不可用：${error ?? '未知原因'}',
          BridgeOnlineStatus(authenticated: true) => '已登录：可获取更高音质',
          _ => '匿名模式：标准音质',
        };
        // Only switch to online when it actually works, so a failure leaves the
        // user with a usable local catalog instead of an empty page.
        _source = status.available ? _SearchSource.online : _SearchSource.local;
        _loading = false;
      });

      if (_onlineAvailable) {
        _runSearch(_query);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _onlineAvailable = false;
        _onlineNotice = '在线搜索不可用：$error';
        _loading = false;
      });
    }
  }

  void _onSourceChanged(_SearchSource source) {
    if (source == _source) {
      return;
    }

    _debounce?.cancel();
    setState(() {
      _source = source;
      _error = null;
      _results = _onlineMode ? const <Song>[] : MockMusic.songs;
    });
    _runSearch(_query);
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);

    if (!_usesBackend) {
      setState(() => _results = _filterLocally(value));
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => _runSearch(value));
  }

  /// Answers [query] from whichever source is selected.
  Future<void> _runSearch(String query) async {
    if (_onlineMode && query.trim().isEmpty) {
      // Bilibili rejects a blank keyword, and "search everything" has no
      // meaning there; the empty state asks for one instead.
      setState(() {
        _results = const <Song>[];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final RustPlayer player = ref.read(rustPlayerProvider);
      final List<Song> songs = _onlineMode
          ? await player.searchVideos(query)
          : await player.searchSongs(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = songs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      // Keep whatever was on screen: a failed search should not blank the list.
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  List<Song> _filterLocally(String query) {
    final String keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return MockMusic.songs;
    }
    return MockMusic.songs
        .where((Song song) {
          return song.title.toLowerCase().contains(keyword) ||
              song.artist.toLowerCase().contains(keyword) ||
              song.album.toLowerCase().contains(keyword);
        })
        .toList(growable: false);
  }

  /// Starts [song], downloading it first when it is an online track.
  Future<void> _play(Song song) async {
    if (_preparingId != null) {
      return;
    }

    if (song.isRemote) {
      setState(() => _preparingId = song.id);
    }

    final String? failure = await ref.read(playerProvider.notifier).play(song);
    if (!mounted) {
      return;
    }

    setState(() => _preparingId = null);
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.spacingSm,
          ),
          child: SectionHeader(title: '搜索', size: SectionHeaderSize.page),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingLg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.searchFieldWidth,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: _onQueryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: _onlineMode
                          ? '搜索 B 站视频、音乐或 UP 主'
                          : '搜索歌曲、专辑、歌手或歌单',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onQueryChanged('');
                              },
                              icon: const Icon(Icons.close),
                              tooltip: '清空',
                            ),
                    ),
                  ),
                ),
              ),
              if (_usesBackend) ...<Widget>[
                const SizedBox(width: AppSizes.spacingSm),
                SegmentedButton<_SearchSource>(
                  segments: <ButtonSegment<_SearchSource>>[
                    ButtonSegment<_SearchSource>(
                      value: _SearchSource.online,
                      label: const Text('在线'),
                      icon: const Icon(Icons.public),
                      enabled: _onlineAvailable,
                    ),
                    const ButtonSegment<_SearchSource>(
                      value: _SearchSource.local,
                      label: Text('本地'),
                      icon: Icon(Icons.library_music_outlined),
                    ),
                  ],
                  selected: <_SearchSource>{_source},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<_SearchSource> selection) {
                    _onSourceChanged(selection.first);
                  },
                ),
              ],
            ],
          ),
        ),
        if (_onlineNotice != null) ...<Widget>[
          const SizedBox(height: AppSizes.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingLg),
            child: Text(
              _onlineNotice!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSizes.spacingMd),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingLg),
          child: SectionHeader(title: '歌曲', size: SectionHeaderSize.subsection),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        if (_loading || _preparingId != null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingLg),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final String? error = _error;
    if (error != null) {
      return _SearchMessage(icon: Icons.cloud_off, message: '搜索失败：$error');
    }

    final List<Song> results = _results;
    if (results.isEmpty) {
      // Distinguish the states a blank list can mean: still loading, nothing
      // matched, or nothing was asked for yet.
      if (_loading) {
        return const SizedBox.shrink();
      }
      if (_onlineMode && _query.trim().isEmpty) {
        return const _SearchMessage(
          icon: Icons.public,
          message: '输入关键词搜索 B 站视频',
        );
      }
      return const _SearchMessage(icon: Icons.search_off, message: '没有找到匹配的歌曲');
    }

    return PageScaffold.builder(
      horizontalPadding: AppSizes.spacingMd,
      topPadding: 0,
      maxWidth: AppSizes.pageMaxWidthText,
      itemCount: results.length,
      itemBuilder: (BuildContext context, int index) {
        final Song song = results[index];
        return SongTile(
          song: song,
          showAlbum: true,
          onTap: () => _play(song),
          onAction: (SongAction action) {
            if (action == SongAction.play) {
              _play(song);
            }
          },
        );
      },
    );
  }
}

/// Empty / error state shared by both search modes.
class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
