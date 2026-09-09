# 路线图

## Phase 1 — 项目架构与 Mock UI（当前）

- [x] Flutter 工程与分层目录
- [x] Material 3 明暗主题
- [x] 响应式外壳（NavigationRail / NavigationBar + MiniPlayer）
- [x] Riverpod 播放状态与模拟队列
- [x] 首页 / 搜索 / 音乐库 / 正在播放 / 占位页
- [x] 渐变占位封面
- [x] 后端地址与 API 客户端接缝预留

## Phase 2 — 真实音频播放

- [ ] 接入 `just_audio`（或 `audio_service`）
- [ ] 真实进度、缓冲、错误状态映射到 `PlayerState`
- [ ] 播放队列持久化
- [ ] 歌词占位替换为真实歌词滚动
- [ ] 音量 / 系统媒体控制（`audio_service`）

## Phase 3 — Rust 后端对接

- [ ] 实现 REST 端点（`/songs/search`、`/songs/{id}`、`/playlist`）
- [ ] 实现 WebSocket `/ws/player` 状态同步
- [ ] `RustApiClient` 落地 HTTP / WS 客户端
- [ ] Mock 数据切换为后端数据
- [ ] 真实封面加载（`Image.network` + 缓存）

## Phase 4 — 完整功能

- [ ] 收藏 / 播放列表管理
- [ ] 设置（音频输出、外观、同步）
- [ ] 专辑详情页
- [ ] 深链与路由完善
- [ ] 打包发布（Android / iOS / Linux / macOS / Windows / Web）

## 技术备注

- 模型层已为后端字段预留映射（`Song.cover`、`duration` 等）。
- `PlayerState` 与音频引擎解耦，Phase 2 无需改 UI。
- 接口契约见 [backend-api.md](backend-api.md)。
