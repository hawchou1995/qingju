import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/deep_link_service.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    DeepLinkService.instance.dispose();
  });

  test('canHandleUri 只接受受支持的 scheme 和 host', () {
    final service = DeepLinkService.instance;

    expect(service.canHandleUri(Uri.parse('https://qingju.me/t/123')), isTrue);
    expect(
      service.canHandleUri(Uri.parse('https://www.qingju.me/t/123')),
      isFalse,
    );
    expect(
      service.canHandleUri(Uri.parse('https://meta.qingju.me/latest')),
      isFalse,
    );
    expect(service.canHandleUri(Uri.parse('qingju://topic/123')), isTrue);
    expect(
      service.canHandleUri(Uri.parse('discourse://auth_redirect?payload=x')),
      isFalse,
    );
    expect(
      service.canHandleUri(Uri.parse('https://example.com/t/123')),
      isFalse,
    );
    expect(service.canHandleUri(Uri.parse('ftp://linux.do/t/123')), isFalse);
  });

  testWidgets('handleUri 不接管非 linux.do 的话题路径', (tester) async {
    BuildContext? capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final context = capturedContext!;
    DeepLinkService.instance.updateContext(context);
    DeepLinkService.instance.handleUri(Uri.parse('https://example.com/t/123'));
    await tester.pump();

    expect(Navigator.of(context).canPop(), isFalse);
  });

  testWidgets('handleUri 支持青橘话题链接', (tester) async {
    BuildContext? capturedContext;
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final context = capturedContext!;
    observer.pushedRoutes.clear();
    DeepLinkService.instance.updateContext(context);
    DeepLinkService.instance.handleUri(Uri.parse('qingju://topic/123/5'));

    expect(observer.pushedRoutes, hasLength(1));
    expect(Navigator.of(context).canPop(), isTrue);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('handleUri 支持青橘用户链接', (tester) async {
    BuildContext? capturedContext;
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final context = capturedContext!;
    observer.pushedRoutes.clear();
    DeepLinkService.instance.updateContext(context);
    DeepLinkService.instance.handleUri(Uri.parse('qingju://user/alice'));

    expect(observer.pushedRoutes, hasLength(1));
    expect(Navigator.of(context).canPop(), isTrue);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('handleUri 对青橘路径大小写不敏感', (tester) async {
    BuildContext? capturedContext;
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final context = capturedContext!;
    observer.pushedRoutes.clear();
    DeepLinkService.instance.updateContext(context);
    DeepLinkService.instance.handleUri(Uri.parse('qingju://Topic/123'));

    expect(observer.pushedRoutes, hasLength(1));
    expect(Navigator.of(context).canPop(), isTrue);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
  });
}
