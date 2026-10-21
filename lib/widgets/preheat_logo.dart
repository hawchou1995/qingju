import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// 使用当前青橘品牌 SVG 展示预热页标志。
class PreheatLogo extends StatelessWidget {
  const PreheatLogo({super.key, this.size = 108});

  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = ScalableImageWidget.fromSISource(
      si: ScalableImageSource.fromSvg(
        DefaultAssetBundle.of(context),
        'assets/logo.svg',
        warnF: (_) {},
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.scale(scale: 0.88 + (0.12 * progress), child: child),
      ),
      child: SizedBox(width: size, height: size, child: logo),
    );
  }
}
