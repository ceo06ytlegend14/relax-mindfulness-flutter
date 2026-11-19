import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The moonlit teal palette from the supplied visual reference.
abstract final class MixerTheme {
  static const background = Color(0xFF001B24);
  static const surface = Color(0xFF042D36);
  static const mint = Color(0xFF43E9CD);
  static const mintLight = Color(0xFF9AFFE6);
  static const text = Color(0xFFF5FAFA);
  static const muted = Color(0xFFA5C0C8);
  static const border = Color(0xFF1D525A);
  static const font = 'MixerSans';
  static const maxWidth = 823.0;
}

class MixerMetrics {
  MixerMetrics(double width)
    : scale = (width / MixerTheme.maxWidth).clamp(0.38, 1.0).toDouble();

  final double scale;
  double get typeScale => math.max(scale, 0.53);
  double space(double value) => value * scale;
  double font(double value) => value * typeScale;

  TextStyle text(
    double size, {
    Color color = MixerTheme.text,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? tracking,
  }) => TextStyle(
    fontFamily: MixerTheme.font,
    fontSize: font(size),
    fontWeight: weight,
    color: color,
    height: height ?? 1.2,
    letterSpacing: tracking,
    decoration: TextDecoration.none,
  );
}

class MixerSurface extends StatelessWidget {
  const MixerSurface({
    required this.child,
    required this.metrics,
    this.active = false,
    this.radius = 26,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final MixerMetrics metrics;
  final bool active;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final s = metrics.scale;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius * s),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFF06444A), Color(0xFF00232C), Color(0xFF00212A)]
              : const [Color(0xFF09343E), Color(0xFF001B25), Color(0xFF01232C)],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(
          color: active
              ? MixerTheme.mint.withOpacity(0.8)
              : MixerTheme.border.withOpacity(0.6),
          width: active ? 1.5 * s : 1 * s,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? MixerTheme.mint.withOpacity(0.16)
                : Colors.black.withOpacity(0.15),
            blurRadius: (active ? 20 : 12) * s,
            offset: Offset(0, 4 * s),
          ),
          BoxShadow(
            color: MixerTheme.mint.withOpacity(active ? 0.05 : 0.025),
            blurRadius: 4 * s,
            spreadRadius: 1 * s,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class MixerSectionHeading extends StatelessWidget {
  const MixerSectionHeading(this.label, {required this.metrics, super.key});
  final String label;
  final MixerMetrics metrics;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: metrics.text(
          17,
          color: const Color(0xFF79E4D0),
          weight: FontWeight.w600,
          tracking: 2.5 * metrics.scale,
        ),
      ),
      SizedBox(width: metrics.space(14)),
      Expanded(
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF397F80), Color(0xFF22434C)],
            ),
          ),
        ),
      ),
    ],
  );
}
