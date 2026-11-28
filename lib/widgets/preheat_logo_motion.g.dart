// 由 tool/gen_splash_motion.dart 根据 tool/splash_motion/logo_motion.json 生成，勿手改。
// 修改动画请改规格文件后执行 `just splash-motion`。

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'preheat_logo_motion.dart';

/// 描线动画总时长
const Duration logoMotionDuration = Duration(milliseconds: 1000);

/// 规格基准 logo 边长（逻辑像素），与原生启动屏 logo 等大
const double logoMotionLogoSize = 108.0;

/// 基准 logo 边长下的描线宽度（逻辑像素），随 logo 尺寸等比缩放
const double logoMotionStrokeWidth = 2.5;

const Cubic logoMotionStrokeCurve = Cubic(0.645, 0.045, 0.355, 1.0);
const Cubic logoMotionFillCurve = Cubic(0.42, 0.0, 0.58, 1.0);
const Cubic logoMotionStrokeFadeCurve = Cubic(0.0, 0.0, 0.58, 1.0);

/// 描线整体淡出区间（占总时长比例）
const double logoMotionStrokeFadeStart = 0.84;
const double logoMotionStrokeFadeEnd = 1.0;

/// 启动页底色，与原生启动屏同值
const Color logoMotionBackgroundLight = Color(0xFFF8F9FF);
const Color logoMotionBackgroundDark = Color(0xFF111418);

/// 描线颜色（品牌色，不随主题变化）
const Color logoMotionStrokeLight = Color(0xFF1C1C1E);
const Color logoMotionStrokeDark = Color(0xFFF0F0F3);

final LogoMotionSpec classicLogoMotion = LogoMotionSpec(
  viewBox: const Rect.fromLTWH(0, 0, 108, 108),
  bodyCenter: const Offset(54, 58),
  bodyRadius: 28.0,
  shapes: [
    LogoMotionShape(
      id: 'circle',
      isBody: true,
      fillPath: Path()
        ..moveTo(54, 30)
        ..arcToPoint(
          const Offset(54.1, 30),
          radius: const Radius.circular(28),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      fillLight: const Color(0xFFF8AD38),
      fillDark: const Color(0xFFF8AD38),
      fillStart: 0.45,
      fillEnd: 0.66,
      strokePath: Path()
        ..moveTo(54, 30)
        ..arcToPoint(
          const Offset(54.1, 30),
          radius: const Radius.circular(28),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      strokeStart: 0.0,
      strokeEnd: 0.45,
    ),
    LogoMotionShape(
      id: 'leaf',
      fillPath: Path()
        ..moveTo(52, 32)
        ..cubicTo(53.3333, 18.6667, 62, 14.6667, 78, 20)
        ..cubicTo(75.3333, 30.6667, 66.6667, 34.6667, 52, 32)
        ..close(),
      fillLight: const Color(0xFFA4CE72),
      fillDark: const Color(0xFFA4CE72),
      fillStart: 0.52,
      fillEnd: 0.72,
      strokePath: Path()
        ..moveTo(52, 32)
        ..cubicTo(53.3333, 18.6667, 62, 14.6667, 78, 20)
        ..cubicTo(75.3333, 30.6667, 66.6667, 34.6667, 52, 32),
      strokeStart: 0.2,
      strokeEnd: 0.42,
    ),
    LogoMotionShape(
      id: 'inner',
      fillPath: Path()
        ..moveTo(54, 37)
        ..arcToPoint(
          const Offset(54.1, 37),
          radius: const Radius.circular(21),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      fillLight: const Color(0xFFFFD475),
      fillDark: const Color(0xFFFFD475),
      fillStart: 0.64,
      fillEnd: 0.84,
      strokePath: Path()
        ..moveTo(54, 37)
        ..arcToPoint(
          const Offset(54.1, 37),
          radius: const Radius.circular(21),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      strokeStart: 0.3,
      strokeEnd: 0.52,
    ),
  ],
);

final LogoMotionSpec modernLogoMotion = LogoMotionSpec(
  viewBox: const Rect.fromLTWH(0, 0, 108, 108),
  bodyCenter: const Offset(54, 58),
  bodyRadius: 28.0,
  shapes: [
    LogoMotionShape(
      id: 'circle',
      isBody: true,
      fillPath: Path()
        ..moveTo(54, 30)
        ..arcToPoint(
          const Offset(54.1, 30),
          radius: const Radius.circular(28),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      fillLight: const Color(0xFFF8AD38),
      fillDark: const Color(0xFFF8AD38),
      fillStart: 0.45,
      fillEnd: 0.66,
      strokePath: Path()
        ..moveTo(54, 30)
        ..arcToPoint(
          const Offset(54.1, 30),
          radius: const Radius.circular(28),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      strokeStart: 0.0,
      strokeEnd: 0.45,
    ),
    LogoMotionShape(
      id: 'leaf',
      fillPath: Path()
        ..moveTo(52, 32)
        ..cubicTo(53.3333, 18.6667, 62, 14.6667, 78, 20)
        ..cubicTo(75.3333, 30.6667, 66.6667, 34.6667, 52, 32)
        ..close(),
      fillLight: const Color(0xFFA4CE72),
      fillDark: const Color(0xFFA4CE72),
      fillStart: 0.52,
      fillEnd: 0.72,
      strokePath: Path()
        ..moveTo(52, 32)
        ..cubicTo(53.3333, 18.6667, 62, 14.6667, 78, 20)
        ..cubicTo(75.3333, 30.6667, 66.6667, 34.6667, 52, 32),
      strokeStart: 0.2,
      strokeEnd: 0.42,
    ),
    LogoMotionShape(
      id: 'inner',
      fillPath: Path()
        ..moveTo(54, 37)
        ..arcToPoint(
          const Offset(54.1, 37),
          radius: const Radius.circular(21),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      fillLight: const Color(0xFFFFD475),
      fillDark: const Color(0xFFFFD475),
      fillStart: 0.64,
      fillEnd: 0.84,
      strokePath: Path()
        ..moveTo(54, 37)
        ..arcToPoint(
          const Offset(54.1, 37),
          radius: const Radius.circular(21),
          largeArc: true,
          clockwise: false,
        )
        ..close(),
      strokeStart: 0.3,
      strokeEnd: 0.52,
    ),
  ],
);
