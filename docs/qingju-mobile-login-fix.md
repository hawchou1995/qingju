# 移动端 Client Hints 请求头故障修复

## 结论与证据

本次提供的错误日志指向客户端构造 HTTP 请求头失败，而不是服务器返回认证错误：

- 异常为 `DioException [unknown]`，内部错误是 `FormatException: Invalid HTTP header field value`。
- 非法值是 `"青橘"; v="0.2.28"`，字符位置指向第一个中文字符。
- 请求为 `GET /unread.json`，调用栈为 `getUnreadTopics → TopicListNotifier.build`，不是登录接口调用栈。
- 锁定依赖 `ua_client_hints 1.7.0` 的 `userAgentClientHintsHeader()` 将原生 `appName` 与 `appVersion` 直接拼成 `Sec-CH-UA`。
- `AppConstants._initClientHints()` 原先只移除依赖的 User-Agent，保留非法品牌头；`RequestHeaderInterceptor` 随后将其注入 API 请求。
- 这段初始化只在 Android/iOS 执行，因此此前 Windows 登录验证没有覆盖此故障。

可以确认该非法请求头导致 API 在本地传输前失败；无法仅凭这份日志断言账号密码错误、Cookie 未同步或完整登录流程已经失败。私有原始日志不入库。

## 修改

- `lib/services/network/client_hints.dart`：集中加载并规范化 Client Hints。品牌使用 ASCII `Qingju`，保留数字版本；移除依赖的应用 UA；可选 Hint 中含非 ASCII 或控制字符的值直接丢弃，避免本地化设备型号再次阻断请求。无效版本不生成品牌/完整版本头。
- `lib/constants.dart`：移动端初始化改用上述入口；平台分支与原有 UA、Cookie、CSRF 行为不变。
- `test/services/network/client_hints_test.dart`：6 项回归测试，包括依赖原样输出、旧头触发 FormatException、Android/iOS 元数据、异常型号/版本、新头真实 Dio IO 本地 HTTP 传输。
- `.github/workflows/qingju-release.yml`：所有五平台 Release 包名加入发布标签中的版本，重命名后再计算校验和。例：标签 `qingju-v0.2.28.3` 对应 `qingju-0.2.28.3-android-arm64-debug.apk`、`qingju-0.2.28.3-ios-arm64-unsigned.ipa`、`qingju-0.2.28.3-macos-arm64-adhoc.zip`、`qingju-0.2.28.3-windows-x64.zip`、`qingju-0.2.28.3-linux-x64.tar.gz`。这只是命名示例，不表示该版本已发布。

## 验证

已执行：

```powershell
flutter test --no-pub test/services/network/client_hints_test.dart test/services/qingju_site_boundary_test.dart
dart analyze lib/services/network/client_hints.dart test/services/network/client_hints_test.dart lib/constants.dart
git diff --check
```

结果：19 项测试通过（新增 6 项、原有站点边界 13 项）；定点静态分析 `No issues found!`；差异空白检查通过。

传输用例显式禁用 Flutter 测试绑定默认的假 HTTP 客户端，并在结束时恢复，以确保请求确实到达 loopback HTTP 服务。原生 MethodChannel 元数据使用模拟输入；并非 Android/iOS 真机测试。

另对 YAML 解析后的实际打包脚本进行了临时文件测试：四平台的 PowerShell 重命名/哈希段和 Linux 的 Bash 复制/哈希段均执行通过，五种文件名都带版本，SHA256 与文件一致。没有执行五平台重新构建或发布。

本机准备脚本提示缺少 cargo，代理证书资源未生成；测试也报告缺少 `assets/certs/`。这未阻止上述 19 项测试通过，但不能据此声称完整安装包构建通过。

## 真机验收与需要补充的信息

源码修复已验证；朋友手机的端到端登录尚未验收，需要包含修复的新包，旧包不会自行获得修复。

若新包仍不能登录，请补充：

1. 手机系统及版本、应用完整版本/构建号和安装来源。
2. 登录方式（密码或第三方登录）、最后成功页面，以及是否能返回应用。
3. 从点击登录到报错的连续日志：请求路径、状态码、内部异常、重定向目标；移除密码、Cookie、Token、验证码。
4. 是否启用应用内代理、DoH 或其他网络适配器，以及相同手机浏览器能否登录。

无需提供账号密码或会话凭据。先确认非法请求头异常不再出现，再单独判断服务器认证及会话同步。
