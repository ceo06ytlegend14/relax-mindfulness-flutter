import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';

abstract final class SanctuaryPalette {
  static const forest = Color(0xFF001A15);
  static const forestSurface = Color(0xFF062B23);
  static const mint = Color(0xFF78EED0);
  static const mintLight = Color(0xFFADFFE7);
  static const cream = Color(0xFFF7F8EB);
  static const sage = Color(0xFFBED2CA);
  static const navy = Color(0xFF02132C);
  static const navySurface = Color(0xFF122945);
  static const navyActive = Color(0xFF193853);
  static const navyControl = Color(0xFF223F5C);
  static const gold = Color(0xFFF5C96D);
  static const lavender = Color(0xFFABB4E3);
  static const mist = Color(0xFFB9C5DD);
}

/// Uses the same 823px reference canvas as the existing Sounds screen.
/// Small copy keeps a readable floor; card heights remain content-driven.
class SanctuaryMetrics {
  SanctuaryMetrics(double width)
    : scale = (width / MixerTheme.maxWidth).clamp(0.38, 1.0).toDouble();

  final double scale;
  double space(double value) => value * scale;
  double font(double value, {double min = 11}) =>
      math.max(min, value * math.max(0.53, scale));

  TextStyle sans(
    double size, {
    Color color = SanctuaryPalette.cream,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
    double tracking = 0,
    double min = 11,
  }) => TextStyle(
    fontFamily: MixerTheme.font,
    fontSize: font(size, min: min),
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: tracking * scale,
    decoration: TextDecoration.none,
  );

  TextStyle serif(double size, {double min = 19}) => TextStyle(
    fontFamily: 'SanctuarySerif',
    fontSize: font(size, min: min),
    fontWeight: FontWeight.w600,
    height: 1.06,
    letterSpacing: -0.6 * scale,
    color: SanctuaryPalette.cream,
    decoration: TextDecoration.none,
  );
}

class SanctuaryBackdrop extends StatelessWidget {
  const SanctuaryBackdrop({
    required this.asset,
    required this.color,
    required this.height,
    this.darkenLeft = false,
    super.key,
  });

  final String asset;
  final Color color;
  final double height;
  final bool darkenLeft;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          excludeFromSemantics: true,
        ),
        if (darkenLeft)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x66001914), Colors.transparent],
                stops: [0, 0.8],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0), color.withOpacity(0.12), color],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
      ],
    ),
  );
}

class SanctuaryPillButton extends StatelessWidget {
  const SanctuaryPillButton({
    required this.label,
    required this.onPressed,
    required this.metrics,
    this.icon,
    this.trailingIcon,
    this.symbol,
    this.glow = false,
    this.gold = false,
    this.quiet = false,
    this.semanticLabel,
    this.buttonKey,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final SanctuaryMetrics metrics;
  final IconData? icon, trailingIcon;
  final SanctuarySymbol? symbol;
  final bool gold, quiet, glow;
  final String? semanticLabel;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final color = gold ? SanctuaryPalette.gold : MixerTheme.primary;
    final foreground = quiet ? SanctuaryPalette.cream : MixerTheme.onPrimary;
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: CupertinoButton(
        key: buttonKey,
        padding: EdgeInsets.zero,
        minSize: 44,
        onPressed: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.space(gold ? 30 : 26),
            vertical: metrics.space(11),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: quiet ? SanctuaryPalette.navyControl : color,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (symbol != null || icon != null) ...[
                if (symbol != null)
                  SanctuaryIcon(
                    symbol!,
                    size: metrics.font(23, min: 14),
                    color: foreground,
                  )
                else
                  Icon(
                    icon,
                    size: metrics.font(23, min: 14),
                    color: foreground,
                  ),
                SizedBox(width: metrics.space(9)),
              ],
              Text(
                label,
                style: metrics.sans(
                  21,
                  min: 12,
                  weight: FontWeight.w600,
                  color: foreground,
                  height: 1.2,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: metrics.space(14)),
                Icon(
                  trailingIcon,
                  size: metrics.font(22, min: 13),
                  color: foreground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SleepSectionHeading extends StatelessWidget {
  const SleepSectionHeading(
    this.title, {
    required this.metrics,
    this.action,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final SanctuaryMetrics metrics;
  final String? action;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: metrics.sans(
            25,
            min: 15,
            weight: FontWeight.w700,
            tracking: -0.5,
          ),
        ),
      ),
      if (action != null)
        CupertinoButton(
          key: actionKey,
          padding: EdgeInsets.only(left: metrics.space(12)),
          minSize: 44,
          onPressed: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action!,
                style: metrics.sans(
                  19,
                  min: 11.5,
                  color: SanctuaryPalette.mist,
                ),
              ),
              SanctuaryIcon(
                SanctuarySymbol.chevronRight,
                size: metrics.font(18, min: 11),
                color: SanctuaryPalette.mist,
              ),
            ],
          ),
        ),
    ],
  );
}

BoxDecoration sleepSurface({double radius = 26, bool glow = false}) =>
    BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      // Retain the call-site emphasis without an ornamental ring or glow.
      color: glow ? SanctuaryPalette.navyActive : SanctuaryPalette.navySurface,
    );
