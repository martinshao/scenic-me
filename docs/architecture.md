# 应用与交付架构

状态：draft。Flutter 为当前框架；以下组织方式是本项目起点，不是官方强制目录。

## 运行代码

lib/main.dart 负责启动，lib/app 负责应用装配和适用的主题／路由。
lib/features/<feature>/presentation 放功能视图及需要时的 ViewModel；data 在实际接入数据时加入 models、repositories、services。共用数据能力有真实复用时提取到 lib/data；真正跨功能的 UI 组件可放 lib/ui/core。

依赖方向：视图 → ViewModel → repository → service。当前切片由 `home` 和 `create` 两个功能组成，创作状态只在页面生命周期内存在，因此暂不创建无用 ViewModel、repository 或 domain 空类。地图相关的系统定位、地点搜索和最近城市存储已经收敛到 `create/data/nearby_services.dart`，视图只依赖接口并可注入测试实现。复杂共享业务出现后才加入 domain/use-cases；具体状态管理、路由、数据库与后端仍未选库。

附近地图位于 `create/presentation/nearby_map_screen.dart`，使用 `flutter_map` 加载 OpenStreetMap 标准瓦片，并以真实经纬度展示场景与搜索结果。`SystemNearbyLocationService` 仅请求前台权限，通过平台地理编码获得城市；`NominatimPlaceSearchService` 只在用户提交后搜索、限制为每秒最多一次并缓存会话内重复查询；`DeviceRecentCitiesStore` 只保存最近六个城市名。公共 OSM 瓦片与 Nominatim 没有 SLA，生产扩量前必须切换到可承诺容量的供应商、自托管服务或服务端代理；搜索地址可通过 `SCENIC_ME_GEOCODING_URL` 编译变量替换，无需修改客户端代码。

test 按功能镜像组织单元与组件测试；地点搜索请求、缓存和页面状态使用可注入服务验证。系统权限弹窗、GPS、平台反向地理编码和外部地图服务仍需要 iOS／Android 真机集成测试，当前组件测试不等同于真实端到端验证。
平台目录由 Flutter CLI 按参数生成，不手写。默认不加入签名配置、CI 厂商文件或自动部署。

## 两种结构互相连接

运行代码按业务职责拆分；docs/changes/<ID> 通过 intent → spec 与设计 → plan → verification 连接需求和实现。发布记录关联实际版本、检查和变更 ID；事件记录回到新的变更。阶段可能并行和反复，文件数量不等于成熟度。

参考：Flutter 官方架构指南 https://docs.flutter.dev/app-architecture/guide ，查阅 2026-09-05。UI／数据分离和可选 domain 来自指南；具体 feature-first 文件夹和 SDLC 组织是本项目建议。
