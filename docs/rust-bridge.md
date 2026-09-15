# Rust 桥接数据契约

本文档定义 Muse Player 使用 `flutter_rust_bridge`（FRB）与 Rust 后端联动时的
Dart ↔ Rust 数据结构。

当前阶段只落地 **数据契约 + Dart 映射层 + Rust 模型骨架**，不包含真实音频播放。

## 设计目标

- **值语义优先**：跨 FFI 传普通结构体 / 枚举，避免把 Rust 对象当成不透明句柄。
- **单一数据源**：完整状态只通过 `BridgePlayerSnapshot` 传递。
- **增量事件**：播放进度等高频变化使用 `BridgePlayerEvent::PositionChanged`，
  避免每次 tick 复制整个队列。
- **类型安全**：命令与事件使用带字段的 enum，而不是 JSON 字符串或 `Map`。
- **UI 解耦**：Flutter UI 继续使用 `Song` / `PlayerState`；
  `BridgeMapper` 负责在两边转换。

## 目录

```text
rust/
├── Cargo.toml
└── src/
    ├── lib.rs
    └── api/
        ├── mod.rs
        └── bridge_models.rs      # Rust 侧数据契约

lib/core/bridge/
├── bridge_models.dart            # Dart 侧手写镜像
├── bridge_mapper.dart            # UI 模型 ↔ Bridge DTO 转换
└── generated/                    # FRB codegen 输出目录（待生成）

flutter_rust_bridge.yaml          # FRB 配置
```

## Rust 数据模型

### `BridgeTrack`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | `String` | 歌曲唯一 ID |
| `title` | `String` | 标题 |
| `artist` | `String` | 艺术家 |
| `album` | `String` | 专辑 |
| `cover_url` | `Option<String>` | 封面 URL；Mock 阶段可为空 |
| `duration_ms` | `i64` | 总时长，毫秒 |
| `source` | `BridgeTrackSource` | 来源：本地 / 远程 / Mock / 未知 |

使用 `duration_ms: i64` 而不是 `Duration`，因为 `Duration` 在 FRB 中会变成
不透明类型或需要额外转换，而毫秒整数可以直接跨 FFI。

### `BridgePlaybackStatus`

```text
Idle / Loading / Playing / Paused / Buffering / Error
```

对应 UI 的 `PlayerStatus`。

### `BridgeRepeatMode`

```text
Off / All / One
```

对应 UI 的 `RepeatMode`。

### `BridgePlayerSnapshot`

完整播放器状态：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `current_track` | `Option<BridgeTrack>` | 当前歌曲 |
| `status` | `BridgePlaybackStatus` | 播放状态 |
| `position_ms` | `i64` | 当前进度 |
| `duration_ms` | `i64` | 当前歌曲总时长 |
| `volume` | `f64` | 音量 `0.0 ~ 1.0` |
| `is_shuffle` | `bool` | 随机播放 |
| `repeat_mode` | `BridgeRepeatMode` | 循环模式 |
| `queue` | `Vec<BridgeTrack>` | 当前队列 |
| `current_index` | `i32` | 队列索引 |
| `updated_at_ms` | `i64` | Rust 生成快照的时间戳 |

### `BridgePlayerCommand`

Flutter → Rust 的命令，使用带字段 enum：

```rust
Play { track_id: String }
PlayTrack { track: BridgeTrack }
PlayQueue { tracks: Vec<BridgeTrack>, start_index: i32 }
Pause
Resume
Toggle
Next
Previous
Seek { position_ms: i64 }
SetVolume { volume: f64 }
SetShuffle { enabled: bool }
SetRepeat { mode: BridgeRepeatMode }
ClearQueue
RequestSnapshot
```

### `BridgePlayerEvent`

Rust → Flutter 的事件流：

```rust
Snapshot { snapshot: BridgePlayerSnapshot }
PositionChanged { position_ms: i64, duration_ms: i64 }
StatusChanged { status: BridgePlaybackStatus }
TrackChanged { track: BridgeTrack, index: i32 }
QueueChanged { tracks: Vec<BridgeTrack>, current_index: i32 }
VolumeChanged { volume: f64 }
Error { error: BridgeError }
```

高频进度只发送 `PositionChanged`；切歌 / 队列变化等低频操作发送完整或增量事件。

### `BridgeError` / `BridgeErrorCode`

结构化错误：

```rust
BridgeError {
    code: BridgeErrorCode,
    message: String,
    details: Option<String>,
}
```

错误码：

```text
Unknown / NotInitialized / InvalidTrack / AudioOutput
Network / Decode / Unsupported / Cancelled
```

### `BridgeInitConfig`

Rust 初始化参数：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `enable_network` | `bool` | 是否允许网络请求 |
| `backend_base_url` | `Option<String>` | Rust 后端地址 |
| `cache_dir` | `Option<String>` | 音频缓存目录 |
| `default_volume` | `f64` | 初始音量 |

### `BridgeLyricLine`

预留歌词结构：

```rust
BridgeLyricLine { start_ms: i64, text: String }
```

## Dart 侧映射

`lib/core/bridge/bridge_mapper.dart` 提供：

```dart
BridgeMapper.fromSong(Song) -> BridgeTrack
BridgeMapper.toSong(BridgeTrack) -> Song
BridgeMapper.fromPlayerState(PlayerState) -> BridgePlayerSnapshot
BridgeMapper.fromPlayerStatus(PlayerStatus) -> BridgePlaybackStatus
BridgeMapper.toPlayerStatus(BridgePlaybackStatus) -> PlayerStatus
BridgeMapper.fromRepeatMode(RepeatMode) -> BridgeRepeatMode
BridgeMapper.toRepeatMode(BridgeRepeatMode) -> RepeatMode
```

这样 UI Provider 和 Widget 不需要知道 Bridge 的毫秒时间戳、可空封面 URL
或 Bridge 专用枚举。

## 推荐 Rust API 形态

代码生成后，建议 Rust 侧暴露以下 API：

```rust
#[frb]
pub fn init_bridge(config: BridgeInitConfig) -> BridgeResult;

#[frb]
pub fn dispatch_player_command(command: BridgePlayerCommand) -> BridgeResult;

#[frb]
pub fn get_player_snapshot() -> BridgePlayerSnapshot;

#[frb]
pub fn subscribe_player_events(sink: StreamSink<BridgePlayerEvent>);
```

对应 Dart 生成代码使用：

```dart
await initBridge(config: ...);
await dispatchPlayerCommand(command: ...);
final snapshot = await getPlayerSnapshot();

subscribePlayerEvents().listen((event) {
  switch (event) {
    case BridgePlayerEvent_Snapshot(:final snapshot):
      // 更新 Riverpod 状态
    case BridgePlayerEvent_PositionChanged(:final positionMs):
      // 只更新进度
  }
});
```

## 接入 Flutter 状态

推荐的 Riverpod 流程：

```text
Rust Player
   │
   ├── init_bridge(config)
   ├── dispatch_player_command(command)
   └── subscribe_player_events(sink)
          │
          ▼
   BridgeMapper.toSong / toPlayerStatus / ...
          │
          ▼
   PlayerNotifier / PlayerState
          │
          ▼
   FloatingPlayerBar / NowPlayingPage
```

- 命令：`PlayerNotifier` 方法 → `BridgePlayerCommand` → `dispatchPlayerCommand`
- 状态：`BridgePlayerEvent` → `PlayerState.copyWith` → UI 自动刷新
- Phase 1 Mock 阶段仍由 `MockMusic` + `PlayerNotifier` 驱动，不调用 FRB。

## 生成 FRB 代码

首次生成前：

```bash
cargo install flutter_rust_bridge_codegen
```

确保 `pubspec.yaml` 包含：

```yaml
dependencies:
  flutter_rust_bridge: ^2.13.0
```

然后根目录执行：

```bash
flutter_rust_bridge_codegen generate
```

生成目录：

```text
lib/core/bridge/generated/
```

配置见根目录：

```text
flutter_rust_bridge.yaml
```

生成后：
1. 将 `BridgeMapper` 中的手写 DTO 替换为 `generated` 中的 FRB 类型；
2. 保持字段名与 `bridge_models.rs` 一致；
3. 先接 `get_player_snapshot` 与 `dispatch_player_command`，再接事件流。

## 设计注意事项

- **不要跨 FFI 传 `Duration`**：一律使用毫秒 `i64`。
- **不要用 `HashMap` 做队列**：使用 `Vec<BridgeTrack>`，顺序确定且 Dart 映射简单。
- **避免高频全量快照**：进度更新使用 `PositionChanged`。
- **避免在 DTO 中放隐藏句柄**：当前结构都是可复制的值类型。
- 未来真实音频引擎的句柄、Decoder、OutputStream 等留在 Rust 内部，
  不通过 Bridge 暴露。
