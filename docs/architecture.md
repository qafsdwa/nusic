# 架构总览

## 项目定位

Muse Player 是一个**桌面优先**（兼容 Android / iOS / Web）的音乐播放器 UI 客户端。
界面采用 Material Design 3（Material You）风格，中文界面。

当前为 **Phase 1**：仅实现「项目架构 + Mock UI」。真实音频播放与后端调用尚未接入，
所有数据来自 `lib/core/constants/mock_data.dart` 中的静态假数据。

## 技术栈

| 层 | 选型 |
| --- | --- |
| UI | Flutter 3.x / Dart 3.13 |
| 状态管理 | `flutter_riverpod`（`NotifierProvider`） |
| 主题 | Material 3（`ColorScheme.fromSeed`） |
| 布局 | 响应式 `LayoutBuilder` + `NavigationRail` / `NavigationBar` |
| 未来后端 | Rust REST API + WebSocket |

## 分层结构

代码按职责分层，依赖方向自上而下（上层依赖下层，下层不依赖上层）：

```text
lib/
├── main.dart              # 入口：ProviderScope 包裹根组件
├── app/                   # 应用层：根组件、路由、主题
│   ├── app.dart           #   MuseApp + 响应式外壳 MainShell
│   ├── router.dart        #   命名路由表
│   └── theme.dart         #   明/暗主题与配色
├── core/                  # 基础设施层（与业务解耦）
│   ├── constants/         #   尺寸、导航分区、Mock 数据
│   ├── network/           #   后端地址与 API 客户端占位
│   └── utils/             #   通用格式化工具
├── models/                # 领域模型（Song、Album）
├── providers/             # Riverpod 状态（PlayerNotifier）
├── pages/                 # 页面级组件
└── widgets/               # 可复用组件
```

### 依赖关系

- `pages` / `widgets` 依赖 `models`、`providers`、`core/constants`、`core/utils`。
- `providers` 依赖 `models`、`core/constants`（读取 Mock 数据）。
- `core/network` 目前为空壳，为后续 Rust 接入预留接缝，不被任何 UI 直接依赖。

## 数据流

Phase 1 的数据流是「单向」的：

```text
MockData (静态常量)
   │
   ├──▶ 页面直接读取（Home / Search / Library 列表渲染）
   │
   └──▶ PlayerNotifier.build() 初始化队列
            │
            └──▶ playerProvider ──▶ ref.watch ──▶ MiniPlayer / NowPlayingPage 响应式刷新
```

用户交互（点击歌曲、播放/暂停、上一首/下一首）通过
`ref.read(playerProvider.notifier)` 调用 `PlayerNotifier` 的方法，
修改不可变的 `PlayerState`，再由 Riverpod 通知订阅者重建 UI。

## 状态模型

`PlayerState` 是不可变对象（`copyWith` 返回新实例），字段：

- `currentSong` / `queue` / `currentIndex`：当前曲目与队列。
- `status`：`PlayerStatus`（idle / loading / playing / paused / buffering / error）。
- `position` / `duration`：进度与总时长。

该状态**与真实音频引擎解耦**，后续可被 `just_audio` / `audio_service`
或 Rust WebSocket 推送的播放状态覆盖，无需改动 UI。

## 响应式布局

外壳 `MainShell` 使用 `LayoutBuilder` 依据宽度切换布局：

| 断点 | 导航形式 | 说明 |
| --- | --- | --- |
| ≥ 900 px | `NavigationRail`（侧边栏，宽 220） | 桌面 / 平板 |
| < 900 px | 底部 `NavigationBar` | 移动端 |

所有页面内容通过 `ConstrainedBox(maxWidth: 1200)` 居中，
保证超宽屏下内容不拉伸。`MiniPlayer` 固定在最底部，横跨所有形态，
内部再按宽度细分出紧凑 / 宽屏两种布局。

## 主题系统

`AppTheme` 提供 `light()` / `dark()` 两套 `ThemeData`：

- 使用 `ColorScheme.fromSeed(seedColor: ...)` 生成 Material 3 配色，
  再覆盖 `primary` / `surface` / `onSurface` 对齐设计稿色值。
- 明暗色板定义在 `AppColors` 中，统一为单一真值来源。
- `MaterialApp.themeMode = ThemeMode.system`，跟随系统明暗。

## 后端接缝

`core/network` 目录为未来 Rust 后端预留：

- `BackendConfig`：集中存放 base URL 与端点路径。
- `RustApiClient`：空壳单例，Phase 1 不实现任何网络调用。

详细接口契约见 [backend-api.md](backend-api.md)。
