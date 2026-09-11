# 模块职责

按目录说明每个文件的职责。文件路径均相对于 `lib/`。

## 应用层

| 文件 | 职责 |
| --- | --- |
| `main.dart` | 程序入口：`initializeApp()` 加载配置后，用 `ProviderScope` override `appConfigProvider` 并启动 `MuseApp` |
| `app/app.dart` | `MuseApp`（读取 `appName` 的 MaterialApp 根组件）与 `MainShell`（响应式外壳） |
| `app/breakpoints.dart` | `AppBreakpoint` 与 `AppBreakpoints`：Mobile `<700` / Tablet `700~1100` / Desktop `>1100` |
| `app/router.dart` | `AppRoutes` 命名路由表（`/search`、`/now-playing` 等），支持深链与后续后端驱动导航 |
| `app/theme.dart` | `AppTheme.light(ThemePalette)` / `dark(ThemePalette)`：从配置色板构建 Material 3 主题，并提供 `resolveThemeMode` |

## core/config/ — 配置系统

| 文件 | 职责 |
| --- | --- |
| `app_config.dart` | `AppConfig` / `PlayerConfig`：配置模型、`fromJson` / `toJson`、fallback |
| `theme_config.dart` | `ThemeConfig` / `ThemePalette`：主题模式与明暗色板、hex 颜色解析 |
| `app_config_loader.dart` | `AppConfigLoader`：从 `assets/config/app_config.json` 加载配置；异常时回退 |
| `app_config_provider.dart` | `appConfigProvider`：全局配置 Riverpod Provider |
| `app_bootstrap.dart` | `initializeApp()`：初始化 Flutter 绑定并加载启动配置 |

详细字段见 [configuration.md](configuration.md)。

## core/ — 其他基础设施

### constants/

| 文件 | 职责 |
| --- | --- |
| `app_sizes.dart` | `AppSizes`：间距、页面最大宽度、导航宽度、Floating Player Bar 与滚动底部留白等尺寸 |
| `app_section.dart` | `AppSection` 枚举：首页 / 搜索 / 音乐库 / 收藏 / 播放列表 / 设置，含 id 与中文 label |

### extensions/

| 文件 | 职责 |
| --- | --- |
| `context_extensions.dart` | `MuseBreakpointContext`：通过 `BuildContext` 读取当前断点（`isMobile` / `isTablet` / `isDesktop`） |

### network/

| 文件 | 职责 |
| --- | --- |
| `backend_config.dart` | `BackendConfig`：后端 base URL 与端点路径的数据模型，可从 JSON 解析 |
| `api_client.dart` | `RustApiClient`：空壳单例，未来 REST + WebSocket 客户端注入点 |

### utils/

| 文件 | 职责 |
| --- | --- |
| `formatters.dart` | `formatDuration`：`Duration` → `m:ss` / `hh:mm:ss` 文本 |

## mock/ — Mock 数据

| 文件 | 职责 |
| --- | --- |
| `mock_music.dart` | `MockMusic`：Phase 1 的静态歌曲、专辑、播放列表、最近播放数据 |

## models/ — 领域模型

| 文件 | 职责 |
| --- | --- |
| `song.dart` | `Song`：id / title / artist / album / cover / duration，含 `copyWith` 与基于 id 的相等性 |
| `album.dart` | `Album`：id / title / artist / cover，用于专辑卡片 |
| `playlist.dart` | `Playlist`：id / name / description / cover / songs，用于歌单页 |

## providers/ — 状态管理

| 文件 | 职责 |
| --- | --- |
| `player_provider.dart` | `PlayerStatus`、`RepeatMode`、`PlayerState`、`PlayerNotifier` 与 `playerProvider`；初始值来自 `AppConfig` |
| `navigation_provider.dart` | `NavigationNotifier` 与 `navigationProvider`：当前 Shell 导航索引 |
| `theme_mode_provider.dart` | `ThemeModeNotifier` 与 `themeModeProvider`：运行时主题模式，初始值来自 `AppConfig.theme.mode` |

`PlayerNotifier` 暴露：`play` / `togglePlayPause` / `next` / `previous` /
`seek` / `setVolume` / `toggleShuffle` / `cycleRepeatMode` / `pause`。

## pages/ — 页面

| 目录 / 文件 | 职责 |
| --- | --- |
| `home/home_page.dart` | 首页：Hero、最近播放、推荐歌单 |
| `home/home_widgets.dart` | Home Header / 搜索框 |
| `home/home_cards.dart` | Hero / 区块标题 / 最近播放卡片 / 歌单卡片 |
| `search/search_page.dart` | 搜索页：本地过滤标题 / 艺术家 / 专辑 |
| `library/library_page.dart` | 音乐库：歌曲 / 专辑 / 歌手 SegmentedButton 切换 |
| `playlist/playlist_page.dart` | 歌单详情：封面、名称、播放全部、曲目列表 |
| `now_playing/now_playing_page.dart` | Now Playing 入口与响应式布局选择 |
| `now_playing/now_playing_widgets.dart` | 桌面 / 移动布局、传输控制、Mock 歌词面板 |
| `settings/settings_page.dart` | 设置页：主题模式切换按钮与关于信息 |

## widgets/ — 可复用组件

| 目录 / 文件 | 职责 |
| --- | --- |
| `common/cover_artwork.dart` | `CoverArtwork`：用首字符 + 确定性渐变生成占位封面 |
| `common/glass_container.dart` | `GlassContainer`：`ClipRRect + BackdropFilter` 液态玻璃容器，仅用于 Floating Player Bar 等强调元素 |
| `common/responsive_layout.dart` | `ResponsiveLayout`：Mobile / Tablet / Desktop 三槽位布局 |
| `common/placeholder_page.dart` | 通用占位页（收藏 / 设置） |
| `navigation/desktop_navigation.dart` | `DesktopNavigationPanel` / `MuseNavigationRail` / `MuseBottomNavigationBar` |
| `player/floating_player_bar.dart` | `FloatingPlayerBar`：悬浮玻璃播放条主入口与布局选择 |
| `player/floating_player_bar_layouts.dart` | Desktop / Mobile 播放条内容、封面与标题、移动播放按钮 |
| `player/player_controls.dart` | `PlayerBarControls`：上一首 / 播放暂停 / 下一首 / 音量 / 队列 |
| `player/player_progress.dart` | `PlayerProgressSlider` / `PlayerProgressLine`：进度与时间 |
| `song/song_tile.dart` | `SongTile` + `SongAction`：标准歌曲行（当前播放高亮 + 更多菜单） |
| `album/album_card.dart` | `AlbumCard`：方形专辑卡片与 hover 轻微缩放 |

## 复用关系

- `SongTile` 被 Home、Search、Library、Playlist 复用。
- `CoverArtwork` 被 `SongTile`、`AlbumCard`、`PlaylistCard`、`NowPlayingPage`、
  `FloatingPlayerBar` 复用。
- `formatDuration` 被 `SongTile`、`PlayerProgressSlider`、`RecentSongCard` 复用。
- `GlassContainer` 仅用于 `FloatingPlayerBar`，避免列表区域重复触发
  `BackdropFilter` 带来的 GPU 开销。
