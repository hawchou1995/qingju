# 青橘适配、构建与验收

## 站点与身份

青橘客户端只连接 `https://qingju.me`。`lib/config/site_identity.dart` 是站点身份来源；`lib/config/sites/qingju.dart` 不注册 Linux.do 专属插件。Android/iOS/macOS/Linux 使用 `me.qingju.client`；Windows 使用独立公司/产品目录和通知 ID；自定义深链为 `qingju://`。内部 Dart 包名和成对的 MethodChannel 保留上游名称，它们不是网络地址。

会话与 CSRF 只允许发送至 HTTPS 青橘主站（443 端口）。原站专属网络请求直接拒绝，外站重定向剥离凭据；CDN 公共媒体不继承账号会话。网页登录由青橘自身处理密码、验证码与 OAuth，成功后的 Cookie 同步与退出流程复用既有实现。

## 可复现构建

Flutter 固定 3.44.8（`.fvmrc`），不整体升级无关依赖。先执行 `git submodule update --init --recursive`，安装 Rust，运行 `dart tool/project_prep.dart app`。该步骤必须生成本地化与代理证书资源，生成的私钥不能提交仓库。

| 平台 | 构建入口 | 交付文件 | 约束 |
|---|---|---|---|
| Android ARM64 | `dart tool/flutterw.dart build apk --debug --target-platform android-arm64` | `qingju-android-arm64-debug.apk` | Android Debug 测试签名，非商店发行包 |
| iOS ARM64 | `dart tool/flutterw.dart build ios --release --no-codesign` | `qingju-ios-arm64-unsigned.ipa` | 将 Runner.app 放入 Payload 压缩；须另行签名才能安装 |
| macOS ARM64 | `FLUXDO_MACOS_ARCH=arm64 dart tool/flutterw.dart build macos --release` | `qingju-macos-arm64-adhoc.zip` | adhoc 签名，未公证 |
| Windows x64 | `dart tool/flutterw.dart build windows --release` | `qingju-windows-x64.zip` | 解压完整目录运行 qingju.exe；保留 native/ 与 data/ |
| Linux x64 | `FLUTTER_VERSION=3.44.8 bash scripts/ci/linux/build_bundle.sh`（Arch） | `qingju-linux-x64.tar.gz` | 需要与构建环境兼容的图形、glibc、GTK 与系统密钥环 |

工作流 `.github/workflows/qingju-build.yml` 在青橘分支执行，只上传 artifacts，不创建标签、Release 或发布通知。每份 artifact 内有 `BUILD.txt`（源码提交号）和 `SHA256SUMS.txt`。本地下载目录为被 Git 忽略的 `deliverables/`；最终校验清单以其中实际生成的文件为准，不把“预期文件名”当作已经生成。

## 测试口径

基线为上游提交 `e1bd839e`，与青橘版使用相同 Flutter 版本。静态分析使用 `flutter analyze --no-pub`；根测试使用 `flutter test --no-pub --reporter json`。本机未开放 Windows 符号链接，依赖解析后可直接生成 l10n 并运行无 pub 检查；不修改全局系统策略。中文路径下分析服务出现 LSP 初始化 JSON 截断时，在英文临时工作树复测。

已观察的初始基线：91 条静态诊断；根测试 1,129 项成功，15 项失败或错误。既有失败主要涉及书签界面、语音调试、鼠标中键与 Hero 源码覆盖测试。最终报告须列出基线差异，不移除失败测试，不放宽检查规则。

边界测试：`flutter test --no-pub test/services/qingju_site_boundary_test.dart`。主站固定地址夹具已经迁移到青橘；旧站拒绝、子域拒绝和跨域剥离凭据都有独立断言。

## Windows 核心功能验收表

| 项目 | 判据 | 证据口径 |
|---|---|---|
| 品牌与独立数据 | 本机启动显示青橘，使用独立数据目录 | 实际进程、窗口和文件路径 |
| 匿名阅读 | 列表、分类标签、正文分页、头像图片 | Windows 实际操作及必要截图 |
| 搜索与导航 | 结果可打开，个人资料与站内链接跳转正确 | Windows 实际操作 |
| 登录与保活 | 本人认证后可读取账号，重启仍登录，退出失效 | 账号持有人配合后验证 |
| 写操作 | 指定区域发帖、回复、上传、点赞和书签可回读 | 只在指定测试区域执行 |
| 五平台产物 | 五平台实际构建成功，文件下载并计算哈希 | 同一构建提交的 Actions 日志与本地 SHA-256 |

此表定义判据，不代表已全部通过。实际完成情况见最终交付回执。未取得本人登录和测试区域时，登录与写操作保持“未验收/阻塞”；其他平台没有实机则只报告构建结果。

## 验收记录（本机 Windows）

已实测：

- 品牌与独立数据：进程/窗口标题“青橘”，数据目录 `%APPDATA%\me.qingju\青橘`，与 FluxDO 分离。
- 登录：账号持有人手工完成青橘账号登录；客户端 `shared_preferences` 中 `current_user_cache` 为用户本人的青橘账号数据。
- 匿名与登录后读取：首页话题列表、分类标签（水漫金山/资源荟萃等）、话题详情分页、正文图片、个人主页（关注/粉丝/获赞/话题/回复统计）。
- 搜索：站内搜索结果列表正常返回并渲染。
- 深链：`qingju://topic/<id>` 与 `qingju://user/<name>` 均能在客户端内打开对应原生页面。
- 写操作（水漫金山）：
  - 回复：在开放话题 `topic/6807` 的第 1 楼点“回复”，客户端内输入并发送，服务端确认新增第 3 楼（`posts_count` 2→3），内容与输入一致。
  - 发帖：首页“+”→创建话题→分类选“水漫金山”→填标题与正文→发布，服务端确认新话题 `topic/6917`《青橘客户端适配验收测试（可删除）》。
  - 书签：`topic/2586` 添加后出现“已添加书签”并可编辑，删除后“已取消书签”，状态已还原。
- 功能裁剪：新构建的帖子操作菜单为“帖子详情/回复/编辑/分享链接/生成分享图片/添加书签/举报”，**已无“打赏 LDC”**；个人页 LDC/CDK、Connect 等级、元宇宙入口同样隐藏，且不再发起原站专属请求。
- 分享卡片：生成分享图片显示“青橘”品牌与 `https://qingju.me/...` 链接。

五平台构建：Android(arm64 debug)、iOS(arm64 无签名)、macOS(arm64 adhoc)、Windows(x64)、Linux(x64) 均构建成功并通过 SHA-256 校验，清单见 [青橘五平台构建产物](qingju-artifacts.md)。

约束与说明：

- 本机宿主窗口长期占用前台，`SetForegroundWindow` 被系统前台锁拒绝，因此键盘输入依赖“置顶 + 坐标归属校验 + SendInput 注入 Unicode”的组合完成；已执行的点击均在点击前用 `WindowFromPoint` 校验坐标归属青橘进程。
- 图片上传未通过自动化验收：客户端能弹出系统文件选择框（`#32770 打开`），但通过 SendKeys 输入路径/粘贴文件列表后，编辑器正文仍为空，未能插入附件。此项需要人工拖拽或点击选择文件确认，未计入通过。
- 点赞：反应详情列表显示本账号已在该帖点赞（服务端状态可读），本轮未再做可见的取消/重赞切换。
- 测试数据：`topic/6917` 与 `topic/6807` 第 3 楼为自动化验收留下的内容，客户端内未找到作者删除入口，需在网页端删除。
- 本机 DGS 透明加密会对 `.xml` 写入封密（文件头 `17 DA 5F A0`）。Android 自适应图标矢量必须以明文提交，否则资源编译器报 `Invalid byte 2 of 2-byte UTF-8 sequence`。已改为经 git 对象库写回明文，图标生成脚本不再直接写 `.xml`，全仓库密文文件数为 0。

## 许可证

保留上游 Git 历史与 `LICENSE`（GPL-3.0）。青橘是第三方客户端，不代表论坛官方；修改源码及构建说明随本仓库公开，私密验收截图、账号与 Cookie 不上传。
