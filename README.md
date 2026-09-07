# scenic_me

Flutter 初始化工程。业务功能、产品验证与发布尚未完成。

## 开始

检查 `initialization.json` 和 [初始化日志](docs/verification/bootstrap/README.md) 确认实际执行结果。
准备所选平台工具链后执行 `flutter run`，先用 `flutter devices` 查看可用目标。
常规检查：`flutter pub get`、`dart format lib test`、`flutter analyze`、`flutter test`。
签名、平台构建和商店上架按实际目标另行验证，不包含在初始化通过结论中。

## 工作入口

- [AI 工作约定](AGENTS.md)
- [项目架构](docs/architecture.md)
- [变更与六阶段交付](docs/changes/README.md)
- [架构决定](docs/decisions/README.md)
- [发布记录](docs/releases/README.md)
- [事件与反馈](docs/incidents/README.md)
- [技能学习](docs/learning/README.md)
- [Agent 评估](evals/README.md)

脚本不会创建 Git 仓库或提交。使用版本管理时保留应用的 pubspec.lock；不要提交秘密或含敏感数据的日志。Flutter 生成的 .gitignore 原样保留。
