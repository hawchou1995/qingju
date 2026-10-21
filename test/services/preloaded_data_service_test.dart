import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/preloaded_data_service.dart';

void main() {
  late PreloadedDataService service;

  setUp(() {
    service = PreloadedDataService();
    service.reset();
  });

  tearDown(() {
    service.reset();
  });

  test('并发 HTML 补水的 topicList 解析失败不会重复完成 completer', () async {
    final html = _homeHtmlWithInvalidTopicList();
    final uncaughtErrors = <Object>[];

    final result = await runZonedGuarded(
      () async {
        final hydrated = await Future.wait([
          service.hydrateFromHtml(html),
          service.hydrateFromHtml(html),
        ]);

        expect(hydrated, [true, true]);
        final topicList = await service.getInitialTopicList();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        return topicList;
      },
      (error, _) {
        uncaughtErrors.add(error);
      },
    );

    expect(result, isNull);
    expect(uncaughtErrors, isEmpty);
  });
}

String _homeHtmlWithInvalidTopicList() {
  final preloaded = jsonEncode({
    'currentUser': <String, dynamic>{},
    'siteSettings': <String, dynamic>{},
    'site': <String, dynamic>{},
    'topicList': {
      'topic_list': {
        'topics': [null],
      },
    },
  });

  return '<meta id="data-discourse-setup">'
      '<script id="data-preloaded" type="application/json">$preloaded</script>';
}
