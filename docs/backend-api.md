# 后端 API 契约（Rust）

> **状态：草案 / 预留。** Phase 1 不实现任何网络调用，本文档定义未来 Rust 后端的
> 接口契约，作为客户端 `core/network` 的对接基准。字段命名与响应结构为提案，
> 最终以 Rust 实现为准。

## 基本信息

- Base URL：由 `assets/config/app_config.json` 的 `backend.baseUrl` 提供，默认 `http://127.0.0.1:8080`
- 认证：待定（本地部署，Phase 2 可能为无鉴权或简单 token）
- 编码：JSON，UTF-8

对应客户端配置见 `assets/config/app_config.json` 的 `backend` 段；运行时通过 `appConfigProvider` 读取 `BackendConfig`。

## REST 端点

### 1. 搜索歌曲

```http
GET /songs/search?q={keyword}
```

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `q` | string | 搜索关键字，匹配标题 / 艺术家 / 专辑 |

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

## WebSocket：播放状态同步

```text
ws://127.0.0.1:8080/ws/player
```

用于客户端与服务端之间的播放状态同步（进度、切歌、队列变更）。

**客户端 → 服务端（指令）**

```json
{ "type": "play",     "song_id": "song_002" }
{ "type": "pause" }
{ "type": "next" }
{ "type": "seek",     "position_ms": 42000 }
```

**服务端 → 客户端（状态推送）**

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

## 客户端映射

| 后端字段 | 客户端模型 | 说明 |
| --- | --- | --- |
| `duration_ms` | `Song.duration`（`Duration`） | 需换算 |
| `cover`（URL） | `Song.cover` | 当前为 `mock://` 占位，接入后渲染 `Image.network` |
| `status` | `PlayerStatus` | 映射到枚举 |
| `position_ms` | `PlayerState.position` | 需换算 |

## 客户端接入点

- `BackendConfig`：从 `app_config.json` 读取 base URL 与端点路径。
- `RustApiClient`：注入 REST（`dio` / `http`）与 WebSocket（`web_socket_channel`）客户端。
- `PlayerNotifier`：接收 WS `state` 推送，`copyWith` 覆盖 `PlayerState`。
- `CoverArtwork`：`cover` 为真实 URL 时渲染网络图，保留渐变占位作为 fallback。
