import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Moonlit teal, with the matte surfaces approved in the Home trial.
/// Keep outlines for inputs/focus/state, not as default card decoration.
abstract final class MixerTheme {
  static const background = Color(0xFF001B24);
  static const surface = Color(0xFF0A3039);
  static const surfaceActive = Color(0xFF103E42);
  static const action = Color(0xFF082C35);
  static const quiet = Color(0xFF062831);
  static const control = Color(0xFF164D51);
  static const primary = Color(0xFF8CE7D0);
  static const onPrimary = Color(0xFF002B26);
  static const heading = Color(0xFF95BBB7);
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: active ? MixerTheme.surfaceActive : MixerTheme.surface,
      borderRadius: BorderRadius.circular(radius * metrics.scale),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class MixerSectionHeading extends StatelessWidget {
  const MixerSectionHeading(this.label, {required this.metrics, super.key});
  final String label;
  final MixerMetrics metrics;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: metrics.text(
      17,
      color: MixerTheme.heading,
      weight: FontWeight.w600,
      tracking: 2.5 * metrics.scale,
    ),
  );
}
