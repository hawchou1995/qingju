import 'package:flutter/material.dart';

import 'webview_login_page.dart';

/// 青橘使用站点自身的完整登录页，兼容验证码、OAuth 与双因素认证。
/// 登录成功后的 Cookie 同步、CSRF 刷新与页面返回沿用既有统一流程。
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const WebViewLoginPage();
}
