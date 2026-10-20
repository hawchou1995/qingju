import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/network/client_hints.dart';
import 'package:ua_client_hints/ua_client_hints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ua_client_hints');
  final originalHttpOverrides = HttpOverrides.current;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, Object> metadata;

  setUp(() {
    // 本组验证真实 IO 传输，禁用 Flutter 测试默认的 HTTP 400 假客户端。
    HttpOverrides.global = null;
    metadata = {
      'appName': '青橘',
      'appVersion': '0.2.28',
      'version': '0.2.28',
      'platform': 'Android',
      'platformVersion': '14',
      'architecture': 'arm64-v8a',
      'model': 'Pixel 8',
      'device': 'shiba',
      'brand': 'Google',
      'mobile': true,
    };
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getInfo');
      return metadata;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    HttpOverrides.global = originalHttpOverrides;
  });

  test('旧依赖输出逐字复现日志中的非法请求头', () async {
    final hints = await userAgentClientHintsHeader();
    expect(hints['Sec-CH-UA'], '"青橘"; v="0.2.28"');
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.port}/unread.json'),
    );
    expect(
      () => request.headers.set('Sec-CH-UA', hints['Sec-CH-UA']!),
      throwsA(isA<FormatException>()),
    );
    request.abort();
  });

  for (final platform in ['Android', 'iOS']) {
    test('$platform 保留中文显示名但使用 ASCII 网络品牌', () async {
      metadata['platform'] = platform;
      final hints = await loadForumClientHints();
      expect(metadata['appName'], '青橘');
      expect(hints['Sec-CH-UA'], '"Qingju"; v="0.2.28"');
      expect(hints, isNot(contains('User-Agent')));
      expect(hints['Sec-CH-UA-Platform'], platform);
      expect(hints['Sec-CH-UA-Mobile'], '?1');
      expect(
        hints.values.every(
          (v) => v.codeUnits.every((u) => u >= 32 && u <= 126),
        ),
        isTrue,
      );
    });
  }

  test('丢弃本地化设备型号和控制字符，不影响其他 Hint', () async {
    metadata['model'] = '小米手机';
    metadata['architecture'] = 'arm64\r\nx-injected: yes';
    final hints = await loadForumClientHints();
    expect(hints, isNot(contains('Sec-CH-UA-Model')));
    expect(hints, isNot(contains('Sec-CH-UA-Arch')));
    expect(hints['Sec-CH-UA-Platform'], 'Android');
  });

  test('无效版本不会形成带引号注入或中文的品牌头', () async {
    metadata['appVersion'] = '版本"\r\n';
    final hints = await loadForumClientHints();
    expect(hints, isNot(contains('Sec-CH-UA')));
    expect(hints, isNot(contains('Sec-CH-UA-Full-Version')));
    expect(hints['Sec-CH-UA-Mobile'], '?1');
  });

  test('修复后的 Hint 经 Dio IO 实际到达本地 HTTP 服务', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = server.first.then((request) async {
      final brand = request.headers.value('sec-ch-ua');
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"ok":true}');
      await request.response.close();
      return brand;
    });
    final dio = Dio()
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
      );
    addTearDown(() => dio.close(force: true));
    final response = await dio.get<Map<String, dynamic>>(
      'http://127.0.0.1:${server.port}/unread.json',
      options: Options(headers: await loadForumClientHints()),
    );
    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(await received, '"Qingju"; v="0.2.28"');
  });
}
