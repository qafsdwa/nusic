# 模块职责

按目录说明每个文件的职责。文件路径均相对于 `lib/`。

## 应用层

| 文件 | 职责 |
| --- | --- |
| `main.dart` | 程序入口：`initializeApp()` 加载配置后，用 `ProviderScope` override `appConfigProvider` 并启动 `MuseApp` |
| `app/app.dart` | `MuseApp`（读取 `appName` 的 MaterialApp 根组件）；`MainShell`（`AmbientBackground` + 标题栏 + 内缩圆角外壳）、`_ShellSurface`（外壳面板，`Clip.antiAlias`）、`_ShellBody`（Riverpod 驱动的响应式外壳与 `IndexedStack`） |
| `app/breakpoints.dart` | `AppBreakpoint` 与 `AppBreakpoints`：断点对齐 M3 window size class —— Mobile `<600` (compact) / Tablet `600~1199` (medium+expanded) / Desktop `>=1200` (large+extra-large)；另导出 `compactMax` / `mediumMax` / `expandedMax` 与组件级的 `heroCompactMax` |
| `app/router.dart` | `AppRoutes` 命名路由表（`/search`、`/now-playing`）。搜索**不是 shell 分区**，入口见 `common/search_launcher.dart`，点击后 push `/search` 路由 |
| `app/theme.dart` | `AppTheme.light(ThemePalette)` / `dark(ThemePalette)`：从配置色板构建 Material 3 主题，并提供 `resolveThemeMode` |

## core/config/ — 配置系统

| 文件 | 职责 |
| --- | --- |
| `app_config.dart` | `AppConfig` / `PlayerConfig`：配置模型、`fromJson` / `toJson`、fallback |
| `theme_config.dart` | `ThemeConfig` / `ThemePalette`：主题模式、明暗色板（字段名对齐 M3 `md.sys.color.*` 角色）、hero 渐变与环境光晕入口 |
| `glass_config.dart` | `GlassConfig` / `GlassPalette`：底部 Floating Player Bar 的玻璃颜色、透明度、模糊与阴影 |
| `hero_gradient_config.dart` | `HeroGradientConfig`：首页 Hero 卡片的明暗两套底衬渐变色标 |
| `ambient_config.dart` | `AmbientConfig`：外壳背后环境光晕的明暗两组光斑颜色。**不是渐变 stops**，数组长度即光斑个数 |
| `config_color.dart` | 配置颜色 / 颜色数组 / 透明度 / 数值解析工具；`parseConfigColorList` 为全有或全无语义 |
| `app_config_loader.dart` | `AppConfigLoader`：从 `assets/config/app_config.json` 加载配置；异常时回退 |
| `app_config_provider.dart` | `appConfigProvider`：全局配置 Riverpod Provider |
| `app_bootstrap.dart` | `initializeApp()`：初始化 Flutter 绑定并加载启动配置 |

详细字段见 [configuration.md](configuration.md)。

## core/bridge/ — Rust 桥接契约

| 文件 | 职责 |
| --- | --- |
| `bridge_models.dart` | Dart 侧手写 Bridge DTO：`BridgeTrack` / `BridgePlayerSnapshot` / 命令 / 事件 |
| `bridge_mapper.dart` | UI 模型（`Song` / `PlayerState`）与 Bridge DTO 的转换 |
| `generated/` | flutter_rust_bridge codegen 输出：契约类型、API 封装、freezed 值 |
| `rust_player.dart` | `RustPlayer`：对生成 API 的薄封装，投影 `BridgeTrack` → `Song`；含在线状态 / 在线搜索 / `prepareTrack`（下载音轨） |

## core/ — 其他基础设施

### constants/

| 文件 | 职责 |
| --- | --- |
| `app_sizes.dart` | `AppSizes`：间距、页面最大宽度（`pageMaxWidth` / `pageMaxWidthText`）、形状令牌（`shape*`，对齐 M3 `md.sys.shape.corner.*`）、导航宽度、Floating Player Bar 与滚动底部留白等尺寸 |
| `app_section.dart` | `AppSection` 枚举：首页 / 音乐库 / 收藏 / 播放列表 / 设置，含 id 与中文 label。**枚举顺序即导航顺序，`index` 即 shell 页面索引**；`app.dart` 直接遍历 `AppSection.values` 构建页面，新增分区会编译报错直到补上页面。搜索**不是**分区，见 `router.dart` |

### network/

| 文件 | 职责 |
| --- | --- |
| `backend_config.dart` | `BackendConfig`：后端 base URL 与端点路径的数据模型，可从 JSON 解析 |
| `backend_config.dart` | `BackendConfig`：REST/WS 前端的 base URL 与端点路径。App 已改用 FFI，此模型仅为保留 `app_config.json` 的 `backend` 段 |

### window/

| 文件 | 职责 |
| --- | --- |
| `window_setup.dart` | `setUpDesktopWindow()`：通过 `window_manager` 隐藏原生标题栏，设置窗口初始尺寸与最小尺寸；`isDesktopPlatform` 平台判断 |

### utils/

| 文件 | 职责 |
| --- | --- |
| `formatters.dart` | `formatDuration`：`Duration` → `m:ss` / `hh:mm:ss` 文本 |
| `motion.dart` | `AppMotion`：动效时长常量（`fast` / `standard` / `emphasized`）与 `of(context, duration)` —— 系统开启减少动效时返回 `Duration.zero`。**新增动画必须走这里** |

## rust/ — Rust 桥接层与后端

### `rust/` — FRB 桥接 crate（`muse_bridge`）

| 文件 | 职责 |
| --- | --- |
| `rust/Cargo.toml` | `muse_bridge` crate：依赖 `flutter_rust_bridge` 与 `serde`；`crate-type` 含 `rlib` 以便后端直接复用 |
| `rust/backend/src/api/bridge_models.rs` | Rust 侧数据契约：Track / Snapshot / Command / Event / Error。**必须定义在 FFI crate 内**，否则 FRB 会把它当成不透明句柄 |
| `rust/backend/src/api/{library,player,online}.rs` | FRB 导出的函数：初始化、搜索、歌单、快照、指令、状态流，以及在线搜索 / 音轨准备 |
| `rust/backend/src/runtime.rs` | FFI 单例（库 + 播放器 + 采样线程 + 惰性在线层）。**放在 `api/` 之外**，避免被 FRB 扫描 |
| `flutter_rust_bridge.yaml` | FRB 代码生成配置 |

详细设计见 [rust-bridge.md](rust-bridge.md)。

### `rust/backend/` — 独立后端服务（`muse_backend`）

REST + WebSocket 服务，接口契约与实现说明见 [backend-api.md](backend-api.md)。

| 文件 | 职责 |
| --- | --- |
| `src/main.rs` | 二进制入口：初始化 tracing、读环境变量、启动服务 |
| `src/lib.rs` | `build_router` / `serve`：装配路由、绑定端口、优雅关闭；集成测试的接入点 |
| `src/config.rs` | `Config`：从环境变量解析监听地址、音乐目录与对外 base URL |
| `src/models.rs` | HTTP / WS 线上类型：`Song` / `PlayerState` / `PlayerCommand` / `ServerMessage` |
| `src/error.rs` | `ErrorBody` 与 `ApiError`：统一错误体，可直接作为 handler 返回值 |
| `src/library.rs` | `Library`：`walkdir` + `lofty` 扫描目录，或内置 seed 目录；搜索 / 详情 / 歌单查询；以及在线曲目叠加层（按 id 解析，不进入目录 / 歌单 / 本地搜索） |
| `src/online.rs` | `OnlineService`（`bpi-rs`）：视频搜索、DASH 音轨挑选、下载到本地缓存；自带 tokio 运行时，对外是阻塞方法 |
| `src/audio/mod.rs` | `AudioEngine` trait：播放后端抽象（load / play / pause / seek / volume / position），以及 `AudioSource` / `AudioError` |
| `src/audio/rodio.rs` | `RodioEngine`：`rodio` + `cpal` 真实输出；`load` 先准备好源再替换，失败不影响当前曲目 |
| `src/audio/clock.rs` | `ClockEngine`：无声卡时的虚拟时钟，供 headless 运行与测试使用 |
| `src/player.rs` | `PlayerHub`：控制状态机（队列 / 循环 / 随机 / 播放头）+ 广播；每 250ms 采样引擎位置并推送 |
| `src/cover.rs` | `CoverCache` 与程序化封面生成（FNV-1a 定种子，512×512 JPEG） |
| `src/routes/mod.rs` | `AppState` 与路由表（CORS / tracing 中间件） |
| `src/routes/health.rs` | `GET /health` |
| `src/routes/songs.rs` | `GET /songs/search`、`/songs/{id}`、`/playlist`、`/covers/{name}` |
| `src/routes/player_ws.rs` | `GET /ws/player`：升级、读指令、推状态 |
| `tests/` | 集成测试：`rest_api` / `player_ws` / `library_scan` 与共享的 `common` 测试服务器 |
| `examples/meta.rs`、`examples/dur.rs` | 选型期探针：分别验证 `lofty` 标签读取与 `symphonia` 时长扫描 |

后端**直接复用** `muse_bridge::api::bridge_models::BridgeTrack` 作为曲目领域类型，
因此 HTTP JSON 与 FFI 契约不会各自漂移。

## mock/ — Mock 数据

| 文件 | 职责 |
| --- | --- |
| `mock_music.dart` | `MockMusic`：Phase 1 的静态歌曲、专辑、播放列表、最近播放数据 |

## models/ — 领域模型

| 文件 | 职责 |
| --- | --- |
| `song.dart` | `Song`：id / title / artist / album / cover / duration / source，含 `copyWith`、基于 id 的相等性与 `isRemote`（在线曲目播放前需先下载） |
| `album.dart` | `Album`：id / title / artist / cover，用于专辑卡片 |
| `playlist.dart` | `Playlist`：id / name / description / cover / songs，用于歌单页 |

## providers/ — 状态管理

| 文件 | 职责 |
| --- | --- |
| `player_provider.dart` | `PlayerStatus`、`RepeatMode`、`PlayerState`、`PlayerNotifier` 与 `playerProvider`；初始值来自 `AppConfig` |
| `navigation_provider.dart` | `NavigationNotifier` 与 `navigationProvider`：当前 Shell 导航索引 |
| `theme_mode_provider.dart` | `ThemeModeNotifier` 与 `themeModeProvider`：运行时主题模式，初始值来自 `AppConfig.theme.mode` |

`PlayerNotifier` 暴露：`play` / `playNext` / `addToQueue` / `togglePlayPause` /
`next` / `previous` / `seek` / `setVolume` / `toggleShuffle` / `cycleRepeatMode` /
`pause`。

`playNext` 把歌曲插到当前曲目之后且**不切换播放**；已在队列中的歌曲是移动而非重复
插入（因为移除靠前的项会让后面的索引整体前移，插入点会重新计算，不能复用旧的
`currentIndex`）。`addToQueue` 追加到队尾，已在队列中的歌曲直接忽略。

## pages/ — 页面

| 目录 / 文件 | 职责 |
| --- | --- |
| `home/home_page.dart` | 首页：Hero 横幅、最近播放、推荐歌单。桌面端不渲染页头（搜索框在标题栏里） |
| `home/home_widgets.dart` | `HomeHeader`：非桌面外壳的问候语 + 搜索入口 |
| `home/home_cards.dart` | `HomeHeroCard`（大图 + 遮罩 + 文案）/ `RecentSongCard` / `PlaylistCard`（均带 hover 播放按钮）/ `SongActionMenu`（紧凑 ⋮ 菜单） |
| `search/search_page.dart` | 搜索页：本地过滤标题 / 艺术家 / 专辑。经 `AppRoutes.search` 以路由方式打开（自带 AppBar 与返回），不是 shell 分区 |
| `library/library_page.dart` | 音乐库：歌曲 / 专辑 / 歌手 SegmentedButton 切换 |
| `playlist/playlist_page.dart` | 歌单详情：封面、名称、播放全部、曲目列表 |
| `now_playing/now_playing_page.dart` | Now Playing 入口与响应式布局选择 |
| `now_playing/now_playing_widgets.dart` | 桌面 / 移动布局、传输控制、Mock 歌词面板 |
| `settings/settings_page.dart` | 设置页：主题模式切换按钮与关于信息 |

## widgets/ — 可复用组件

| 目录 / 文件 | 职责 |
| --- | --- |
| `common/page_scaffold.dart` | `PageScaffold` / `PageScaffold.builder`：标准滚动页面骨架（内容居中 + 底部预留播放条留白）；`CenteredPage`：居中、非滚动的页面骨架 |
| `common/section_header.dart` | `SectionHeader` / `SectionHeaderSize`：全站页面标题与区块标题的统一入口 |
| `common/list_card.dart` | `ListCard`：把多行 tile 堆叠成一个圆角裁切面板 |
| `common/cover_artwork.dart` | `CoverArtwork` / `CoverArtworkStyle`：方形封面。默认渲染生成式场景，低于 32dp 自动退化为「首字符 + 渐变」字母块 |
| `common/generated_artwork.dart` | `GeneratedArtwork` / `GeneratedScene`：用 `CustomPainter` 画出的 7 套场景（日落海、冬夜、暖色抽象、日光、星云、雾中山脊、极光）。`forKey` 用 FNV-1a 稳定哈希选场景；`stableArtworkHash` 供字母块选色。**枚举顺序是设计的一部分** |
| `common/ambient_background.dart` | `AmbientBackground`：外壳背后的环境光晕，按 `theme.ambient` 画固定位置的柔光斑（径向渐变淡出，不用 `MaskFilter.blur`） |
| `common/search_launcher.dart` | `SearchLauncherField`：只读搜索框，点击 push `AppRoutes.search`。标题栏与首页页头共用同一个控件 |
| `common/glass_container.dart` | `GlassContainer`：`ClipRRect + BackdropFilter` 液态玻璃容器，支持表面渐变、渐变描边、高光与配置化透明度，仅用于 Floating Player Bar 等强调元素 |
| `common/responsive_layout.dart` | `ResponsiveLayout`：Mobile / Tablet / Desktop 三槽位布局，被 `MainShell` 用于选择外壳 |
| `common/placeholder_page.dart` | 通用占位页（收藏 / 设置） |
| `navigation/desktop_navigation.dart` | `DesktopNavigationPanel` / `MuseNavigationRail` / `MuseBottomNavigationBar`。面板与 rail 都透明，共用外壳面；无 logo（品牌在标题栏）、无页脚 |
| `player/floating_player_bar.dart` | `FloatingPlayerBar`：悬浮玻璃播放条主入口与布局选择 |
| `player/floating_player_bar_layouts.dart` | Desktop / Mobile 播放条内容、封面与标题、移动播放按钮 |
| `player/player_controls.dart` | `PlayerBarControls`：上一首 / 播放暂停 / 下一首 / 音量 |
| `player/player_progress.dart` | `PlayerProgressSlider` / `PlayerProgressLine`：进度与时间 |
| `song/song_tile.dart` | `SongTile` + `SongAction`：标准歌曲行（当前播放用**图标**+ 底色标记，不只靠颜色） |
| `album/album_card.dart` | `AlbumCard`：方形专辑卡片；`onTap` 为 null 时不显示 hover 缩放与指针手型 |
| `window/custom_title_bar.dart` | `CustomTitleBar`：桌面自定义标题栏，支持拖拽、双击最大化 / 还原、最小化与关闭；左侧品牌对齐侧边导航列，中间居中搜索入口；自身不画不透明底色（环境光晕透出） |

## 复用关系

- `PageScaffold` 被 Home、Library、Playlist、Settings 直接复用，并被 Search 以
  `PageScaffold.builder` 形式复用；`CenteredPage` 仅用于 Now Playing。
  页面的居中宽度（`pageMaxWidth` / `pageMaxWidthText`）与底部留白
  （`scrollBottomPadding`）只在这一个文件里出现。
- `SectionHeader` 是全站唯一的标题入口，按 `SectionHeaderSize`
  （page / section / subsection）映射到 `headlineMedium` / `titleLarge` / `titleMedium`，
  **同时区分字重与颜色**，不只靠字号分层次。
- `ListCard` 被 Library（曲库、歌手）与 Playlist（曲目）复用。
- `AppMotion.of` 被 `home_cards`、`album_card`、`player_controls`、
  `floating_player_bar_layouts`、`desktop_navigation`、`now_playing_widgets`
  六处动画调用。
- `SongTile` 被 Home、Search、Library、Playlist 复用。
- `CoverArtwork` 被 `SongTile`、`AlbumCard`、`PlaylistCard`、`RecentSongCard`、
  `NowPlayingPage`、`FloatingPlayerBar` 复用；它内部对非方形表面（如 Hero 横幅）
  通过 `GeneratedArtwork` 直接铺满。
- `SearchLauncherField` 被 `CustomTitleBar`（桌面）与 `HomeHeader`（其他外壳）
  复用，两个入口是同一个控件。
- `GeneratedScene.forKey` 的场景映射被 `test/generated_artwork_test.dart` 钉住 ——
  枚举顺序一改，全应用封面重排。
- `formatDuration` 被 `SongTile`、`PlayerProgressSlider`、`RecentSongCard` 复用。
- `GlassContainer` 仅用于 `FloatingPlayerBar`，避免列表区域重复触发
  `BackdropFilter` 带来的 GPU 开销。

## 设计约束（改 UI 前先读）

这些来自 `docs/m3-audit.md` 的修复，改回去会让审计项重新失败：

- **不要用颜色单独表达状态。** 当前播放行同时有图标（形状线索）与底色；
  `SongTile` 的图标带 `semanticLabel`，读屏软件能播报。
- **不要新增 `Duration(milliseconds: ...)` 字面量。** 走 `AppMotion`。
- **不要引入 M3 形状标尺之外的圆角。** 走 `AppSizes.shape*`。
- **不要把 `outline` 与 `outlineVariant` 设成同一个值**，也不要让
  `surfaceContainer*` 五级塌陷成一级。
- **不要放点了没反应的控件。** 没有目的地就传 `onTap: null` 让组件呈现为非交互，
  而不是传一个空闭包 —— 空闭包会渲染出完整的水波纹、hover 与 tooltip，
  读屏软件还会把它播报为可操作按钮。`SongActionMenu` 因此只列已实现的菜单项
  （`收藏` 在 Phase 4 有存储之前不出现），而不是列出来点了没反应。
- **Hero 上的文字必须压在恒定深色遮罩上。** 场景是生成的，颜色不可控；
  直接往图上放白字会让某些「场景 × 主题」组合掉到 4.5:1 以下。
- **场景特征尺寸按 `size.shortestSide` 缩放，不要按宽度。** Hero 横幅约 4:1，
  按宽度缩放会把太阳画成巨大圆盘、倒影变成硬边矩形。

对应的回归测试在 `test/accessibility_test.dart`、
`test/generated_artwork_test.dart` 与 `test/player_queue_test.dart`。
