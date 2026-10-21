import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:fluxdo/widgets/preheat_logo.dart';

void main() {
  testWidgets('preheat logo renders the Qingju SVG asset', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PreheatLogo(size: 108)));
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.byWidgetPredicate((widget) => widget is ScalableImageWidget),
      findsWidgets,
    );
  });

  test('preheat title uses the canonical site name', () async {
    final source = await File('lib/widgets/preheat_gate.dart').readAsString();

    expect(source, contains('SiteIdentity.name'));
    expect(source, isNot(contains("'FluxDO'")));
  });
}
