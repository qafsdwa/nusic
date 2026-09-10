# Muse Player 文档

Muse Player 是一个基于 Flutter 的跨平台 Material Design 3 音乐播放器客户端。
当前处于 **Phase 1：Mock UI** 阶段，尚未接入真实音频播放与后端服务。

## 文档目录

| 文档 | 说明 |
| --- | --- |
| [architecture.md](architecture.md) | 架构总览、分层设计、启动流程、数据流、响应式与主题系统 |
| [configuration.md](configuration.md) | `app_config.json` 配置字段、初始化流程、容错与扩展方式 |
| [modules.md](modules.md) | 各目录 / 文件模块的职责说明 |
| [backend-api.md](backend-api.md) | 未来 Rust 后端 REST + WebSocket 接口契约 |
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
