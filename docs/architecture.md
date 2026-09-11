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
│   ├── constants/             #   尺寸、导航分区
│   ├── extensions/            #   BuildContext 响应式扩展
│   ├── network/               #   BackendConfig / RustApiClient 占位
│   └── utils/                 #   通用格式化工具
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
        └── AppConfigLoader.load()
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

外壳 `MainShell` 使用 `LayoutBuilder` 依据宽度切换布局：

| 断点 | 宽度 | 导航形式 | 说明 |
| --- | --- | --- | --- |
| Mobile | `< 700` | Material `NavigationBar` | 底部导航 + Floating Player Bar |
| Tablet | `700 ~ 1100` | `NavigationRail` | 侧边导航，Floating Player Bar 显示当前时间 |
| Desktop | `> 1100` | 自定义 `DesktopNavigationPanel` | 220px 侧边面板，Floating Player Bar 完整控制 |

所有页面内容通过 `ConstrainedBox(maxWidth: 1200)` 居中，
保证超宽屏下内容不拉伸。

Floating Player Bar 始终位于 `Stack` 中，并使用
`Positioned(left/right/bottom)` 悬浮在内容之上，而不是作为
`bottomNavigationBar` 贴在窗口底部。所有可滚动页面底部预留
`AppSizes.scrollBottomPadding = 150`，避免内容与操作按钮被遮挡。

## 主题系统

`AppTheme` 提供 `light(ThemePalette)` / `dark(ThemePalette)` 两套 `ThemeData`：

- 明暗色板定义在 `assets/config/app_config.json` 的 `theme` 段，支持
  `mode` / `light` / `dark`。
- `ThemeConfig` / `ThemePalette` 负责解析十六进制颜色，小写文件名见
  `lib/core/config/theme_config.dart`。
- `ColorScheme.fromSeed(...).copyWith(...)` 使用配置中的
  `primary` / `primaryContainer` / `surface` / `onSurface` 等精确色值。
- `MaterialApp.themeMode` 默认来自 `config.theme.mode`，并通过
  `themeModeProvider` 支持设置页运行时切换。
- Phase 1 默认色板仅作为 JSON 缺失或解析失败时的 fallback。
- 仅 Floating Player Bar 使用 `GlassContainer + BackdropFilter`，
  普通列表和卡片保持普通 Surface，避免不必要的 GPU 开销。

## 后端接缝

`core/network` 目录为未来 Rust 后端预留：

- `BackendConfig`：从 `app_config.json` 的 `backend` 段解析 base URL 与端点路径。
- `RustApiClient`：空壳单例，Phase 1 不实现任何网络调用。

详细接口契约见 [backend-api.md](backend-api.md)。
