# 后端 API 契约（Rust）

> **状态：已实现。** REST 与 WebSocket 端点在 `rust/backend/` 落地，Flutter 侧
> 尚未接入（`RustApiClient` 仍为空壳，见 Phase 3）。本文档既是契约也是实现说明，
> 字段命名与响应结构以本文档为准。

## 基本信息

- Base URL：由 `assets/config/app_config.json` 的 `backend.baseUrl` 提供，默认 `http://127.0.0.1:8080`
- 认证：待定（本地部署，Phase 2 可能为无鉴权或简单 token）
- 编码：JSON，UTF-8

对应客户端配置见 `assets/config/app_config.json` 的 `backend` 段；运行时通过 `appConfigProvider` 读取 `BackendConfig`。

### 启动

```bash
cd rust/backend
cargo run              # 监听 127.0.0.1:8080
```

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `MUSE_BACKEND_PORT` | `8080` | 监听端口 |
| `MUSE_BACKEND_HOST` | `127.0.0.1` | 监听地址。默认只绑回环，因为服务会暴露本地文件；绑 `0.0.0.0` 需显式设置 |
| `MUSE_MUSIC_DIR` | 未设置 | 要扫描的音乐目录；未设置或扫不到文件时回退到内置 seed 目录 |
| `MUSE_PUBLIC_BASE_URL` | `http://127.0.0.1:{port}` | 写进封面绝对 URL 的基地址。绑定地址常是 `0.0.0.0`，客户端需要可访问的主机名，故与监听地址分开 |
| `MUSE_AUDIO` | `auto` | 播放后端：`auto`（有设备用真实输出）/ `rodio`（优先真实输出）/ `silent`（只用虚拟时钟，不碰声卡） |
| `RUST_LOG` | `muse_backend=info,tower_http=warn` | 日志级别 |

### 错误响应

所有非 2xx 响应体为统一的错误对象：

```json
{ "code": "not_found", "message": "song not found: song_999" }
```

| `code` | HTTP | 触发条件 |
| --- | --- | --- |
| `not_found` | 404 | 单曲 / 封面 id 不存在 |
| `bad_request` | 400 | 参数非法 |
| `cover_render_failed` | 500 | 封面编码失败（不应发生） |

WebSocket 上的错误同样用这两个字段，但包在 `{"type":"error", ...}` 里。

## REST 端点

### 0. 健康检查

```http
GET /health
```

**响应（200）**

```json
{ "status": "ok", "engine": "rodio" }
```

`engine` 为 `rodio`（真实音频输出）或 `clock`（无声卡的虚拟时钟）。它单独返回，
是因为"接口正常但没有声音"是最难从外部定位的故障。

### 1. 搜索歌曲

```http
GET /songs/search?q={keyword}
```

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `q` | string | 搜索关键字，匹配标题 / 艺术家 / 专辑。**可省略**，省略或为空返回整个曲库 |

**响应（200）**

```json
{
  "songs": [
    {
      "id": "song_001",
      "title": "Midnight Drive",
      "artist": "Google Material Orchestra",
      "album": "Synthetic Waves",
      "cover": "http://127.0.0.1:8080/covers/song_001.jpg",
      "duration_ms": 252000
    }
  ]
}
```

匹配为大小写不敏感的子串匹配。无匹配时返回 `{"songs": []}` 而不是 404。

### 2. 获取单曲详情

```http
GET /songs/{id}
```

**响应（200）**：与搜索结果单条结构一致；未找到返回 `404`。

### 3. 获取播放列表

```http
GET /playlist
```

**响应（200）**

```json
{
  "id": "playlist_default",
  "title": "默认列表",
  "songs": [ { "...": "同 Song 结构" } ]
}
```

### 4. 获取封面

```http
GET /covers/{id}.jpg
```

**响应（200）**：`image/jpeg`，512×512，附带 `Cache-Control: public, max-age=31536000, immutable`。
未找到返回 `404`。

封面是**程序化生成**的，不是位图资源：颜色与装饰圆盘由歌曲 id 的 FNV-1a 哈希决定
（与 Flutter 侧 `stableArtworkHash` 同一算法），因此同一首歌每次请求得到完全相同的
字节，可以放心长缓存。这样未打标签的文件也有封面，不必依赖内嵌封面图。

`.jpg` 后缀可省略，便于客户端直接拿 `id` 拼 URL。

## WebSocket：播放状态同步

```text
ws://127.0.0.1:8080/ws/player
```

连接建立后服务端**立即推送一次当前 `state`**，之后每次状态变化都会推送。进度由后台
每 250ms **采样真实播放引擎**后推送——位置来自音频设备/解码器，不是状态机自己累加的
计时器，因此不会漂移。

播放由 `rodio` 驱动真实输出。曲目结束后由解码器给出结束信号，队列自动前进
（`repeat=one` 重播、`all` 环绕、`off` 到队尾停在 `idle`）。

内置 seed 目录**没有音频文件**：这类曲目会播放等长的静音占位，时间轴依然真实，
只是听不见声音。扫描到的本地文件则正常解码播放。

没有可用声卡时（CI、无音频的服务器）服务会退化为**虚拟时钟**：API、协议与时序
语义完全不变，只是没有声音，`/health` 的 `engine` 会显示 `clock`。

### 客户端 → 服务端（指令）

带 `type` 标签的对象。文档化指令：

```json
{ "type": "play",     "song_id": "song_002" }
{ "type": "pause" }
{ "type": "next" }
{ "type": "seek",     "position_ms": 42000 }
```

完整指令集（额外指令为附加项，见下）：

| `type` | 字段 | 说明 |
| --- | --- | --- |
| `play` | `song_id` | 播放指定歌曲。已在队列中则移动游标，否则队列被替换为该曲目 |
| `play_queue` | `song_ids`, `start_index` | 整体替换队列并从 `start_index` 开始播放 |
| `pause` / `resume` / `toggle` | — | 暂停 / 继续 / 切换 |
| `next` / `previous` | — | 上下一首，遵循 repeat 模式 |
| `seek` | `position_ms` | 跳转，自动 clamp 到 `[0, duration_ms]` |
| `set_volume` | `volume` | 0.0 ~ 1.0，自动 clamp |
| `set_shuffle` | `enabled` | 随机播放 |
| `set_repeat` | `mode` | `off` / `all` / `one` |
| `clear_queue` | — | 清空队列并回到 `idle` |
| `request_state` | — | 请求一次当前状态快照 |

`volume` / `shuffle` / `repeat` / `previous` / `toggle` / `play_queue` / `clear_queue` /
`request_state` 是**附加指令**：Flutter 播放器本身有这些能力，只做文档里的四个会让
WebSocket 只能驱动 UI 的一个子集。旧客户端忽略未知字段即可。

### 服务端 → 客户端（状态推送）

```json
{
  "type": "state",
  "song_id": "song_002",
  "status": "playing",
  "position_ms": 42100,
  "duration_ms": 308000,
  "queue": ["song_002", "song_003"]
}
```

`queue` 是**歌曲 id 数组**（不是完整对象）：推送频率高，只发 id 能显著压小 payload。
客户端需要详情时用 `/songs/{id}` 补齐。

完整字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `type` | `"state"` | 消息标签 |
| `song_id` | `string \| null` | 当前歌曲 id，空队列时为 `null` |
| `status` | `string` | `idle` / `loading` / `playing` / `paused` / `buffering` / `error` |
| `position_ms` | `int` | 当前进度，毫秒 |
| `duration_ms` | `int` | 当前歌曲总时长，毫秒 |
| `queue` | `string[]` | 播放顺序的歌曲 id |
| `volume` | `number` | 0.0 ~ 1.0 |
| `is_shuffle` | `bool` | 随机播放 |
| `repeat_mode` | `string` | `off` / `all` / `one` |
| `updated_at_ms` | `int` | 服务端产生该状态的 Unix 毫秒时间戳 |

`volume` / `is_shuffle` / `repeat_mode` / `updated_at_ms` 为**附加字段**，让客户端一次
推送即可恢复完整播放器状态，无需二次请求。

### 错误推送

```json
{ "type": "error", "code": "command_rejected", "message": "unknown song id: ghost" }
```

| `code` | 触发条件 |
| --- | --- |
| `invalid_command` | JSON 解析失败或 `type` 未知 |
| `command_rejected` | 指令合法但被拒绝（如未知 `song_id`） |

**被拒绝的指令不会改变任何状态**，也不会产生 `state` 推送。连接在收到坏帧后保持打开。

### 连接生命周期

每个连接由两个独立任务驱动：一个读取指令，一个推送状态。任一方向结束即整条连接关闭，
因此客户端断开不会泄漏任务。慢客户端若落后超过 64 条消息，服务端会记录警告并**重推
最新快照**（位置是绝对值，重推即可恢复一致）。

## 客户端映射

| 后端字段 | 客户端模型 | 说明 |
| --- | --- | --- |
| `duration_ms` | `Song.duration`（`Duration`） | 需换算 |
| `cover`（URL） | `Song.cover` | 当前为 `mock://` 占位，接入后渲染 `Image.network` |
| `status` | `PlayerStatus` | 映射到枚举 |
| `position_ms` | `PlayerState.position` | 需换算 |
| `queue`（id 数组） | `PlayerState.queue` | 需按 id 从曲库解析回 `Song` |
| `volume` / `is_shuffle` / `repeat_mode` | `PlayerState` 同名字段 | 附加字段，可直接 `copyWith` |

队列里的 id 由 `PlayerSyncService` 解析回 `Song`：连接时先用 `/playlist` 建好
id→Song 目录，之后再按需 `GET /songs/{id}` 补缺失项；确实取不到的会保留为占位行而不是
从队列里删掉，否则索引会错位。

## 客户端接入点

已实现（Flutter 侧）：

| 文件 | 职责 |
| --- | --- |
| `core/network/api_client.dart` | `RustApiClient`：REST（search / song / playlist / health）+ WS 连接；`http.Client` 与 socket 工厂都可注入 |
| `core/network/player_socket.dart` | `PlayerSocket`：把 `web_socket_channel` 收窄成最小接口，便于用假 socket 测协议 |
| `core/network/player_sync.dart` | `PlayerSyncService`：WS 生命周期、指令序列化、id→Song 解析、错误上报 |
| `core/network/network_providers.dart` | `rustApiClientProvider`：按 `BackendConfig` 构建并持有客户端 |
| `providers/player_provider.dart` | `PlayerNotifier`：`enableNetwork` 时把指令转发给后端并镜像推送；否则保留本地 Mock 播放 |
| `pages/search/search_page.dart` | `enableNetwork` 时向后端搜索（250ms 防抖），否则本地过滤 Mock |

行为约定：

- `enableNetwork: true`（默认）时连接后端；**后端不可达不会报错**，而是静默回退到本地
  Mock 播放，只写一条 debug 日志。
- 远程模式下 UI 状态完全由 `state` 推送驱动，不做乐观更新 —— 后端是唯一事实来源。
- 队列编辑（`playNext` / `addToQueue`）在当前协议里没有对应指令，远程模式下是空操作，
  避免只改本地、随即被推送覆盖造成状态不一致。
- 封面：`RustApiClient.coverUri()` 只接受 `http(s)`，`mock://` 返回 `null`，由
  `CoverArtwork` 继续画生成图。
