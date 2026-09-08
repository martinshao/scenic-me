# 变更索引与交付约定

当前变更：

- [000-bootstrap 初始化意图](000-bootstrap/intent.md)、[规格](000-bootstrap/spec.md)、[计划](000-bootstrap/plan.md)：技术初始化，不是产品需求已确认的证据。
- [001-ai-travel-photo 产品意图](001-ai-travel-photo/intent.md)、[交互](001-ai-travel-photo/interaction.md)、[视觉设计](001-ai-travel-photo/design.md)、[实施计划](001-ai-travel-photo/plan.md)与[验证](../verification/001-ai-travel-photo/README.md)：首页、统一创作流程和附近地图已有本地 Flutter 演示实现；真实服务与完整 MVP 范围仍待确定。

新增业务变更时创建稳定 ID 的子目录，按需要生成下列文件，不要求每轮复制全部模板：

| 环节 | 记录 | 必需信息 | 负责角色 |
| --- | --- | --- | --- |
| Plan | intent.md | 场景、证据、结果、边界与未知 | 产品 |
| Design | spec.md、interaction.md、design.md 或关联原型 | 规则、验收、流程／状态、可开发设计 | 产品、交互、UI |
| Build | plan.md 与代码链接 | 范围、依赖、数据、风险和验证 | 工程 |
| Test | verification.md 与日志 | 版本、环境、步骤、期望、实际、限制 | 工程、质量 |
| Deploy | docs/releases 下的记录 | 变更 ID、制品、环境、授权、结果、恢复 | 发布 |
| Maintain | docs/incidents 下的记录 | 影响、证据、诊断、处置、后续变更 | 服务负责人 |

所有记录标记状态、输入版本、负责人、证据与未决项。负责人未知时写待指定，不捏造签字或批准。已有外部工作项时选定权威记录并关联 ID。没有 Git 时使用修订号，不编造提交 SHA。
