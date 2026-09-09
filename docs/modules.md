# 模块职责

按目录说明每个文件的职责。文件路径均相对于 `lib/`。

## app/ — 应用层

| 文件 | 职责 |
| --- | --- |
| `main.dart` | 程序入口，`runApp(ProviderScope(child: MuseApp()))` |
| `app/app.dart` | `MuseApp`（MaterialApp 根组件）与 `MainShell`（响应式外壳：侧边栏 / 底部导航 + MiniPlayer） |
| `app/router.dart` | `AppRoutes` 命名路由表（`/search`、`/library`、`/now-playing`），支持深链与后续后端驱动导航 |
| `app/theme.dart` | `AppColors` 色板 + `AppTheme.light()/dark()` 明暗主题 |

## core/ — 基础设施层

### constants/

| 文件 | 职责 |
| --- | --- |
| `app_sizes.dart` | `AppSizes`：间距、页面最大宽度、导航栏宽度、MiniPlayer 高度等统一尺寸常量 |
| `app_section.dart` | `AppSection` 枚举：首页 / 搜索 / 音乐库 / 收藏 / 播放列表 / 设置，含 id 与中文 label |
| `mock_data.dart` | `MockData`：Phase 1 的静态歌曲与专辑假数据 |

### network/

| 文件 | 职责 |
| --- | --- |
| `backend_config.dart` | `BackendConfig`：后端 base URL 与端点路径常量 |
| `api_client.dart` | `RustApiClient`：空壳单例，未来 REST + WebSocket 客户端注入点 |

### utils/

| 文件 | 职责 |
| --- | --- |
| `formatters.dart` | `formatDuration`：`Duration` → `mm:ss` / `hh:mm:ss` 文本 |

## models/ — 领域模型

| 文件 | 职责 |
| --- | --- |
| `song.dart` | `Song`：id / title / artist / album / cover / duration，含 `copyWith` 与基于 id 的相等性 |
| `album.dart` | `Album`：id / title / artist / cover，用于专辑卡片 |

> `Album` 刻意与 `Song` 分离，便于后续 Rust 的专辑 / 播放列表端点直接映射。

## providers/ — 状态管理

| 文件 | 职责 |
| --- | --- |
| `player_provider.dart` | `PlayerStatus` 枚举、`PlayerState` 不可变状态、`PlayerNotifier`（`Notifier`）与全局 `playerProvider` |

`PlayerNotifier` 暴露：`playSong` / `togglePlayPause` / `next` / `previous` / `seek` / `pause` / `reset`。

## pages/ — 页面

| 文件 | 职责 |
| --- | --- |
| `home_page.dart` | 首页：搜索框入口 + 「最近播放」歌曲列表 |
| `search_page.dart` | 搜索页：本地过滤标题 / 艺术家 / 专辑的实时搜索 |
| `library_page.dart` | 音乐库：横向专辑卡片 + 完整曲库列表 |
| `now_playing_page.dart` | 正在播放页：大封面、播放控制、歌词占位 |
| `placeholder_page.dart` | 通用占位页（收藏 / 播放列表 / 设置） |

## widgets/ — 可复用组件

| 文件 | 职责 |
| --- | --- |
| `cover_artwork.dart` | `CoverArtwork`：用首字符 + 确定性渐变生成占位封面 |
| `song_tile.dart` | `SongTile` + `SongAction`：标准歌曲行（含更多菜单） |
| `album_card.dart` | `AlbumCard`：方形专辑卡片 |
| `navigation.dart` | `AppNavigationRail` / `AppBottomNavigationBar`：桌面与移动导航 |
| `mini_player.dart` | `MiniPlayer`：底部迷你播放条（紧凑 / 宽屏两种布局） |

## 复用关系

- `SongTile` 被 Home、Search、Library 复用。
- `CoverArtwork` 被 `SongTile`、`AlbumCard`、`MiniPlayer`、`NowPlayingPage` 复用。
- `formatDuration` 被 `SongTile`、`MiniPlayer` 复用。
