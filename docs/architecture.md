# 架构总览

## 项目定位

Muse Player 是一个**桌面优先**、兼容 Windows / Linux / macOS / Android / iOS
的跨平台音乐播放器 UI 客户端。界面采用 Material Design 3（Material You）
与轻度 Liquid Glass 风格，中文界面。

当前为 **Phase 1**：仅实现「项目架构 + Mock UI」。真实音频播放与后端调用尚未接入，
所有歌曲数据来自 `lib/mock/mock_music.dart` 中的静态假数据。

## 技术栈

| 层 | 选型 |
| --- | --- |
| UI | Flutter 3.x / Dart 3.13 |
| 状态管理 | `flutter_riverpod`（`NotifierProvider` / `Provider`） |
| 主题 | Material 3（`ColorScheme.fromSeed`） |
| 配置 | `assets/config/app_config.json` + 启动初始化 |
| 布局 | 响应式 `LayoutBuilder` + 自定义 Desktop 导航 / `NavigationRail` / `NavigationBar` |
| 未来后端 | Rust REST API + WebSocket |

## 分层结构

代码按职责分层，依赖方向自上而下（上层依赖下层，下层不依赖上层）：

```text
lib/
├── main.dart                  # 入口：初始化配置 + ProviderScope
├── app/                       # 应用层
│   ├── app.dart               #   MuseApp + MainShell 响应式外壳
│   ├── breakpoints.dart       #   Mobile / Tablet / Desktop 断点
│   ├── router.dart            #   命名路由表
│   └── theme.dart             #   Material 3 明暗主题
├── core/                      # 基础设施层
│   ├── config/                #   AppConfig / Loader / Provider / Bootstrap
│   ├── constants/             #   尺寸、形状令牌、导航分区
│   ├── network/               #   BackendConfig / RustApiClient 占位
│   ├── window/                #   桌面窗口初始化与自定义标题栏开关
│   └── utils/                 #   格式化工具与动效时长（AppMotion）
├── mock/                      # Phase 1 Mock 数据
│   └── mock_music.dart
├── models/                    # 领域模型（Song、Album、Playlist）
├── providers/                 # Riverpod 状态（Player、Navigation、ThemeMode）
├── pages/                     # 页面级组件
│   ├── home/
│   ├── library/
│   ├── now_playing/
│   ├── playlist/
│   ├── search/
│   └── settings/
└── widgets/                   # 可复用组件
    ├── album/
    ├── common/
    ├── navigation/
    ├── player/
    ├── window/                 # CustomTitleBar
    └── song/
```

### 依赖关系

- `pages` / `widgets` 依赖 `models`、`providers`、`core/constants`、`core/utils`。
- `providers` 依赖 `models`、`mock`、`core/config`（读取播放器默认值与 Mock 数据）。
- `core/config` 依赖 `core/network` 的 `BackendConfig` 数据模型。
- `core/network` 中的 `RustApiClient` 目前为空壳，为后续 Rust 接入预留接缝。
- `app` 层依赖配置 Provider，但不直接读取 JSON。

## 启动与配置初始化

```text
main()
  └── initializeApp()
        ├── WidgetsFlutterBinding.ensureInitialized()
        ├── AppConfigLoader.load()
        └── setUpDesktopWindow()
              ├── rootBundle.loadString(...)
              ├── json.decode(...)
              └── AppConfig.fromJson(...)
  └── runApp(
        ProviderScope(
          overrides: appConfigProvider.overrideWithValue(config),
          child: MuseApp(),
        ),
      )
```

- 桌面窗口：`lib/core/window/window_setup.dart` 隐藏原生标题栏，Flutter
  侧由 `lib/widgets/window/custom_title_bar.dart` 提供拖拽与窗口控制。
- 配置文件：`assets/config/app_config.json`
- 配置模型：`lib/core/config/app_config.dart`
- 加载器：`lib/core/config/app_config_loader.dart`
- Provider：`lib/core/config/app_config_provider.dart`
- 启动初始化：`lib/core/config/app_bootstrap.dart`

详细字段与容错行为见 [configuration.md](configuration.md)。

## 数据流

Phase 1 的数据流是「单向」的：

```text
AppConfig + MockMusic (静态资源)
   │
   ├──▶ 页面直接读取（Home / Search / Library 列表渲染）
   │
   └──▶ PlayerNotifier.build() 初始化队列与播放器默认值
            │
            └──▶ playerProvider ──▶ ref.watch ──▶ FloatingPlayerBar / NowPlayingPage 响应式刷新
```

用户交互（点击歌曲、播放/暂停、上一首/下一首）通过
`ref.read(playerProvider.notifier)` 调用 `PlayerNotifier` 的方法，
修改不可变的 `PlayerState`，再由 Riverpod 通知订阅者重建 UI。

## 状态模型

`PlayerState` 是不可变对象（`copyWith` 返回新实例），字段：

- `currentSong` / `queue` / `currentIndex`：当前曲目与队列。
- `status`：`PlayerStatus`（idle / loading / playing / paused / buffering / error）。
- `position` / `duration`：进度与总时长。
- `volume` / `isShuffle` / `repeatMode`：播放器偏好，初始值来自 `AppConfig`。

该状态**与真实音频引擎解耦**，后续可被 `just_audio` / `audio_service`
或 Rust WebSocket 推送的播放状态覆盖，无需改动 UI。

## 响应式布局

外壳 `MainShell` 通过 `ResponsiveLayout` 依据可用宽度选择布局。
断点对齐 **Material 3 window size class**，而不是设备名：

| 断点 | 宽度 | M3 window size class | 导航形式 | 说明 |
| --- | --- | --- | --- | --- |
| Mobile | `< 600` | compact | Material `NavigationBar` | 底部导航 + Floating Player Bar |
| Tablet | `600 ~ 1199` | medium + expanded | `NavigationRail` | 侧边导航，Floating Player Bar 显示当前时间 |
| Desktop | `>= 1200` | large + extra-large | 自定义 `DesktopNavigationPanel` | 220px 侧边面板，Floating Player Bar 完整控制 |

M3 的原始边界是 600 / 840 / 1200 / 1600。`medium` 与 `expanded` 共用 rail 外壳，
`large` 与 `extra-large` 共用常驻面板，因此只需要两个阈值 —— 但它们是 M3 的阈值，
不是随手定的设备宽度。`AppBreakpoints` 同时导出 `compactMax` / `mediumMax` /
`expandedMax` 供需要原始 M3 边界的场合使用。

### 导航结构

外壳有 **5 个分区**（首页 / 音乐库 / 收藏 / 播放列表 / 设置），在 compact 尺寸下
正好落在 M3 对底部导航「3–5 个目的地」的建议区间内。

`AppSection` 枚举的顺序**即**导航顺序，其 `index` **即** shell 的页面索引；
`app.dart` 直接遍历 `AppSection.values` 构建 `IndexedStack`，因此
"页面列表与枚举顺序不一致" 这类错误在编译期就不可能发生，新增分区也会强制补上页面。

**搜索不是分区**。首页头部已经带搜索框，再占一个导航位是冗余的；搜索改为 push
`AppRoutes.search` 路由（自带 AppBar 与返回），首页头部是它的唯一入口。

所有页面内容通过 `ConstrainedBox` 居中。**最大宽度按内容类型分两档**：

| 常量 | 值 | 用途 |
| --- | --- | --- |
| `AppSizes.pageMaxWidth` | 1200 | 网格 / 封面类页面（首页、音乐库、歌单） |
| `AppSizes.pageMaxWidthText` | 1040 | 文本密集页面（搜索、设置） |

M3 建议 large / extra-large 窗口下的阅读型内容约束在 840–1040dp；
1200dp 下行长过长，视线回行容易丢位。

Floating Player Bar 始终位于 `Stack` 中，并使用
`Positioned(left/right/bottom)` 悬浮在内容之上，而不是作为
`bottomNavigationBar` 贴在窗口底部。所有可滚动页面底部预留
`AppSizes.scrollBottomPadding = 150`，避免内容与操作按钮被遮挡。
这两件事都由 `PageScaffold` 统一保证。

## 主题系统

`AppTheme` 提供 `light(ThemePalette)` / `dark(ThemePalette)` 两套 `ThemeData`：

- 明暗色板与底部玻璃参数定义在 `assets/config/app_config.json` 的 `theme` 段，
  支持 `mode` / `light` / `dark` / `glass`。
- `ThemeConfig` / `ThemePalette` 负责解析十六进制颜色，见
  `lib/core/config/theme_config.dart`。
- 色板字段名直接采用 M3 的 `md.sys.color.*` 角色名，避免一层翻译。
- `ColorScheme.fromSeed(...).copyWith(...)` 使用配置中的精确色值。
- `MaterialApp.themeMode` 默认来自 `config.theme.mode`，并通过
  `themeModeProvider` 支持设置页运行时切换。
- Phase 1 默认色板仅作为 JSON 缺失或解析失败时的 fallback。
- 仅 Floating Player Bar 使用 `GlassContainer + BackdropFilter`，
  普通列表和卡片保持普通 Surface，避免不必要的 GPU 开销。

### 两个必须保持的语义区分

**`outline` ≠ `outlineVariant`**。前者标记重要边界（输入框描边、聚焦环），
后者是装饰性分隔（分割线）。把它们设成同一个值会让分割线与输入框描边无法区分，
且之后想调任一方都会连带改动另一方。

**`surfaceContainer*` 五级色阶不能塌陷**。M3 用 **tonal surface 而非阴影**表达高度，
靠 `Lowest / Low / Container / High / Highest` 五级递进区分层级。
把五级指向同一个色值，就等于失去了表达高度的唯一手段 —— 这也是为什么卡片
只能一律 `elevation: 0`。

### 装饰性渐变

首页 Hero 卡片是全应用唯一一块大面积装饰表面。它的色相跨度大、不对应任何单个 M3
颜色角色，因此放在 `theme.heroGradient`（明暗各一组色标）里，而不是写死在 widget 中。
解析是「全有或全无」的 —— 半解析的渐变既不是配置值也不是默认值，比直接回退更糟。

### 形状令牌

`AppSizes` 中的 `shape*` 常量对齐 M3 的 `md.sys.shape.corner.*` 标尺
（none 0 / xs 4 / sm 8 / md 12 / lg 16 / lgIncreased 20 / xl 28 / xxl 48 / full）。
**不要在标尺之外引入半径** —— 出现 18、24 这类数字通常意味着一次性的决定，
设计一改就会漂移。

唯一的例外是 `AppSizes.floatingPlayerBarRadius = 30`：播放条读起来是一块悬浮玻璃板
而不是一张 sheet，因此刻意落在 `xl`(28) 与 `xxl`(48) 之间。它被保留但**必须保持有注释**，
而不是悄悄四舍五入掉。

### 动效

所有动画时长走 `AppMotion`（`lib/core/utils/motion.dart`），它同时是减少动效的收口点：

- `AppMotion.fast` (170ms) —— hover / 按压反馈
- `AppMotion.standard` (180ms) —— 默认状态切换
- `AppMotion.emphasized` (200ms) —— Now Playing 这类较大表面

`AppMotion.of(context, duration)` 在系统开启"减少动效"
（`MediaQuery.disableAnimations`）时返回 `Duration.zero`。
**新增动画一律走这个入口，不要直接写 `Duration(milliseconds: ...)`** ——
逐个 widget 判断平台偏好必然会漏。

减少动效下状态变化照常发生，只是不再有过渡：反馈保留，表演取消。

## 后端接缝

`core/network` 目录为未来 Rust 后端预留：

- `BackendConfig`：从 `app_config.json` 的 `backend` 段解析 base URL 与端点路径。
- `RustApiClient`：空壳单例，Phase 1 不实现任何网络调用。

详细接口契约见 [backend-api.md](backend-api.md)。
