import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/components/wellbeing_components.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

class BreatheScreen extends StatefulWidget {
  const BreatheScreen({super.key});

  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _orb;
  Timer? _timer;
  BreathingPattern? _pattern;
  bool _running = false;
  bool _completed = false;
  int _minutes = 3;
  int _remaining = 180;
  int _cycleTick = 0;
  BreathPhase _phase = BreathPhase.inhale;
  int _phaseLeft = 4;
  int _phaseDuration = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A hidden tab must not silently finish a breathing practice. Resume is
    // explicit, and keeps the current phase/countdown rather than restarting it.
    if (!TickerMode.of(context) && _running) _pause();
    final pattern = context.read<AppState>().pattern;
    if (_pattern != pattern) {
      _pattern = pattern;
      _reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _running) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _orb.dispose();
    super.dispose();
  }

  void _pause() {
    _timer?.cancel();
    _orb.stop();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    _orb.stop();
    _orb.value = 0;
    setState(() {
      _running = false;
      _completed = false;
      _remaining = _minutes * 60;
      _cycleTick = 0;
      _phase = BreathPhase.inhale;
      _phaseLeft = _pattern?.inhale ?? 4;
      _phaseDuration = _phaseLeft;
    });
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_running) {
      _pause();
      return;
    }
    if (_completed) _reset();
    setState(() => _running = true);
    _animatePhase();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) return;
      if (!TickerMode.of(context) ||
          ModalRoute.of(context)?.isCurrent == false) {
        _pause();
        return;
      }
      final pattern = _pattern!;
      final previous = _phase;
      setState(() {
        _remaining--;
        _cycleTick = (_cycleTick + 1) % pattern.totalCycle;
        var elapsed = 0;
        for (final entry in [
          (BreathPhase.inhale, pattern.inhale),
          (BreathPhase.hold, pattern.hold),
          (BreathPhase.exhale, pattern.exhale),
          (BreathPhase.holdOut, pattern.holdOut),
        ]) {
          if (entry.$2 > 0 && _cycleTick < elapsed + entry.$2) {
            _phase = entry.$1;
            _phaseDuration = entry.$2;
            _phaseLeft = entry.$2 - (_cycleTick - elapsed);
            break;
          }
          elapsed += entry.$2;
        }
      });
      if (_remaining <= 0) {
        _timer?.cancel();
        _orb.stop();
        setState(() {
          _running = false;
          _completed = true;
        });
        context.read<AppState>().recordSession(
          '${pattern.displayName} Session',
          'Breathing',
          _minutes,
        );
      } else if (_phase != previous) {
        HapticFeedback.selectionClick();
        _animatePhase();
      }
    });
  }

  void _animatePhase() {
    final progress = 1 - _phaseLeft / _phaseDuration;
    final expanding = _phase == BreathPhase.inhale;
    if (MediaQuery.disableAnimationsOf(context)) {
      _orb.value = _phase == BreathPhase.inhale || _phase == BreathPhase.hold
          ? 1
          : 0;
      return;
    }
    _orb.duration = Duration(seconds: _phaseDuration);
    switch (_phase) {
      case BreathPhase.inhale:
      case BreathPhase.exhale:
        if (expanding) {
          _orb.forward(from: progress);
        } else {
          _orb.reverse(from: 1 - progress);
        }
      case BreathPhase.hold:
        _orb.value = 1;
      case BreathPhase.holdOut:
        _orb.value = 0;
    }
  }

  String get _phaseLabel => switch (_phase) {
    BreathPhase.inhale => 'Breathe in',
    BreathPhase.hold => 'Hold gently',
    BreathPhase.exhale => 'Breathe out',
    BreathPhase.holdOut => 'Rest',
  };

  void _selectPattern(BreathingPattern pattern) {
    context.read<AppState>().setPattern(pattern);
    _pattern = pattern;
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final time =
        '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}';
    final button = _running
        ? 'Pause practice'
        : _completed
        ? 'Start again'
        : _remaining < _minutes * 60
        ? 'Resume practice'
        : 'Begin practice';
    return WellbeingPage(
      title: 'Breathing room',
      scrollKey: const PageStorageKey('breathing-scroll'),
      builder: (context, m) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WellbeingEyebrow('ONE BREATH AT A TIME'),
          const SizedBox(height: 10),
          Text(
            'Find your\ncomfortable rhythm.',
            key: const ValueKey('breathing-title'),
            style: m.serif(60, min: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Follow the circle, or simply breathe naturally. There is no need to keep up.',
            style: m.sans(22, min: 14, color: MixerTheme.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          WellbeingSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: WellbeingEyebrow('YOUR QUIET TIMER')),
                    const SizedBox(width: 12),
                    Text(
                      time,
                      key: const ValueKey('breathing-time'),
                      style: m.sans(30, min: 22, weight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = math.min(250.0, constraints.maxWidth);
                    return Center(
                      child: SizedBox.square(
                        dimension: size,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final fraction in [1.0, 0.84, 0.66])
                              Container(
                                width: size * fraction,
                                height: size * fraction,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: MixerTheme.mint.withOpacity(0.12),
                                  ),
                                ),
                              ),
                            AnimatedBuilder(
                              animation: _orb,
                              builder: (context, _) => Transform.scale(
                                scale: 0.65 + _orb.value * 0.32,
                                child: Container(
                                  width: size * 0.84,
                                  height: size * 0.84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0D514F),
                                    border: Border.all(
                                      color: MixerTheme.mint.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _completed ? '✓' : '$_phaseLeft',
                                  key: const ValueKey(
                                    'breathing-phase-seconds',
                                  ),
                                  style: m.serif(82, min: 45),
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _completed ? 'Well done' : _phaseLabel,
                                    key: const ValueKey('breathing-phase'),
                                    style: m.sans(23, min: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  _completed
                      ? 'Your practice is complete. Take a moment before you move on.'
                      : app.pattern.description,
                  textAlign: TextAlign.center,
                  style: m.sans(
                    21,
                    min: 13,
                    color: MixerTheme.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                CupertinoButton.filled(
                  key: const ValueKey('breathing-toggle'),
                  onPressed: _toggle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SanctuaryIcon(
                        _running ? SanctuarySymbol.pause : SanctuarySymbol.play,
                        color: MixerTheme.background,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(button, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  key: const ValueKey('breathing-reset'),
                  onPressed: _reset,
                  child: const Text('Reset timer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const WellbeingEyebrow('CHOOSE YOUR PACE'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final pattern in BreathingPattern.values)
                _Choice(
                  key: ValueKey('breathing-pattern-${pattern.name}'),
                  label: pattern.displayName,
                  selected: app.pattern == pattern,
                  onPressed: () => _selectPattern(pattern),
                ),
            ],
          ),
          const SizedBox(height: 23),
          const WellbeingEyebrow('MAKE A LITTLE TIME'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final minutes in [1, 3, 5, 10, 15])
                _Choice(
                  key: ValueKey('breathing-duration-$minutes'),
                  label: '$minutes min',
                  selected: _minutes == minutes,
                  onPressed: () {
                    _minutes = minutes;
                    _reset();
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Changing the pace or duration resets the timer. Leaving this page or putting the app in the background pauses or ends the practice; it will not silently count as completed.\n\nKeep every breath comfortable. Skip holds, return to normal breathing, or stop if you feel dizzy or uncomfortable. This is a relaxation tool, not medical advice.',
            style: m.sans(18, min: 12, color: MixerTheme.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? MixerTheme.primary : MixerTheme.action,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MixerTheme.font,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? MixerTheme.onPrimary : MixerTheme.text,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationThickness: 2,
          ),
        ),
      ),
    ),
  );
}
