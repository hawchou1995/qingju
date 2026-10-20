import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/config/site_identity.dart';
import 'package:fluxdo/config/sites/qingju.dart';
import 'package:fluxdo/constants.dart';
import 'package:fluxdo/services/deep_link_service.dart';
import 'package:fluxdo/services/qr_login_service.dart';
import 'package:fluxdo/services/network/cookie/app_cookie_manager.dart';
import 'package:fluxdo/services/network/interceptors/site_boundary_interceptor.dart';
import 'package:fluxdo/services/network/interceptors/redirect_interceptor.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool redirect = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancelFuture) async {
    requests.add(options);
    if (redirect && options.uri.host == SiteIdentity.host) {
      return ResponseBody.fromString('', 302,
          headers: {'location': ['https://cdn.example/image.png']});
    }
    return ResponseBody.fromString('{}', 200,
        headers: {'content-type': ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('站点身份与插件只指向青橘', () {
    expect(AppConstants.baseUrl, 'https://qingju.me');
    expect(AppConstants.siteCustomization, same(qingjuCustomization));
    expect(qingjuCustomization.plugins, isEmpty);
    expect(qingjuCustomization.avatarGlowRules, isEmpty);
    expect(qingjuCustomization.linkSecurityConfig!.internalDomains,
        ['qingju.me']);
    expect(SiteIdentity.supportsLinuxDoServices, isFalse);
  });

  for (final url in [
    'https://linux.do', 'https://connect.linux.do',
    'http://qingju.me', 'https://qingju.me:444',
    'https://qingju.me.evil.example', 'https://cdn.qingju.me',
  ]) {
    test('凭据源拒绝 $url', () {
      expect(SiteIdentity.isCredentialOrigin(Uri.parse(url)), isFalse);
    });
  }

  test('凭据源只允许 HTTPS 主站', () {
    expect(SiteIdentity.isCredentialOrigin(Uri.parse(SiteIdentity.baseUrl)),
        isTrue);
  });

  test('旧站点请求在适配器执行前拒绝', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(SiteBoundaryInterceptor());
    await expectLater(dio.get('https://credit.linux.do/home'),
        throwsA(isA<DioException>()));
    expect(adapter.requests, isEmpty);
    dio.close();
  });

  test('跨站重定向剥离大小写混合凭据', () async {
    final adapter = _CaptureAdapter()..redirect = true;
    final dio = Dio(BaseOptions(followRedirects: false,
        validateStatus: (status) => status != null && status < 400))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(SiteBoundaryInterceptor());
    dio.interceptors.add(RedirectInterceptor(dio));
    await dio.get('${SiteIdentity.baseUrl}/image', options: Options(headers: {
      'Cookie': '_t=test-only', 'X-CsRf-ToKeN': 'test-only',
      'User-Api-Key': 'test-only', 'Authorization': 'test-only',
      'Accept': 'image/png',
    }));
    expect(adapter.requests.length, 2);
    final headers = adapter.requests.last.headers;
    for (final name in ['cookie', 'x-csrf-token', 'user-api-key', 'authorization']) {
      expect(headers.keys.map((key) => key.toLowerCase()), isNot(contains(name)));
    }
    expect(headers['Accept'], 'image/png');
    dio.close();
  });

  test('外站不会读取或保存主站 Cookie', () async {
    final jar = CookieJar();
    final manager = AppCookieManager(jar);
    await jar.saveFromResponse(Uri.parse(SiteIdentity.baseUrl),
        [Cookie('_t', 'local-test')..secure = true]);
    expect(await manager.loadCookies(RequestOptions(
        path: 'https://linux.do/t/1')), isEmpty);
    await manager.saveCookies(Response(
      requestOptions: RequestOptions(path: 'https://linux.do/'),
      headers: Headers.fromMap({'set-cookie': ['_t=foreign; Path=/']}),
      statusCode: 200,
    ));
    expect(await jar.loadForRequest(Uri.parse('https://linux.do/')), isEmpty);
    expect((await jar.loadForRequest(Uri.parse(SiteIdentity.baseUrl))).single.value,
        'local-test');
  });

  test('深链只接收青橘，不接管原站', () {
    final links = DeepLinkService.instance;
    expect(links.canHandleUri(Uri.parse('https://qingju.me/t/123')), isTrue);
    expect(links.canHandleUri(Uri.parse('qingju://topic/123')), isTrue);
    expect(links.canHandleUri(Uri.parse('https://linux.do/t/123')), isFalse);
    expect(links.canHandleUri(Uri.parse('fluxdo://topic/123')), isFalse);
  });

  test('扫码协议与原客户端隔离', () {
    expect(QrLoginService.scheme, 'qingju');
    expect(QrLoginService.instance.parsePayload(
        'fluxdo://qr-login?v=2&k=x&o=y&u=z&exp=0'), isNull);
  });
}
