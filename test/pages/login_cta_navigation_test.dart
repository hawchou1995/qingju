import 'dart:io';

import 'package:common_ui/common_ui.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluxdo/config/site_identity.dart';
import 'package:fluxdo/l10n/s.dart';
import 'package:fluxdo/models/user.dart';
import 'package:fluxdo/pages/login_page.dart';
import 'package:fluxdo/pages/profile_page.dart';
import 'package:fluxdo/providers/core_providers.dart';
import 'package:fluxdo/providers/theme_provider.dart';
import 'package:fluxdo/services/discourse/discourse_service.dart';
import 'package:fluxdo/theme/app_theme.dart';
import 'package:fluxdo/theme/theme_resolver.dart';

import '../support/cf_test_platform.dart' show CfTestCookieManager;

/// 未登录资料页的登录按钮要真的能把用户带到青橘登录页，并且那里实际请求的是
/// `https://qingju.me/login`。这里点真实的生产按钮（`ProfilePage` →
/// `_goToLogin` → `LoginPage` → `WebViewLoginPage`），只把原生 WebView 换成
/// 记录请求的 platform fake，网络地址仍由生产代码决定。
void main() {
  // 断言的是中文界面下的用户可见文案。
  setUpAll(() => LocaleSettings.setLocale(AppLocale.zh));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.zh));

  testWidgets('点按未登录资料页登录按钮后请求青橘站点登录页', (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Cookie 预热与本机插件通道不在被测范围：给一个临时目录即可。
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProvider,
      (_) async => Directory.systemTemp.path,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProvider,
        null,
      ),
    );

    final platform = _LoginWebViewPlatform();
    final previousPlatform = InAppWebViewPlatform.instance;
    InAppWebViewPlatform.instance = platform;
    addTearDown(() {
      if (previousPlatform != null) {
        InAppWebViewPlatform.instance = previousPlatform;
      }
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final observer = _RouteSpy();
    late BuildContext context;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // 未登录：资料页底部渲染的是登录入口。
          currentUserProvider.overrideWith(_LoggedOut.new),
          discourseServiceProvider.overrideWithValue(_Service()),
        ],
        child: TranslationProvider(
          child: Builder(
            builder: (outer) => MaterialApp(
              navigatorObservers: [observer],
              theme: _theme(),
              locale: TranslationProvider.of(outer).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Builder(
                builder: (inner) {
                  context = inner;
                  return const ProfilePage();
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 用户此刻看到的就是「登录青橘」。
    final label = _loginCtaLabel(context);
    expect(label, '登录青橘');
    final cta = find.text(label);
    expect(cta, findsOneWidget, reason: '未登录资料页必须有可见登录入口');

    await tester.ensureVisible(cta);
    await tester.pump();
    await tester.tap(cta);

    // 点按的生产 wiring：立刻 push 出登录页路由。
    final route = observer.latest;
    expect(
      route,
      isA<InteractionPageRoute<dynamic>>(),
      reason: '点按后必须走登录页路由',
    );
    expect(
      (route! as InteractionPageRoute<dynamic>).builder(context),
      isA<LoginPage>(),
    );

    await tester.pumpAndSettle();

    // 生产登录页在 `onWebViewCreated` 里先注册回调，再等待一次初始 Cookie 回放
    // （上限 2s，见 `webview_login_page.dart` 的 `_awaitInitialCookieFlush`）
    // 才发出首个 loadUrl。这里先用可见状态确认 WebView 已创建、回调已接线，
    // 再用测试虚拟时钟越过这段等待；不真实等待，也不改生产时序。
    expect(platform.created, isTrue, reason: '登录页必须创建 WebView');
    expect(
      platform.controller.handlers.keys,
      contains('onLoginCredentials'),
      reason: '登录页必须先接上站点登录表单的凭证回调',
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 登录页在 WebView 里实际发出的请求。
    expect(platform.controller.loadRequests, ['https://qingju.me/login']);
    expect(
      find.text(_loginPageTitle(context)),
      findsOneWidget,
      reason: '登录页工具栏标题同样使用青橘站点名',
    );
    expect(
      platform.controller.handlers.keys,
      contains('onLoginCredentials'),
      reason: '登录页要接上站点登录表单的凭证回调',
    );
    expect(tester.takeException(), isNull);
  });
}

/// 读取生产代码里同一份文案，避免测试复制字面量。
String _loginCtaLabel(BuildContext context) =>
    context.l10n.profile_loginLinuxDo;

String _loginPageTitle(BuildContext context) =>
    context.l10n.webviewLogin_title(SiteIdentity.name);

ThemeData _theme() {
  final themeState = ThemeState(
    mode: ThemeMode.system,
    seedColor: Colors.blue,
    themeId: 'material',
  );
  final resolved = ThemeResolver.resolve(
    spec: themeState.themeSpec,
    mode: ThemeMode.system,
    black: false,
    seed: themeState.seedColor,
    variant: themeState.schemeVariant,
  );
  return buildAppTheme(
    resolved.light,
    resolved.lightColors,
    themeState.effectiveShapes,
    themeState,
    fullscreenSwipeBack: false,
    pageBackground: false,
    style: themeState.effectiveStyle,
  );
}

class _RouteSpy extends NavigatorObserver {
  Route<dynamic>? latest;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      latest = route;
}

class _LoggedOut extends CurrentUserNotifier {
  @override
  Future<User?> build() async => null;
}

class _Service implements DiscourseService {
  @override
  final currentUserNotifier = ValueNotifier<User?>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoginWebViewPlatform extends InAppWebViewPlatform {
  final controller = _LoginWebViewController();
  final cookies = CfTestCookieManager();
  bool _created = false;

  @override
  PlatformCookieManager createPlatformCookieManager(
    PlatformCookieManagerCreationParams params,
  ) => cookies;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _LoginWebViewWidget(params, this);

  /// 生产登录页的 `onWebViewCreated` 是否已经接线。
  bool get created => _created;

  /// 只接一次生产页面的 `onWebViewCreated`，避免重复创建控制器。
  void scheduleCreate(PlatformInAppWebViewWidgetCreationParams params) {
    if (_created) return;
    _created = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onCreated = params.onWebViewCreated;
      if (onCreated == null) return;
      onCreated(controller.wrapped);
    });
  }
}

/// 不创建原生视图，只在首帧后把生产页面的 `onWebViewCreated` 接上。
class _LoginWebViewWidget extends PlatformInAppWebViewWidget {
  _LoginWebViewWidget(super.params, this.platform) : super.implementation();

  final _LoginWebViewPlatform platform;

  @override
  Widget build(BuildContext context) {
    platform.scheduleCreate(params);
    return const SizedBox.expand();
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      InAppWebViewController.fromPlatform(platform: controller) as T;

  @override
  void dispose() {}
}

class _LoginWebViewController extends PlatformInAppWebViewController {
  _LoginWebViewController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'login-test'),
      );

  final loadRequests = <String>[];
  final handlers = <String, Function>{};

  InAppWebViewController get wrapped =>
      InAppWebViewController.fromPlatform(platform: this);

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required Function callback,
  }) {
    handlers[handlerName] = callback;
  }

  @override
  Future<void> loadUrl({
    required URLRequest urlRequest,
    WebUri? allowingReadAccessTo,
    Uri? iosAllowingReadAccessTo,
  }) async {
    loadRequests.add(urlRequest.url.toString());
  }

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async => '';

  @override
  Future<WebUri?> getUrl() async => WebUri(
    loadRequests.isEmpty ? 'about:blank' : loadRequests.last,
  );

  @override
  void dispose({bool isKeepAlive = false}) {}
}
