# 应用与交付架构

状态：draft。Flutter 为当前框架；以下组织方式是本项目起点，不是官方强制目录。

## 运行代码

lib/main.dart 负责启动，lib/app 负责应用装配和适用的主题／路由。
lib/features/<feature>/presentation 放功能视图及需要时的 ViewModel；data 在实际接入数据时加入 models、repositories、services。共用数据能力有真实复用时提取到 lib/data；真正跨功能的 UI 组件可放 lib/ui/core。

依赖方向：视图 → ViewModel → repository → service。当前只有无业务逻辑的 start 页面，故不创建无用 ViewModel、repository 或 domain 空类。复杂共享业务出现后才加入 domain/use-cases。具体状态管理、路由、DI、数据库与后端暂不选库。

test 按功能镜像组织单元与组件测试；真实端到端需求出现后再加 integration_test 和所需 SDK 依赖，当前不声称具备集成测试。
平台目录由 Flutter CLI 按参数生成，不手写。默认不加入签名配置、CI 厂商文件或自动部署。

## 两种结构互相连接

运行代码按业务职责拆分；docs/changes/<ID> 通过 intent → spec 与设计 → plan → verification 连接需求和实现。发布记录关联实际版本、检查和变更 ID；事件记录回到新的变更。阶段可能并行和反复，文件数量不等于成熟度。

参考：Flutter 官方架构指南 https://docs.flutter.dev/app-architecture/guide ，查阅 2026-09-05。UI／数据分离和可选 domain 来自指南；具体 feature-first 文件夹和 SDLC 组织是本项目建议。
