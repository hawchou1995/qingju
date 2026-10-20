import 'package:ua_client_hints/ua_client_hints.dart';

/// 显示名称可以本地化，Client Hints 的网络品牌必须使用 ASCII。
Future<Map<String, String>> loadForumClientHints() async {
  final hints = Map<String, String>.from(await userAgentClientHintsHeader());
  // 使用 AppConstants 清理后的浏览器 UA，不发送依赖生成的中文应用 UA。
  hints.removeWhere((name, _) => name.toLowerCase() == 'user-agent');
  final version = hints['Sec-CH-UA-Full-Version'];
  if (version != null && RegExp(r'^\d+(?:\.\d+)*$').hasMatch(version)) {
    hints['Sec-CH-UA'] = '"Qingju"; v="$version"';
  } else {
    hints.remove('Sec-CH-UA');
    hints.remove('Sec-CH-UA-Full-Version');
  }
  // 原生元数据（如设备型号）也可能本地化；非法 Hint 不应阻断所有 API。
  hints.removeWhere(
    (_, value) => value.codeUnits.any((unit) => unit < 0x20 || unit > 0x7e),
  );
  return hints;
}
