import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// 原生启动屏守卫（Android 12+ 的 `SplashTheme.Classic` / `SplashTheme.Modern`）。
///
/// 这几份 drawable 由 `tool/gen_splash_motion.dart` 从
/// `tool/splash_motion/logo_motion.json` 生成，过去曾整块沿用旧版标志，
/// 导致 Android 12+ 原生启动屏与启动图标、Flutter 启动页不是同一个标志。
/// 这里不比对生成结果是否最新（那是 `just splash-motion-check`），而是校验
/// 语义：四份资源存在且被对应主题引用、几何就是启动图标的青橘矢量、
/// 完整落在画布与动效安全区内、日夜配色有足够对比、原生动效保留。
void main() {
  const res = 'android/app/src/main/res';
  const launcherForeground = '$res/drawable/ic_launcher_foreground.xml';

  /// 青橘标志的三个填色：橘色果身、绿色叶片、浅色果心。
  const brandFills = ['#F8AD38', '#A4CE72', '#FFD475'];

  /// 288dp 画布里 logo 占 108dp 居中；Android 12 的图标安全区是以画布中心为
  /// 圆心、直径 192dp 的圆，超出部分会被系统裁掉。
  const canvas = 288.0;
  const logoInset = 90.0;
  const safeRadius = 96.0;

  List<String> splashLogos() => [
    for (final night in [false, true])
      for (final style in ['classic', 'modern'])
        '$res/drawable${night ? '-night' : ''}/splash_logo_$style.xml',
  ];

  /// [night] 传 `''` 或 `'-night'`，直接拼在 drawable 目录名后面。
  String readSplash(String night, String style) =>
      File('$res/drawable$night/splash_logo_$style.xml').readAsStringSync();

  test('日夜 × 经典/现代四份启动屏资源都被对应主题引用', () {
    for (final night in ['', '-night']) {
      final styles =
          File('$res/values$night-v31/styles.xml').readAsStringSync();
      for (final style in ['Classic', 'Modern']) {
        final block = _styleBlock(styles, 'SplashTheme.$style');
        expect(block, isNotNull, reason: 'values$night-v31 缺少 SplashTheme.$style');
        expect(
          block,
          contains(
            '@drawable/splash_logo_${style.toLowerCase()}',
          ),
          reason: 'SplashTheme.$style 应引用同名的青橘标志 drawable',
        );
        expect(
          block,
          contains('@integer/splash_motion_duration'),
          reason: 'SplashTheme.$style 应保留原生描线动效时长',
        );
      }
    }
    for (final path in splashLogos()) {
      expect(File(path).existsSync(), isTrue, reason: '$path 缺失');
      expect(
        File(path).readAsStringSync(),
        contains('<animated-vector'),
        reason: '$path 应仍是描线动画，不能退化成静态图',
      );
    }
  });

  test('四份启动屏的填色几何就是启动图标的青橘矢量', () {
    final launcher = _fillPaths(File(launcherForeground).readAsStringSync());
    expect(
      launcher.keys.toSet(),
      brandFills.toSet(),
      reason: '启动图标应包含橘色果身、绿色叶片与浅色果心三层填色',
    );
    for (final path in splashLogos()) {
      final splash = _fillPaths(File(path).readAsStringSync());
      expect(
        splash.keys.toSet(),
        brandFills.toSet(),
        reason: '$path 的填色应是与启动图标一致的青橘三色',
      );
      for (final color in brandFills) {
        expect(
          splash[color],
          launcher[color],
          reason:
              '$path 的 $color 层应与 $launcherForeground 使用同一段路径坐标，'
              '复用已可用的 Android 矢量而不是另画一份',
        );
      }
    }
  });

  test('四份启动屏的几何完整落在画布与动效安全区内', () {
    for (final path in splashLogos()) {
      final text = File(path).readAsStringSync();
      final transform = _groupTransform(text);
      expect(
        transform.scale,
        1.0,
        reason: '$path 应把 108 单位 viewBox 按 1:1 映射到 108dp',
      );
      expect(
        [transform.dx, transform.dy],
        [logoInset, logoInset],
        reason: '$path 应把标志居中放进 ${canvas.toInt()}dp 画布',
      );

      final extent = _extent(text);
      expect(
        extent.width,
        greaterThan(30),
        reason: '$path 的标志不应是空白或退化形状',
      );
      // 标志在画布坐标系里的实际范围：viewBox 单位 × 缩放 + 平移。
      final left = extent.left * transform.scale + transform.dx;
      final right = extent.right * transform.scale + transform.dx;
      final top = extent.top * transform.scale + transform.dy;
      final bottom = extent.bottom * transform.scale + transform.dy;
      expect(
        [left, top, right, bottom].every((v) => v >= 0 && v <= canvas),
        isTrue,
        reason: '$path 的标志超出 ${canvas.toInt()}dp 画布：$extent',
      );
      // 命中测试四角，确保没有被 Android 12 的图标安全区裁切。
      final center = canvas / 2;
      for (final corner in [
        [left, top],
        [right, top],
        [left, bottom],
        [right, bottom],
      ]) {
        final distance = math.sqrt(
          math.pow(corner[0] - center, 2) + math.pow(corner[1] - center, 2),
        );
        expect(
          distance,
          lessThanOrEqualTo(safeRadius),
          reason: '$path 的标志 "$corner" 落在系统裁切区，启动屏会被切掉一角',
        );
      }
    }
  });

  test('日夜配色对比足够，描线颜色随主题切换', () {
    final backgrounds = <String, String>{
      for (final night in ['', '-night'])
        night: _hexColor(
          File('$res/values$night/splash_colors.xml').readAsStringSync(),
          'splash_background',
        ),
    };
    expect(backgrounds[''], '#F8F9FF');
    expect(backgrounds['-night'], '#111418');

    for (final night in ['', '-night']) {
      for (final style in ['classic', 'modern']) {
        final text = readSplash(night, style);
        final fills = _fillPaths(text).keys.toSet();
        expect(fills, brandFills.toSet(), reason: 'values$night 的 $style 配色应保持青橘');
        // 果身是标志主体轮廓，必须在启动屏底色上可辨认；旧版纯色标志
        // （#F0F0F0 / #F0F0F3）在浅色底上对比只有 1.08，等于看不见。
        expect(
          _contrast('#F8AD38', backgrounds[night]!),
          greaterThan(1.5),
          reason: '$style 的橘色果身在 values$night 底色 ${backgrounds[night]} 上对比不足',
        );
        expect(
          text,
          contains(
            'android:strokeColor="${night.isEmpty ? '#1C1C1E' : '#F0F0F3'}"',
          ),
          reason: 'values$night 的描线颜色应跟随亮/暗主题',
        );
      }
    }
  });

  test('四份启动屏保留原生动效时长与描线/填色动画', () {
    final duration = RegExp(
      r'splash_motion_duration">(\d+)<',
    ).firstMatch(File('$res/values-v31/splash_motion.xml').readAsStringSync());
    expect(duration, isNotNull);
    expect(int.parse(duration!.group(1)!), greaterThanOrEqualTo(500));
    for (final path in splashLogos()) {
      final text = File(path).readAsStringSync();
      for (final interpolator in [
        'splash_motion_stroke',
        'splash_motion_fill',
        'splash_motion_stroke_fade',
      ]) {
        expect(
          text,
          contains('@interpolator/$interpolator'),
          reason: '$path 缺少 $interpolator 动画',
        );
      }
      expect(
        RegExp(r'<target android:name="\w+_(fill|stroke)">').allMatches(text),
        hasLength(6),
        reason: '$path 应对三层填色与三层描线各有一个动画目标',
      );
    }
  });
}

/// 取某个 style 块的原文（`<style name="x" ...>…</style>`）。
String? _styleBlock(String xml, String name) {
  final match = RegExp(
    '<style name="$name"[^>]*>(.*?)</style>',
    dotAll: true,
  ).firstMatch(xml);
  return match?.group(1);
}

/// 解析所有带 `android:fillColor` 的 path，返回 颜色 → 绝对坐标路径。
Map<String, String> _fillPaths(String xml) {
  final out = <String, String>{};
  for (final chunk in xml.split('<path')) {
    final color = RegExp(r'android:fillColor="(#\w+)"').firstMatch(chunk);
    final data = RegExp(r'android:pathData="([^"]+)"').firstMatch(chunk);
    if (color == null || data == null) continue;
    out[color.group(1)!] = _normalizePath(data.group(1)!);
  }
  return out;
}

class _Transform {
  const _Transform(this.dx, this.dy, this.scale);
  final double dx;
  final double dy;
  final double scale;
}

_Transform _groupTransform(String xml) {
  final group = RegExp(r'<group\b[^>]*>').firstMatch(xml)?.group(0);
  expect(group, isNotNull, reason: '缺少 <group> 变换');
  double attr(String name) {
    final match = RegExp('android:$name="(-?[\\d.]+)"').firstMatch(group!);
    expect(match, isNotNull, reason: '<group> 缺少 android:$name');
    return double.parse(match!.group(1)!);
  }

  final scaleX = attr('scaleX');
  final scaleY = attr('scaleY');
  expect(scaleX, scaleY, reason: '标志不应被非等比拉伸');
  return _Transform(attr('translateX'), attr('translateY'), scaleX);
}

/// 把路径解析成绝对坐标命令，与生成器（tool/gen_splash_motion.dart）一致。
List<String> _commands(String d) {
  final tokens = RegExp(
    r'[MmLlHhVvCcQqAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final out = <String>[];
  var i = 0;
  double cx = 0, cy = 0, sx = 0, sy = 0;
  String? op;
  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);
  String n(double v) {
    final rounded = (v * 10000).round() / 10000;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  while (i < tokens.length) {
    if (isCommand(tokens[i])) {
      op = tokens[i++];
    } else if (op == null) {
      fail('路径缺少起始命令: $d');
    }
    final rel = op == op.toLowerCase();
    switch (op.toUpperCase()) {
      case 'M':
        {
          var x = next(), y = next();
          if (rel) {
            x += cx;
            y += cy;
          }
          out.add('M${n(x)},${n(y)}');
          cx = sx = x;
          cy = sy = y;
          op = rel ? 'l' : 'L';
        }
      case 'L':
        {
          var x = next(), y = next();
          if (rel) {
            x += cx;
            y += cy;
          }
          out.add('L${n(x)},${n(y)}');
          cx = x;
          cy = y;
        }
      case 'H':
        {
          var x = next();
          if (rel) x += cx;
          out.add('L${n(x)},${n(cy)}');
          cx = x;
        }
      case 'V':
        {
          var y = next();
          if (rel) y += cy;
          out.add('L${n(cx)},${n(y)}');
          cy = y;
        }
      case 'C':
        {
          final a = [for (var k = 0; k < 6; k++) next()];
          if (rel) {
            for (var k = 0; k < 6; k += 2) {
              a[k] += cx;
              a[k + 1] += cy;
            }
          }
          out.add('C${a.map(n).join(',')}');
          cx = a[4];
          cy = a[5];
        }
      case 'Q':
        {
          // 二次贝塞尔换算成等价三次曲线，启动图标里就有一段 Q。
          var qx = next(), qy = next();
          var x = next(), y = next();
          if (rel) {
            qx += cx;
            qy += cy;
            x += cx;
            y += cy;
          }
          final c1x = cx + 2 / 3 * (qx - cx), c1y = cy + 2 / 3 * (qy - cy);
          final c2x = x + 2 / 3 * (qx - x), c2y = y + 2 / 3 * (qy - y);
          out.add(
            'C${n(c1x)},${n(c1y)},${n(c2x)},${n(c2y)},${n(x)},${n(y)}',
          );
          cx = x;
          cy = y;
        }
      case 'A':
        {
          final rx = next(), ry = next(), rot = next();
          final large = next(), sweep = next();
          var x = next(), y = next();
          if (rel) {
            x += cx;
            y += cy;
          }
          out.add(
            'A${n(rx)},${n(ry)},${n(rot)},${n(large)},${n(sweep)},'
            '${n(x)},${n(y)}',
          );
          cx = x;
          cy = y;
        }
      case 'Z':
        out.add('Z');
        cx = sx;
        cy = sy;
        op = null;
    }
  }
  return out;
}

/// 收尾的 Z 只影响描边是否闭合，填色本来就自动闭合，比对时去掉以免同一段
/// 几何因为写不写 Z 被判成两个形状。
String _normalizePath(String d) {
  final parts = _commands(d);
  if (parts.isNotEmpty && parts.last == 'Z') parts.removeLast();
  return parts.join(' ');
}

class _Extent {
  const _Extent(this.left, this.top, this.right, this.bottom);
  final double left;
  final double top;
  final double right;
  final double bottom;
  double get width => right - left;
  double get height => bottom - top;
  @override
  String toString() =>
      '(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}) - '
      '(${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)})';
}

/// 路径包围盒（viewBox 单位）。圆弧按起止点与半径保守外扩，避免漏算圆的体积。
_Extent _extent(String xml) {
  var left = double.infinity, top = double.infinity;
  var right = -double.infinity, bottom = -double.infinity;
  void include(double x, double y) {
    left = math.min(left, x);
    top = math.min(top, y);
    right = math.max(right, x);
    bottom = math.max(bottom, y);
  }

  for (final chunk in xml.split('<path')) {
    final data = RegExp(r'android:pathData="([^"]+)"').firstMatch(chunk);
    if (data == null) continue;
    var cx = 0.0, cy = 0.0;
    for (final command in _commands(data.group(1)!)) {
      final op = command[0];
      final args = command
          .substring(1)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(double.parse)
          .toList();
      switch (op) {
        case 'M':
        case 'L':
          cx = args[0];
          cy = args[1];
          include(cx, cy);
        case 'C':
          for (var k = 0; k < 6; k += 2) {
            include(args[k], args[k + 1]);
          }
          cx = args[4];
          cy = args[5];
        case 'A':
          final rx = args[0], ry = args[1];
          final large = args[3] != 0, sweep = args[4] != 0;
          final x = args[5], y = args[6];
          // 端点参数化求圆心：沿弦中垂线有两个候选，按 large/sweep 选定，
          // 再看圆心 ± 半径，这样整圆的真实体积不会漏算。
          final r = math.max(rx, ry);
          final dx = x - cx, dy = y - cy;
          final d = math.sqrt(dx * dx + dy * dy);
          final mx = (cx + x) / 2, my = (cy + y) / 2;
          final half = r * r - d * d / 4;
          final h = half > 0 ? math.sqrt(half) : 0.0;
          final sign = large != sweep ? 1.0 : -1.0;
          final ox = d == 0 ? 0.0 : -dy / d * h * sign;
          final oy = d == 0 ? 0.0 : dx / d * h * sign;
          include(mx + ox - r, my + oy - r);
          include(mx + ox + r, my + oy + r);
          include(x, y);
          cx = x;
          cy = y;
        case 'Z':
          break;
      }
    }
  }
  return _Extent(left, top, right, bottom);
}

String _hexColor(String xml, String name) {
  final match = RegExp(
    '<color name="$name">(#[0-9A-Fa-f]+)</color>',
  ).firstMatch(xml);
  expect(match, isNotNull, reason: '缺少 $name');
  return match!.group(1)!;
}

/// WCAG 相对亮度对比度。
double _contrast(String a, String b) {
  double luminance(String hex) {
    final r = int.parse(hex.substring(1, 3), radix: 16) / 255;
    final g = int.parse(hex.substring(3, 5), radix: 16) / 255;
    final b = int.parse(hex.substring(5, 7), radix: 16) / 255;
    double linear(double c) =>
        c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
  }

  final la = luminance(a), lb = luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
