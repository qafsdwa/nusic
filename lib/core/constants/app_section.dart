/// Navigation / section identifiers used by the shell.
///
/// Keeping IDs as plain strings makes them easy to map to route names or to
/// backend playlist/library sections later.
enum AppSection {
  home('home', '首页'),
  search('search', '搜索'),
  library('library', '音乐库'),
  favorites('favorites', '收藏'),
  playlists('playlists', '播放列表'),
  settings('settings', '设置');

  const AppSection(this.id, this.label);

  final String id;
  final String label;
}
