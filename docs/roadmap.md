# 路线图

## Phase 1 — 项目架构与 Mock UI（当前）

- [x] Flutter 工程与分层目录
- [x] Material 3 明暗主题
- [x] 响应式外壳（Desktop Panel / NavigationRail / NavigationBar）
- [x] Floating Liquid Glass Player Bar
- [x] Riverpod 播放状态与模拟队列
- [x] 首页 / 搜索 / 音乐库 / 播放列表 / 正在播放
- [x] 渐变占位封面
- [x] JSON 配置系统与启动初始化
- [x] 后端地址与 API 客户端接缝预留

## Phase 2 — 真实音频播放

- [ ] 接入 `just_audio`（或 `audio_service`）
- [ ] 真实进度、缓冲、错误状态映射到 `PlayerState`
- [ ] 播放队列持久化
- [ ] 歌词占位替换为真实歌词滚动
- [ ] 音量 / 系统媒体控制（`audio_service`）

## Phase 3 — Rust 后端对接

后端侧（`rust/backend/`）：

- [x] 实现 REST 端点（`/songs/search`、`/songs/{id}`、`/playlist`、`/covers/{id}.jpg`、`/health`）
- [x] 实现 WebSocket `/ws/player` 状态同步（指令 + 状态推送 + 错误回传）
- [x] 目录扫描（`walkdir` + `lofty`）与内置 seed 目录回退
- [x] 程序化生成封面（512×512 JPEG，可长缓存）
- [x] 接入真实音频引擎（`rodio` 解码 + 输出，位置来自音频时钟）
- [x] 音频引擎抽象（`AudioEngine` trait：rodio / 无声卡虚拟时钟）
- [x] B 站在线层（`bpi-rs`）：视频搜索 → DASH 音轨解析 → 缓存为本地文件后播放
- [x] 在线曲目叠加层：只按 id 解析，不进入本地目录 / 歌单 / 本地搜索

客户端侧（Flutter）：

- [x] flutter_rust_bridge 接入：App 通过 FFI **同进程**调用 Rust，不再走 HTTP/WS
- [x] `PlayerNotifier` 引擎模式：指令转发 + `subscribe()` 状态镜像（库加载失败则回退 Mock）
- [x] 搜索页接入 Rust 引擎（防抖 + 错误态）
- [x] 搜索页在线 / 本地切换；在线曲目播放前先下载缓存（进度条 + 失败提示）
- [ ] 音乐库 / 歌单页切换到 Rust 数据（当前仍读 `MockMusic`）
- [ ] 队列增删改的 FFI 指令（`playNext` / `addToQueue` 引擎模式下暂为空操作）
- [ ] 封面：本地文件内嵌图通过 FFI 传给 Flutter（当前仍是生成图）
- [ ] Rust 侧 HTTP/WS 前端与 App 解耦（目前仍在同一 crate，App 链接时会被带入）
- [ ] 在线结果分页 / 滚动加载，以及准备阶段的进度反馈

## Phase 4 — 完整功能

- [ ] 收藏 / 播放列表管理
- [ ] 设置（音频输出、外观、同步）
- [ ] 专辑详情页
- [ ] 深链与路由完善
- [ ] 打包发布（Android / iOS / Linux / macOS / Windows / Web）

## 技术备注

- 模型层已为后端字段预留映射（`Song.cover`、`duration` 等）。
- `PlayerState` 与音频引擎解耦，Phase 2 无需改 UI。
- 配置系统见 [configuration.md](configuration.md)。
