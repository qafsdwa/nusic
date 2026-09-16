/// Navigation / section identifiers used by the shell.
///
/// Keeping IDs as plain strings makes them easy to map to route names or to
/// backend playlist/library sections later.
///
/// **Order is load-bearing**: the shell builds its `IndexedStack` pages by
/// iterating [values], so the enum order *is* the navigation order and the
/// index of each value is the shell's page index.
///
/// Search is deliberately **not** a destination. The home header already
/// carries a search field, so a sixth destination was redundant; search is
/// pushed as its own route (`AppRoutes.search`) instead.
enum AppSection {
  home('home', '首页'),
  library('library', '音乐库'),
  favorites('favorites', '收藏'),
  playlists('playlists', '播放列表'),
  settings('settings', '设置');

  const AppSection(this.id, this.label);

  final String id;
  final String label;
}
