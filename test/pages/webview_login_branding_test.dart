import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/config/site_identity.dart';
import 'package:fluxdo/constants.dart';

void main() {
  test('登录工具栏标题使用规范站点身份', () async {
    final source = await File(
      'lib/pages/webview_login_page.dart',
    ).readAsString();

    expect(SiteIdentity.name, '青橘');
    expect(
      source,
      contains('context.l10n.webviewLogin_title(SiteIdentity.name)'),
    );
  });

  test('所有登录标题翻译都使用站点名占位符', () async {
    for (final locale in const ['en', 'zh', 'zh_HK', 'zh_TW']) {
      final file = File('lib/l10n/modules/webview/webview_$locale.arb');
      final arb = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final title = arb['webviewLogin_title'] as String;
      final metadata = arb['@webviewLogin_title'] as Map<String, dynamic>;
      final placeholders = metadata['placeholders'] as Map<String, dynamic>;

      expect(title, contains('{siteName}'), reason: locale);
      expect(title, isNot(contains('LINUX.DO')), reason: locale);
      expect(
        placeholders['siteName'],
        isA<Map<String, dynamic>>(),
        reason: locale,
      );
    }
  });

  test('未登录入口点击后进入青橘登录地址', () async {
    final source = await File(
      'lib/pages/webview_login_page.dart',
    ).readAsString();

    // 页面实际拼出的地址就是站点登录页，而不是旧站或其他站点。
    expect(AppConstants.baseUrl, SiteIdentity.baseUrl);
    expect(
      Uri.parse('${AppConstants.baseUrl}/login').toString(),
      'https://qingju.me/login',
    );
    expect(source, contains(r"'${AppConstants.baseUrl}/login'"));
    expect(source.toLowerCase(), isNot(contains('linux.do')));
  });
}
