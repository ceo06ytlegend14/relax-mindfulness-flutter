import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// A decorative waveform, frozen when paused, offscreen or reduced motion is on.
class MixerWaveform extends StatefulWidget {
  const MixerWaveform({required this.playing, super.key});
  final bool playing;

  @override
  State<MixerWaveform> createState() => _MixerWaveformState();
}

class _MixerWaveformState extends State<MixerWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  void _syncAnimation() {
    final animate =
        widget.playing &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate && !_animation.isAnimating) {
      _animation.repeat();
    } else if (!animate && _animation.isAnimating) {
      _animation.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant MixerWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(painter: _WaveformPainter(_animation)),
    ),
  );
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 155;
    final path = Path();
    final phase = animation.value * math.pi * 2;
    for (var i = 0; i < count; i++) {
      final x = i / (count - 1);
      final envelope = math.exp(-math.pow((x - 0.51) * 5.0, 2));
      final detail = 0.3 + 0.7 * (math.sin(i * 1.73 + phase).abs());
      final halfHeight = size.height * (0.025 + envelope * detail * 0.45);
      path.moveTo(x * size.width, size.height / 2 - halfHeight);
      path.lineTo(x * size.width, size.height / 2 + halfHeight);
    }
    final shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, 0),
      [
        MixerTheme.mint.withOpacity(0),
        MixerTheme.mint.withOpacity(0.8),
        MixerTheme.mint,
        MixerTheme.mint.withOpacity(0.6),
        MixerTheme.mint.withOpacity(0),
      ],
      const [0, 0.2, 0.5, 0.8, 1],
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, size.width / 520)
      ..shader = shader;
    canvas.drawPath(
      path,
      paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(path, paint..maskFilter = null);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
