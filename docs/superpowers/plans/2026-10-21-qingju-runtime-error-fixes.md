# 青橘书签卸载与会话引导错误修复计划

> **For agentic workers:** 本计划已获批准，当前会话直接执行。步骤用 checkbox 跟踪。

**Goal:** 消除书签页卸载时使用失效 `WidgetRef` 的异常，并停止为不支持 Linux.do 指纹插件的青橘站点反复启动 WebView bootstrap。

**Architecture:** `BookmarksPage` 仅在桌面端、组件仍挂载时创建 `ShortcutScopeBinding`，卸载时空安全释放。`WebViewSessionCookieRefreshService` 以既有 `SiteIdentity.supportsLinuxDoServices` 为能力门；青橘返回明确的 `unsupported_site` 结果，不创建 headless WebView、不增加失败退避，并把失败阶段写入同步完成日志。登录流程仍同步 `_t` / `_forum_session` 等核心 Cookie；BrowserTrust 不把不适用的 `_rt` 当作请求失败。

**Tech Stack:** Flutter / Dart、Riverpod、`flutter_test`、`flutter_inappwebview`。

## Global Constraints

- 不新增依赖，不修改站点服务器、Cookie 名称或核心 `_t` 认证。
- qingju 的 `SiteIdentity.supportsLinuxDoServices` 保持 `false`。
- 不改版本号、不创建 tag、不发布 Release；本任务只修工作区源码并验证。
- 保留未跟踪 `.workflow/`，不提交日志、Cookie 值或浏览器资料。

---

### Task 1: 修复 BookmarksPage dispose 中的失效 ref

**Files:**
- Modify: `lib/pages/bookmarks_page.dart`
- Modify: `test/pages/bookmarks/bookmarks_page_test.dart`

**接口与行为:**
- `_shortcutScopeBinding` 改为 nullable 字段。
- 仅当 `PlatformUtils.isDesktop` 时，在 `initState` 中构造 binding；`dispose` 使用 null-aware cleanup。
- 移动端卸载不触碰 `WidgetRef`，桌面端快捷键注册与 deferred unregister 保持现状。

- [x] 添加移动端测试：将 `PlatformUtils.debugDesktopOverride` 设为 `false`，pump `BookmarksPage` 后卸载，断言 `tester.takeException()` 为 `null`。
- [x] 回归验证：新卸载用例独立通过；旧实现曾复现 ref/unmounted 异常。整文件中原有工作区用例另有失败，见 Task 3。
- [x] 实现 nullable/eager desktop-only binding 生命周期。

### Task 2: 将 Linux.do 指纹 bootstrap 作为站点可选能力

**Files:**
- Modify: `lib/services/webview_session_cookie_refresh_service.dart`
- Modify: `lib/services/browser_trust_coordinator.dart`
- Modify: `lib/pages/webview_login_page.dart`
- Modify: `lib/widgets/auth/webview_login_dialog.dart`
- Create: `test/services/webview_session_cookie_refresh_service_test.dart`

**接口与行为:**
- `SessionBootstrapResult` 增加 `unsupported_site` 结果判定。
- `ensureSynced` 与 `runOnController` 在 `SiteIdentity.supportsLinuxDoServices == false` 时记录一次 info skip 并立即返回，不初始化 CookieJar、不启动 WebView、不增加 `failureStreak`。
- WebView 登录页仍执行同源 Cookie 边界同步，但跳过 fingerprint wait/bootstrap；`_rt` 对该站点标记为不适用，不触发强制后台重试。
- 登录对话框跳过 fingerprint bootstrap，但保留原有认证 Cookie 同步与登录收口。
- BrowserTrust 把 `unsupported_site` 视为 session-bootstrap 不适用；CF/request-gate 判定不变。
- `webview_session_sync_completed` 日志加入 `phase`，后续失败可区分 `discover`、`timeout`、`controller_error` 等阶段。

- [x] 添加服务测试：qingju 的 `ensureSynced` 返回 `unsupported_site`，且不启动平台 WebView 路径。
- [x] 实现站点能力门、登录调用方跳过逻辑与可诊断 phase。

### Task 3: 验收

- [ ] 运行 `flutter test --no-pub --no-test-assets test/pages/bookmarks/bookmarks_page_test.dart test/services/webview_session_cookie_refresh_service_test.dart`。
  - 结果：新卸载用例和 session service 测试分别通过；整文件运行被原有工作区用例阻断，该用例在 `test/pages/bookmarks/bookmarks_page_test.dart:220` 找不到 `Alpha`。
- [x] 运行 `dart analyze` 定点分析五个生产文件与两个测试文件。
- [x] 运行 `dart format --output=none --set-exit-if-changed` 检查改动文件。
- [x] 运行 `git diff --check` 并确认 `.workflow/` 未进入改动范围。
