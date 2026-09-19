# muse_backend

Muse Player 的 Rust 后端：REST + WebSocket 控制接口。

接口契约与字段说明见 [`docs/backend-api.md`](../../docs/backend-api.md)。

## 运行

```bash
cargo run                              # http://127.0.0.1:8080（seed 目录，静音占位）
MUSE_MUSIC_DIR=~/Music cargo run       # 扫描真实音乐目录并用 rodio 播放
MUSE_AUDIO=silent cargo run            # 不碰声卡：虚拟时钟，接口照常
```

Linux 上 `rodio` 依赖 ALSA 头文件：`sudo apt-get install -y libasound2-dev`（Fedora 为
`alsa-lib-devel`）。

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `MUSE_BACKEND_PORT` | `8080` | 监听端口 |
| `MUSE_BACKEND_HOST` | `127.0.0.1` | 监听地址（默认只绑回环） |
| `MUSE_MUSIC_DIR` | 未设置 | 音乐目录；未设置或扫不到文件时用内置 seed 目录 |
| `MUSE_PUBLIC_BASE_URL` | `http://127.0.0.1:{port}` | 封面绝对 URL 的基地址 |
| `MUSE_AUDIO` | `auto` | 播放后端：`auto` / `rodio` / `silent` |
| `RUST_LOG` | `muse_backend=info,tower_http=warn` | 日志级别 |

## 端点

```text
GET  /health                # { "status": "ok", "engine": "rodio" \| "clock" }
GET  /songs/search?q=       # 搜索标题 / 艺术家 / 专辑；q 可省略
GET  /songs/{id}            # 单曲详情，404 表示不存在
GET  /playlist              # 默认播放列表
GET  /covers/{id}.jpg       # 程序化生成的 512×512 JPEG，可长缓存
WS   /ws/player             # 播放状态同步
```

## 代码结构

```text
src/
├── main.rs              二进制入口：tracing + 环境变量 + 启动
├── lib.rs               build_router / serve：装配、绑定、优雅关闭
├── config.rs            Config：环境变量解析
├── models.rs            线上类型：Song / PlayerState / PlayerCommand / ServerMessage
├── error.rs             ErrorBody / ApiError：统一错误体
├── library.rs           Library：目录扫描 + seed 目录 + 查询 + 文件路径解析
├── player.rs            PlayerHub：控制状态机 + 广播（每 250ms 采样引擎）
├── cover.rs             CoverCache：程序化封面生成
├── audio/
│   ├── mod.rs           AudioEngine trait：播放后端抽象
│   ├── rodio.rs         RodioEngine：真实输出
│   └── clock.rs         ClockEngine：无声卡回退 / 测试用虚拟时钟
└── routes/
    ├── mod.rs           AppState + 路由表
    ├── health.rs        GET /health
    ├── songs.rs         GET /songs/* · /playlist · /covers/*
    └── player_ws.rs     GET /ws/player
```

## 设计要点

- **契约不漂移**：曲目领域类型直接用 `muse_bridge::api::bridge_models::BridgeTrack`
  （与 Flutter 走 FRB 的是同一个类型），HTTP JSON 由它投影而来。
- **控制与声音分离**：`PlayerHub` 只管队列 / 循环 / 随机 / 协议，实际出声交给
  `AudioEngine` trait。这条缝让协议能在没有声卡的机器上开发与测试，也让播放后端
  可以整体替换。无声卡时自动退化为 `ClockEngine`（虚拟时钟），API 语义不变。
- **位置来自引擎**：推送的 `position_ms` 取自 `rodio` 的播放位置（或虚拟时钟），
  后台 250ms 只是**采样**而不是累加计时器，所以不会漂移。
- **加载是原子的**：`AudioEngine::load` 先把源准备好再替换；文件缺失/解码失败时
  当前曲目继续播放，`PlayerHub` 据此拒绝命令且不改任何状态。
- **seed 目录静音占位**：内置目录没有音频文件，这类曲目播放等长静音，时间轴真实
  但无声；真实文件正常解码。
- **可缓存封面**：封面由歌曲 id 的 FNV-1a 哈希确定性生成，同一 id 永远得到同一
  字节，因此可以 `immutable` 长缓存；未打标签的文件也有封面。
- **失败回退**：目录不存在或扫不到任何可解析文件时回退到 seed 目录，避免客户端
  拿到空库。

## 测试

```bash
cargo test                              # 单元 + 集成
cargo clippy --all-targets
cargo fmt --all
```

集成测试（`tests/`）在真实回环 socket 上驱动服务，覆盖 REST 形状 / 状态码 /
封面缓存头、WebSocket 指令与推送、目录扫描（用 `hound` 生成 WAV 夹具），以及
`tests/audio_engine.rs` 对**真实声卡**的验证（进度、seek、曲终、加载失败不影响
当前曲目、静音占位可 seek）。没有声卡的机器会自动跳过该文件里的用例而不是失败。
