import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/config/sites/linuxdo.dart';
import 'package:fluxdo/config/sites/qingju.dart';
import 'package:fluxdo/plugins/plugins.dart';

/// 只改写最小正文字数的假插件，用于验证测试注入路径仍然可用
class _MinLengthPlugin extends SitePlugin {
  const _MinLengthPlugin(this.minLength);

  final int minLength;

  @override
  String get id => 'test-min-length';

  @override
  int composerMinPostLength(int value, ComposerMinLengthContext context) =>
      minLength;
}

const _composerContext = ComposerMinLengthContext(
  isFirstPost: false,
  isPrivateMessage: false,
  isPmWithNonHumanUser: false,
  maxPostLength: 32000,
);

void main() {
  tearDown(PluginRegistry.resetOverride);

  test('默认站点是青橘，且不注册任何插件', () {
    expect(PluginRegistry.plugins, same(qingjuCustomization.plugins));
    expect(PluginRegistry.plugins, isEmpty);
  });

  test('旧站插件不再默认注册（含回复扣积分、warden、字数提示）', () {
    expect(linuxdoCustomization.plugins, isNotEmpty);
    expect(PluginRegistry.plugins.whereType<ReplyCostPlugin>(), isEmpty);
    expect(PluginRegistry.plugins.whereType<WardenPlugin>(), isEmpty);
    expect(PluginRegistry.plugins.whereType<CharacterCountsPlugin>(), isEmpty);
    for (final plugin in linuxdoCustomization.plugins) {
      expect(PluginRegistry.plugins, isNot(contains(plugin)));
    }
  });

  test('消费者：没有插件时最小正文字数原样返回', () {
    expect(PluginRegistry.resolveMinPostLength(8, _composerContext), 8);
  });

  test('消费者：注入的插件生效且可还原', () {
    PluginRegistry.overridePlugins(const [_MinLengthPlugin(16)]);

    expect(PluginRegistry.plugins.single.id, 'test-min-length');
    expect(PluginRegistry.resolveMinPostLength(8, _composerContext), 16);

    PluginRegistry.resetOverride();
    expect(PluginRegistry.plugins, isEmpty);
    expect(PluginRegistry.resolveMinPostLength(8, _composerContext), 8);
  });
}
