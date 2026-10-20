# 青橘

基于 [FluxDO](https://github.com/Lingyan000/fluxdo) 二次开发的 **qingju.me 专用第三方论坛客户端**，使用 Flutter，沿用 Material 3 布局与原有论坛交互。与青橘社区官方无直接关联。

## 适配范围

- 默认站点为 `https://qingju.me`，独立应用标识 `me.qingju.client`。
- 应用名、图标、默认青绿色主题、通知与分享文案独立于 FluxDO。
- 登录使用青橘自身完整网页登录流程，不复用 Linux.do 的 hCaptcha 配置。
- 保留话题浏览、分类标签、搜索、发帖回复、上传、点赞书签、通知与个人资料功能。
- 隐藏原站 LDC/CDK、Connect 等级及打赏入口，不加载原站专属插件。
- HTTPS 主站以外的请求不携带青橘会话与 CSRF；旧站专属请求由网络边界拒绝。

## 构建与验收

当前为开发验收构建，不发布应用商店、GitHub Release 或上游更新渠道。

- [青橘适配、构建与验收说明](docs/qingju.md)
- [领域术语](CONTEXT.md)
- [原有开发工具说明](docs/development.md)
- 工作流：`.github/workflows/qingju-build.yml`
- 分支：`qingju`；上游远端：`upstream`。

固定使用 `.fvmrc` 中的 Flutter 3.44.8，先递归初始化子模块：

```sh
git submodule update --init --recursive
dart tool/project_prep.dart app
dart tool/flutterw.dart run -d windows
```

Android 需要 Android SDK/JDK 17，原生代理需要 Rust、CMake（Windows 还需 NASM）。Apple 构建在 macOS 上进行；Linux CI 使用 Arch/WPE 依赖链。不要跳过项目预处理，它负责本地化代码与证书资源。

针对性测试：

```sh
dart tool/flutterw.dart test test/services/qingju_site_boundary_test.dart
```

## 许可证与上游归属

本项目保留 FluxDO 的 Git 历史、原作者归属及 GPL-3.0 许可证，详见 [LICENSE](LICENSE)。感谢 Lingyan000 与 FluxDO 贡献者。本仓库的青橘适配修改同样按 GPL-3.0 提供；未改动的第三方组件遵循各自许可证。
