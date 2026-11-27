import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fluxdo/config/site_identity.dart';
import 'package:fluxdo/l10n/s.dart';

/// 登录入口统一走站点自身的登录页（`WebViewLoginPage`），因此这里覆盖用户
/// 在“未登录”资料页按钮和登录页工具栏上真正看到的文案：按真实渲染路径取
/// `context.l10n`，而不是只断言常量。上游 linux.do 原生表单已被站点登录页
/// 取代，对应的表单控件断言不再适用。
void main() {
  // 延迟翻译的构建必须在 widget 测试的 fake async 区域之外完成。
  setUpAll(() async {
    for (final locale in AppLocale.values) {
      await LocaleSettings.setLocale(locale);
    }
  });

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.zh));

  const expectedCopy = <AppLocale, (String entry, String title)>{
    AppLocale.zh: ('登录青橘', '登录 青橘'),
    AppLocale.zhHk: ('登錄青橘', '登錄 青橘'),
    AppLocale.zhTw: ('登入青橘', '登入 青橘'),
    AppLocale.en: ('Log in to Qingju', 'Log in to 青橘'),
  };

  /// 取指定语言下真实渲染用到的文案对象。
  Future<AppLocalizations> pumpCopy(
    WidgetTester tester,
    AppLocale locale,
  ) async {
    LocaleSettings.setLocaleSync(locale);
    late AppLocalizations copy;
    await tester.pumpWidget(
      TranslationProvider(
        child: Builder(
          builder: (context) => MaterialApp(
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Builder(
              builder: (inner) {
                copy = inner.l10n;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return copy;
  }

  testWidgets('未登录入口与登录页标题在四种语言下都显示青橘品牌', (tester) async {
    for (final entry in expectedCopy.entries) {
      final copy = await pumpCopy(tester, entry.key);

      expect(
        copy.profile_loginLinuxDo,
        entry.value.$1,
        reason: '未登录资料页按钮文案 (${entry.key})',
      );
      expect(
        copy.webviewLogin_title(SiteIdentity.name),
        entry.value.$2,
        reason: '登录页工具栏标题 (${entry.key})',
      );
      expect(tester.takeException(), isNull, reason: '${entry.key}');
    }
  });

  testWidgets('登录入口相关文案不再出现旧站名称', (tester) async {
    for (final locale in AppLocale.values) {
      final copy = await pumpCopy(tester, locale);
      final rendered = [
        copy.profile_loginLinuxDo,
        copy.webviewLogin_title(SiteIdentity.name),
        copy.webviewLogin_loginSuccess,
      ].join('\n').toLowerCase();

      expect(rendered, isNot(contains('linux.do')), reason: '$locale');
    }
  });
}
