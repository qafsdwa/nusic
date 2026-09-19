# Muse Player 文档

Muse Player 是一个基于 Flutter 的跨平台 Material Design 3 音乐播放器客户端。
Rust 后端（`rust/backend/`，REST + WebSocket，`rodio` 真实播放）与 Flutter 客户端
（`lib/core/network/`）均已实现：开启 `enableNetwork` 后客户端搜索后端并镜像其播放
状态，后端不可达时回退到 Mock 播放。音频由后端输出，Flutter 自身不播放。

## 文档目录

| 文档 | 说明 |
| --- | --- |
| [architecture.md](architecture.md) | 架构总览、分层设计、启动流程、数据流、响应式与主题系统 |
| [configuration.md](configuration.md) | `app_config.json` 配置字段、初始化流程、容错与扩展方式 |
| [modules.md](modules.md) | 各目录 / 文件模块的职责说明 |
| [backend-api.md](backend-api.md) | Rust 后端 REST + WebSocket 接口契约与实现说明 |
| [rust-bridge.md](rust-bridge.md) | flutter_rust_bridge 数据契约、Dart ↔ Rust 映射与事件流设计 |
| [roadmap.md](roadmap.md) | 分阶段规划（Phase 1 → 后续） |

## 快速开始

```bash
flutter pub get
flutter run
```

## 项目检查

```bash
dart format .
flutter analyze
flutter test
```

## 生成 API 文档

代码已随源码附带 `dartdoc` 注释，可生成静态 API 文档：

```bash
dart doc          # 输出到 doc/api/
```

项目根目录的 `dartdoc_options.yaml` 定义了输出目录与站点名称。
