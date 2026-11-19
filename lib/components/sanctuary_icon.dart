import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Small, local vector symbols. Navigation must not disappear if an icon font
/// fails to load in a web deployment or is removed during font tree shaking.
enum SanctuarySymbol {
  home,
  sounds,
  meditate,
  sleep,
  play,
  pause,
  arrowRight,
  chevronRight,
  chevronDown,
  close,
  check,
  clock,
  leaf,
  moon,
  waves,
  rain,
  wind,
  bolt,
  tree,
  loop,
  restart,
  rewind,
  forward,
  sliders,
  heart,
  heartFill,
  book,
}

class SanctuaryIcon extends StatelessWidget {
  const SanctuaryIcon(
    this.symbol, {
    this.size,
    this.color,
    this.glow = false,
    super.key,
  });

  final SanctuarySymbol symbol;
  final double? size;
  final Color? color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: CustomPaint(
          painter: _SanctuaryIconPainter(
            symbol,
            color ?? theme.color ?? const Color(0xFF7E9AA5),
            glow,
          ),
        ),
      ),
    );
  }
}

class _SanctuaryIconPainter extends CustomPainter {
  const _SanctuaryIconPainter(this.symbol, this.color, this.glow);

  final SanctuarySymbol symbol;
  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    if (glow) {
      _draw(
        canvas,
        Paint()
          ..color = color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5),
      );
    }
    _draw(canvas, stroke);
    canvas.restore();
  }

  void _draw(Canvas canvas, Paint paint) {
    switch (symbol) {
      case SanctuarySymbol.home:
        canvas.drawPath(
          Path()
            ..moveTo(3, 15)
            ..lineTo(16, 3)
            ..lineTo(29, 15)
            ..moveTo(7, 12)
            ..lineTo(7, 29)
            ..lineTo(13, 29)
            ..lineTo(13, 20)
            ..lineTo(19, 20)
            ..lineTo(19, 29)
            ..lineTo(25, 29)
            ..lineTo(25, 12),
          paint,
        );
      case SanctuarySymbol.sounds:
        final fill = Paint()
          ..color = paint.color
          ..maskFilter = paint.maskFilter
          ..isAntiAlias = true;
        for (final rect in const [
          Rect.fromLTWH(3, 11, 5, 17),
          Rect.fromLTWH(13.5, 2, 5, 28),
          Rect.fromLTWH(24, 8, 5, 20),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
            fill,
          );
        }
      case SanctuarySymbol.meditate:
        canvas.drawCircle(const Offset(16, 5), 2.6, paint);
        canvas.drawPath(
          Path()
            ..moveTo(6, 18)
            ..lineTo(11, 14)
            ..lineTo(13, 10)
            ..lineTo(19, 10)
            ..lineTo(21, 14)
            ..lineTo(26, 18)
            ..moveTo(14, 13)
            ..lineTo(13, 20)
            ..lineTo(5, 26)
            ..lineTo(27, 26)
            ..lineTo(19, 20)
            ..lineTo(18, 13)
            ..moveTo(13, 20)
            ..lineTo(8, 22)
            ..lineTo(3, 23)
            ..moveTo(19, 20)
            ..lineTo(24, 22)
            ..lineTo(29, 23)
            ..moveTo(11, 29)
            ..lineTo(21, 29),
          paint,
        );
      case SanctuarySymbol.sleep:
        canvas.drawPath(
          Path()
            ..moveTo(3, 6)
            ..lineTo(3, 29)
            ..moveTo(3, 22)
            ..lineTo(29, 22)
            ..lineTo(29, 12)
            ..lineTo(13, 12)
            ..lineTo(13, 22)
            ..moveTo(3, 15)
            ..lineTo(13, 15)
            ..moveTo(3, 27)
            ..lineTo(29, 27)
            ..lineTo(29, 30),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 10, 5, 5),
            const Radius.circular(1),
          ),
          paint,
        );
      case SanctuarySymbol.play:
        canvas.drawPath(
          Path()
            ..moveTo(10, 6)
            ..lineTo(26, 16)
            ..lineTo(10, 26)
            ..close(),
          Paint()
            ..color = paint.color
            ..maskFilter = paint.maskFilter
            ..isAntiAlias = true,
        );
      case SanctuarySymbol.pause:
        for (final left in const [8.0, 20.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left, 6, 5, 20),
              const Radius.circular(1.5),
            ),
            Paint()
              ..color = paint.color
              ..maskFilter = paint.maskFilter,
          );
        }
      case SanctuarySymbol.arrowRight:
        canvas.drawPath(
          Path()
            ..moveTo(4, 16)
            ..lineTo(27, 16)
            ..moveTo(19, 8)
            ..lineTo(27, 16)
            ..lineTo(19, 24),
          paint,
        );
      case SanctuarySymbol.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(12, 6)
            ..lineTo(22, 16)
            ..lineTo(12, 26),
          paint,
        );
      case SanctuarySymbol.chevronDown:
        canvas.drawPath(
          Path()
            ..moveTo(6, 12)
            ..lineTo(16, 22)
            ..lineTo(26, 12),
          paint,
        );
      case SanctuarySymbol.close:
        canvas.drawPath(
          Path()
            ..moveTo(8, 8)
            ..lineTo(24, 24)
            ..moveTo(24, 8)
            ..lineTo(8, 24),
          paint,
        );
      case SanctuarySymbol.check:
        canvas.drawPath(
          Path()
            ..moveTo(6, 16)
            ..lineTo(13, 23)
            ..lineTo(27, 9),
          paint..strokeWidth = 3,
        );
      case SanctuarySymbol.clock:
        canvas.drawCircle(const Offset(16, 16), 12, paint);
        canvas.drawPath(
          Path()
            ..moveTo(16, 8)
            ..lineTo(16, 17)
            ..lineTo(22, 20),
          paint,
        );
      case SanctuarySymbol.leaf:
        canvas.drawPath(
          Path()
            ..moveTo(27, 4)
            ..cubicTo(12, 2, 4, 9, 5, 21)
            ..cubicTo(14, 28, 28, 24, 27, 4)
            ..close()
            ..moveTo(5, 28)
            ..lineTo(22, 10)
            ..moveTo(11, 21)
            ..lineTo(12, 13)
            ..moveTo(11, 21)
            ..lineTo(19, 21),
          paint,
        );
      case SanctuarySymbol.moon:
        canvas.drawPath(
          Path()
            ..moveTo(27, 21)
            ..cubicTo(14, 27, 5, 13, 13, 3)
            ..cubicTo(-4, 8, 0, 31, 17, 29)
            ..cubicTo(22, 29, 25, 26, 27, 21)
            ..close(),
          paint,
        );
      case SanctuarySymbol.waves:
        for (final y in const [8.0, 16.0, 24.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(3, y)
              ..cubicTo(8, y - 7, 11, y + 7, 16, y)
              ..cubicTo(21, y - 7, 24, y + 7, 29, y),
            paint,
          );
        }
      case SanctuarySymbol.rain:
        canvas.drawPath(
          Path()
            ..moveTo(7, 21)
            ..cubicTo(-1, 20, 0, 9, 8, 9)
            ..cubicTo(10, 0, 23, 0, 25, 10)
            ..cubicTo(33, 10, 33, 21, 25, 21)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 25)
            ..lineTo(7, 29)
            ..moveTo(17, 25)
            ..lineTo(15, 29)
            ..moveTo(25, 25)
            ..lineTo(23, 29),
          paint,
        );
      case SanctuarySymbol.wind:
        canvas.drawPath(
          Path()
            ..moveTo(3, 11)
            ..lineTo(21, 11)
            ..cubicTo(30, 11, 27, -1, 21, 4)
            ..moveTo(3, 17)
            ..lineTo(28, 17)
            ..moveTo(3, 23)
            ..lineTo(17, 23)
            ..cubicTo(26, 23, 23, 35, 17, 30),
          paint,
        );
      case SanctuarySymbol.bolt:
        canvas.drawPath(
          Path()
            ..moveTo(19, 2)
            ..lineTo(5, 18)
            ..lineTo(15, 18)
            ..lineTo(13, 30)
            ..lineTo(27, 13)
            ..lineTo(17, 13)
            ..close(),
          Paint()
            ..color = paint.color
            ..maskFilter = paint.maskFilter
            ..isAntiAlias = true,
        );
      case SanctuarySymbol.tree:
        canvas.drawPath(
          Path()
            ..moveTo(16, 2)
            ..lineTo(6, 14)
            ..lineTo(11, 14)
            ..lineTo(3, 24)
            ..lineTo(13, 24)
            ..lineTo(13, 30)
            ..lineTo(19, 30)
            ..lineTo(19, 24)
            ..lineTo(29, 24)
            ..lineTo(21, 14)
            ..lineTo(26, 14)
            ..close(),
          paint,
        );
      case SanctuarySymbol.loop:
        canvas.drawPath(
          Path()
            ..moveTo(16, 16)
            ..cubicTo(10, 4, 2, 6, 2, 16)
            ..cubicTo(2, 26, 10, 28, 16, 16)
            ..cubicTo(22, 4, 30, 6, 30, 16)
            ..cubicTo(30, 26, 22, 28, 16, 16)
            ..close(),
          paint,
        );
      case SanctuarySymbol.restart:
        canvas.drawPath(
          Path()
            ..moveTo(6, 10)
            ..cubicTo(14, -1, 31, 8, 27, 21)
            ..cubicTo(23, 34, 5, 31, 4, 19)
            ..moveTo(6, 3)
            ..lineTo(6, 11)
            ..lineTo(14, 11),
          paint,
        );
      case SanctuarySymbol.rewind:
        canvas.drawPath(
          Path()
            ..moveTo(14, 6)
            ..lineTo(3, 16)
            ..lineTo(14, 26)
            ..moveTo(28, 6)
            ..lineTo(17, 16)
            ..lineTo(28, 26),
          paint,
        );
      case SanctuarySymbol.forward:
        canvas.drawPath(
          Path()
            ..moveTo(4, 6)
            ..lineTo(15, 16)
            ..lineTo(4, 26)
            ..moveTo(18, 6)
            ..lineTo(29, 16)
            ..lineTo(18, 26),
          paint,
        );
      case SanctuarySymbol.sliders:
        canvas.drawPath(
          Path()
            ..moveTo(3, 7)
            ..lineTo(18, 7)
            ..moveTo(24, 7)
            ..lineTo(29, 7)
            ..moveTo(3, 16)
            ..lineTo(8, 16)
            ..moveTo(14, 16)
            ..lineTo(29, 16)
            ..moveTo(3, 25)
            ..lineTo(20, 25)
            ..moveTo(26, 25)
            ..lineTo(29, 25),
          paint,
        );
        for (final p in const [Offset(21, 7), Offset(11, 16), Offset(23, 25)]) {
          canvas.drawCircle(p, 3, paint);
        }
      case SanctuarySymbol.heart:
      case SanctuarySymbol.heartFill:
        final heart = Path()
          ..moveTo(16, 28)
          ..lineTo(5, 17)
          ..cubicTo(-3, 7, 9, -2, 16, 7)
          ..cubicTo(23, -2, 35, 7, 27, 17)
          ..close();
        canvas.drawPath(
          heart,
          symbol == SanctuarySymbol.heart
              ? paint
              : (Paint()
                  ..color = paint.color
                  ..maskFilter = paint.maskFilter
                  ..isAntiAlias = true),
        );
      case SanctuarySymbol.book:
        canvas.drawPath(
          Path()
            ..moveTo(16, 29)
            ..lineTo(16, 7)
            ..cubicTo(12, 3, 5, 3, 2, 6)
            ..lineTo(2, 27)
            ..cubicTo(7, 24, 12, 25, 16, 29)
            ..cubicTo(20, 25, 25, 24, 30, 27)
            ..lineTo(30, 6)
            ..cubicTo(26, 3, 20, 3, 16, 7),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SanctuaryIconPainter oldDelegate) =>
      oldDelegate.symbol != symbol ||
      oldDelegate.color != color ||
      oldDelegate.glow != glow;
}
