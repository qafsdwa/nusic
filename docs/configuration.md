# 配置系统

Muse Player 在应用启动时从 `assets/config/app_config.json` 读取配置，
并通过 Riverpod 的 `appConfigProvider` 暴露给整个组件树。

配置系统当前属于 **Phase 1 基础设施**：它不会发起网络请求，也不会改变
Mock UI 的真实数据来源，但已经为后续 Rust 后端地址、播放器初始默认值、
主题色板、构建环境切换预留了统一入口。

## 配置文件位置

```text
assets/config/app_config.json
```

该文件必须在 `pubspec.yaml` 的 `flutter.assets` 中声明：

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/config/app_config.json
```

## 配置示例

```json
{
  "appName": "Muse Player",
  "environment": "development",
  "enableMockData": true,
  "enableNetwork": false,
  "backend": {
    "baseUrl": "http://127.0.0.1:8080",
    "songsSearchPath": "/songs/search",
    "songPath": "/songs",
    "playlistPath": "/playlist",
    "playerWebSocketPath": "/ws/player"
  },
  "player": {
    "initialVolume": 0.7,
    "defaultShuffle": false,
    "defaultRepeatMode": "off"
  },
  "theme": {
    "mode": "system",
    "light": {
      "primary": "#1A73E8",
      "onPrimary": "#FFFFFF",
      "primaryContainer": "#D2E3FC",
      "onPrimaryContainer": "#202124",
      "background": "#F8F9FA",
      "surface": "#FFFFFF",
      "surfaceVariant": "#F1F3F4",
      "textPrimary": "#202124",
      "textSecondary": "#5F6368",
      "divider": "#DADCE0"
    },
    "dark": {
      "primary": "#8AB4F8",
      "onPrimary": "#202124",
      "primaryContainer": "#174EA6",
      "onPrimaryContainer": "#E8EAED",
      "background": "#202124",
      "surface": "#292A2D",
      "surfaceVariant": "#303134",
      "textPrimary": "#E8EAED",
      "textSecondary": "#BDC1C6",
      "divider": "#3C4043"
    },
    "glass": {
      "blur": 24,
      "borderWidth": 1,
      "shadowBlurRadius": 28,
      "shadowSpreadRadius": 1,
      "shadowOffsetY": 8,
      "light": {
        "surfaceStart": "#FFFFFF",
        "surfaceStartOpacity": 0.76,
        "surfaceEnd": "#FFFFFF",
        "surfaceEndOpacity": 0.56,
        "borderStart": "#FFFFFF",
        "borderStartOpacity": 0.92,
        "borderMiddle": "#FFFFFF",
        "borderMiddleOpacity": 0.30,
        "borderEnd": "#FFFFFF",
        "borderEndOpacity": 0.70,
        "highlight": "#FFFFFF",
        "highlightOpacity": 0.32,
        "shadow": "#000000",
        "shadowOpacity": 0.08
      },
      "dark": {
        "surfaceStart": "#2A2B2F",
        "surfaceStartOpacity": 0.78,
        "surfaceEnd": "#1F2023",
        "surfaceEndOpacity": 0.66,
        "borderStart": "#FFFFFF",
        "borderStartOpacity": 0.22,
        "borderMiddle": "#FFFFFF",
        "borderMiddleOpacity": 0.04,
        "borderEnd": "#FFFFFF",
        "borderEndOpacity": 0.10,
        "highlight": "#FFFFFF",
        "highlightOpacity": 0.10,
        "shadow": "#000000",
        "shadowOpacity": 0.25
      }
    }
  }
}
```

## 字段说明

### 根字段

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `appName` | string | `"Muse Player"` | `MaterialApp.title` |
| `environment` | string | `"development"` | 当前环境标识，建议值：`development` / `staging` / `production` |
| `enableMockData` | bool | `true` | 是否使用 Mock 数据。Phase 1 必须为 `true` |
| `enableNetwork` | bool | `false` | 是否允许真实网络请求。Phase 1 保持 `false` |
| `backend` | object | 见下 | Rust 后端地址与端点路径 |
| `player` | object | 见下 | 播放器初始状态默认值 |
| `theme` | object | 见下 | 主题模式与明暗色板 |

### `backend`

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `baseUrl` | string | `http://127.0.0.1:8080` | 后端基础地址 |
| `songsSearchPath` | string | `/songs/search` | 搜索歌曲端点 |
| `songPath` | string | `/songs` | 单曲详情端点前缀 |
| `playlistPath` | string | `/playlist` | 播放列表端点 |
| `playerWebSocketPath` | string | `/ws/player` | 播放状态同步 WebSocket 端点 |

### `player`

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `initialVolume` | number | `0.7` | 初始音量，范围 `0.0` ~ `1.0` |
| `defaultShuffle` | bool | `false` | 初始随机播放状态 |
| `defaultRepeatMode` | string | `"off"` | 初始循环模式：`off` / `all` / `one` |

### `theme`

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `mode` | string | `"system"` | 主题模式：`system` / `light` / `dark` |
| `light` | object | `ThemePalette.lightFallback` | 浅色模式色板 |
| `dark` | object | `ThemePalette.darkFallback` | 深色模式色板 |
| `glass` | object | `GlassConfig.fallback` | 底部 Floating Player Bar 液态玻璃参数 |

#### `theme.glass`

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `blur` | number | `24` | 背景模糊 sigma，越大越模糊 |
| `borderWidth` | number | `1` | 玻璃边框宽度 |
| `shadowBlurRadius` | number | `28` | 外阴影模糊半径 |
| `shadowSpreadRadius` | number | `1` | 外阴影扩散半径 |
| `shadowOffsetY` | number | `8` | 外阴影向下偏移 |
| `light` | object | 见下 | 浅色模式玻璃参数 |
| `dark` | object | 见下 | 深色模式玻璃参数 |

#### `theme.glass.light` / `theme.glass.dark`

| 字段 | 类型 | 默认值（light / dark） | 说明 |
| --- | --- | --- | --- |
| `surfaceStart` | string | `#FFFFFF` / `#2A2B2F` | 玻璃表面渐变起点色 |
| `surfaceStartOpacity` | number | `0.76` / `0.78` | 渐变起点透明度 |
| `surfaceEnd` | string | `#FFFFFF` / `#1F2023` | 玻璃表面渐变终点色 |
| `surfaceEndOpacity` | number | `0.56` / `0.66` | 渐变终点透明度 |
| `borderStart` | string | `#FFFFFF` / `#FFFFFF` | 渐变描边起点色 |
| `borderStartOpacity` | number | `0.92` / `0.22` | 描边起点透明度 |
| `borderMiddle` | string | `#FFFFFF` / `#FFFFFF` | 渐变描边中间色 |
| `borderMiddleOpacity` | number | `0.30` / `0.04` | 描边中间透明度 |
| `borderEnd` | string | `#FFFFFF` / `#FFFFFF` | 渐变描边终点色 |
| `borderEndOpacity` | number | `0.70` / `0.10` | 描边终点透明度 |
| `highlight` | string | `#FFFFFF` / `#FFFFFF` | 左上高光颜色 |
| `highlightOpacity` | number | `0.32` / `0.10` | 高光透明度 |
| `shadow` | string | `#000000` / `#000000` | 阴影颜色 |
| `shadowOpacity` | number | `0.08` / `0.25` | 阴影透明度 |

#### `theme.light` / `theme.dark`

两个色板结构相同，颜色值使用十六进制字符串，支持：

- `#RRGGBB`
- `#AARRGGBB`

| 字段 | 对应 Material 3 角色 | 说明 |
| --- | --- | --- |
| `primary` | `colorScheme.primary` | 主色 |
| `onPrimary` | `colorScheme.onPrimary` | 主色上的文字 / 图标 |
| `primaryContainer` | `colorScheme.primaryContainer` | 主色容器 |
| `onPrimaryContainer` | `colorScheme.onPrimaryContainer` | 主色容器上的内容 |
| `background` | `scaffoldBackgroundColor` | 页面背景 |
| `surface` | `colorScheme.surface` | 卡片 / 面板表面 |
| `surfaceVariant` | `colorScheme.surfaceContainerHighest` | 搜索框、次级表面 |
| `textPrimary` | `colorScheme.onSurface` | 主文字 |
| `textSecondary` | `colorScheme.onSurfaceVariant` | 次级文字 |
| `divider` | `colorScheme.outline` / `outlineVariant` | 分割线与描边 |

`AppTheme` 不再硬编码颜色，而是从 `ThemeConfig` / `ThemePalette` 构建
`ThemeData`。因此修改 `app_config.json` 即可切换主题模式与明暗色板。

### 运行时切换主题

设置页的「主题」按钮会调用 `themeModeProvider`，在当前运行会话内循环切换
`跟随系统 -> 浅色 -> 深色 -> 跟随系统`。该操作只修改运行时状态，不会写回
`app_config.json`；下次启动仍以配置文件中的 `theme.mode` 为准。

## 初始化流程

```text
main()
  │
  ▼
initializeApp()
  │  WidgetsFlutterBinding.ensureInitialized()
  ▼
AppConfigLoader.load()
  │  rootBundle.loadString('assets/config/app_config.json')
  │  json.decode(...)
  │  AppConfig.fromJson(...)
  ▼
AppConfig
  │
  ├──▶ ProviderScope overrides: appConfigProvider.overrideWithValue(config)
  │
  ├──▶ MuseApp 读取 appName + theme.mode / theme.light / theme.dark
  │
  ├──▶ AppTheme.light(...), AppTheme.dark(...), AppTheme.resolveThemeMode(...)
  │
  └──▶ PlayerNotifier 读取 player.initialVolume / defaultShuffle / defaultRepeatMode
```

关键文件：

| 文件 | 职责 |
| --- | --- |
| `lib/core/config/app_config.dart` | `AppConfig`、`PlayerConfig` 数据模型与 JSON 解析 |
| `lib/core/config/theme_config.dart` | `ThemeConfig`、`ThemePalette` 与颜色 hex 解析 |
| `lib/core/config/glass_config.dart` | `GlassConfig`、`GlassPalette`：底部玻璃条颜色、透明度、模糊与阴影 |
| `lib/core/config/config_color.dart` | 配置颜色 / 透明度 / 数值解析工具 |
| `lib/core/network/backend_config.dart` | `BackendConfig` 数据模型与 JSON 解析 |
| `lib/core/config/app_config_loader.dart` | 从 Flutter asset 加载并解析配置 |
| `lib/core/config/app_config_provider.dart` | Riverpod `appConfigProvider` |
| `lib/core/config/app_bootstrap.dart` | 启动初始化：绑定 Flutter 并加载配置 |
| `lib/main.dart` | 在 `runApp` 前完成配置加载并 override Provider |
| `lib/app/theme.dart` | 根据配置色板构建 Material 3 `ThemeData` |

## 读取配置

在 Widget 中：

```dart
final AppConfig config = ref.watch(appConfigProvider);
final String appName = config.appName;
final ThemeMode themeMode = AppTheme.resolveThemeMode(config.theme.mode);
```

在 `Notifier` / 非 Widget 逻辑中：

```dart
final AppConfig config = ref.read(appConfigProvider);
final double volume = config.player.initialVolume;
```

不建议在业务代码中直接读取 JSON 文件，统一通过 `appConfigProvider` 访问，
方便未来替换为远程配置或构建环境变量。

## 容错行为

`AppConfigLoader` 不会抛出异常。以下情况会自动回退到
`AppConfig.fallback`：

- asset 文件缺失；
- JSON 语法错误；
- JSON 根节点不是对象；
- 某个字段缺失或类型不符。

颜色字段解析失败时，会单独回退到对应 `ThemePalette` 的默认值。
回退时仅输出 `debugPrint`，应用仍可正常启动。这样可以保证
`flutter run`、`flutter test` 和截图预览不会被配置问题阻塞。

## 修改配置

1. 编辑 `assets/config/app_config.json`。
2. 运行热重启（Hot Restart）或重新启动应用。
3. 执行静态检查：

```bash
dart format .
flutter analyze
flutter test
```

## 后续扩展

- Phase 3 接入 Rust 后，`enableNetwork` 切换为 `true`，并读取 `backend` 配置。
- 如需多环境构建，可按 flavor 替换不同 asset，或后续引入
  `--dart-define` / `--dart-define-from-file`。
- 不要在 asset 配置中存放密钥；敏感信息应使用构建时注入或安全存储。
