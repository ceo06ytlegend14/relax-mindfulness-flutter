import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/services/pwa_player_visibility.dart';

const _mint = Color(0xFF56EBCB);
const _pearl = Color(0xFFF7FAF5);
const _mist = Color(0xFFD0DFE5);

String _clock(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Photographic, local-asset player. The timer, transport and slider all share
/// AppState's actual session; pausing or minimizing never discards that session.
class GuidedPlayerOverlay extends StatefulWidget {
  const GuidedPlayerOverlay({super.key});

  @override
  State<GuidedPlayerOverlay> createState() => _GuidedPlayerOverlayState();
}

class _GuidedPlayerOverlayState extends State<GuidedPlayerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool _pulsing = false;
  double? _scrubSeconds;

  @override
  void initState() {
    super.initState();
    setPwaPlayerExpanded(true);
  }

  @override
  void dispose() {
    setPwaPlayerExpanded(false);
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.hasGuidedSession) return const SizedBox.shrink();
    final animate =
        app.isGuidedPlaying &&
        !MediaQuery.of(context).disableAnimations &&
        !MediaQuery.of(context).accessibleNavigation;
    if (_pulsing != animate) {
      _pulsing = animate;
      if (animate) {
        _breath.repeat(reverse: true);
      } else {
        _breath.stop();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) app.minimizeGuidedPlayer();
      },
      child: BlockSemantics(
        child: Semantics(
          explicitChildNodes: true,
          scopesRoute: true,
          namesRoute: true,
          label: 'Session player',
          child: FocusScope(
            autofocus: true,
            child: Material(
              color: const Color(0xFF092334),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/player/lake_dawn.webp',
                    key: const ValueKey('player-landscape'),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x7A102D43),
                          Color(0x4A173249),
                          Color(0xA309253C),
                          Color(0xC2061728),
                        ],
                        stops: [0, 0.34, 0.72, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final s = (constraints.maxWidth / 430)
                            .clamp(0.78, 1.55)
                            .toDouble();
                        final cover = math.min(
                          math.min(constraints.maxWidth * 0.48, 360.0),
                          math.max(132.0, constraints.maxHeight * 0.25),
                        );
                        final title = app.currentGuidedTitle!;
                        final total = math.max(1, app.guidedTotalSec);
                        final elapsed =
                            (_scrubSeconds ?? app.guidedElapsedSec.toDouble())
                                .clamp(0.0, total.toDouble())
                                .toDouble();
                        final loading = app.isGuidedLoading;
                        return SingleChildScrollView(
                          key: const ValueKey('guided-player-scroll'),
                          padding: EdgeInsets.all(18 * s),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0,
                                constraints.maxHeight - 36 * s,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        _PlayerGlass(
                                          radius: 100,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14 * s,
                                              vertical: 10 * s,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SanctuaryIcon(
                                                  SanctuarySymbol.sounds,
                                                  color: _mint,
                                                  size: 18 * s,
                                                ),
                                                SizedBox(width: 9 * s),
                                                Text(
                                                  'SOOTHING AUDIO',
                                                  style: _type(
                                                    11 * s,
                                                    weight: FontWeight.w600,
                                                    tracking: 1.1,
                                                  ),
                                                ),
                                                SizedBox(width: 10 * s),
                                                Container(
                                                  width: 6 * s,
                                                  height: 6 * s,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: app.isGuidedPlaying
                                                        ? _mint
                                                        : _mist,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        _CircleControl(
                                          buttonKey: const ValueKey(
                                            'minimize-guided-player',
                                          ),
                                          label: 'Minimize session player',
                                          symbol: SanctuarySymbol.chevronDown,
                                          size: 42 * s,
                                          onPressed: app.minimizeGuidedPlayer,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20 * s),
                                    AnimatedBuilder(
                                      animation: _breath,
                                      builder: (context, _) =>
                                          _BreathingArtwork(
                                            size: cover,
                                            scale: s,
                                            pulse: animate
                                                ? _breath.value
                                                : 0.35,
                                            artwork: guidedPlayerArtwork(title),
                                          ),
                                    ),
                                    SizedBox(height: 10 * s),
                                    Text(
                                      title,
                                      key: const ValueKey(
                                        'guided-player-title',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: _type(
                                        28 * s,
                                        weight: FontWeight.w600,
                                        height: 1.16,
                                        tracking: -0.6,
                                      ),
                                    ),
                                    SizedBox(height: 7 * s),
                                    Text(
                                      app.isGuidedLooping
                                          ? 'Calming audio · A little space to breathe.'
                                          : 'Calming audio · Stops when this audio ends.',
                                      textAlign: TextAlign.center,
                                      style: _type(
                                        math.max(12, 13 * s),
                                        color: _mist,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (app.guidedPlaybackError != null) ...[
                                      SizedBox(height: 12 * s),
                                      Semantics(
                                        liveRegion: true,
                                        child: Text(
                                          app.guidedPlaybackError!,
                                          key: const ValueKey(
                                            'guided-playback-error',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: _type(
                                            math.max(12, 13 * s),
                                            color: const Color(0xFFFFDCAB),
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 16 * s),
                                    Text(
                                      _clock(app.guidedRemainingSec),
                                      key: const ValueKey('guided-countdown'),
                                      style:
                                          _type(
                                            58 * s,
                                            weight: FontWeight.w500,
                                            height: 1.05,
                                            tracking: 1.2,
                                          ).copyWith(
                                            fontFeatures: const [
                                              ui.FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                    SizedBox(height: 3 * s),
                                    Text(
                                      loading
                                          ? 'PREPARING YOUR SOUNDSCAPE'
                                          : app.isGuidedPlaying
                                          ? 'TIME TO UNWIND'
                                          : 'PAUSED · STAY A LITTLE LONGER',
                                      key: const ValueKey(
                                        'guided-playback-status',
                                      ),
                                      style: _type(
                                        math.max(9, 9.5 * s),
                                        color: _mist,
                                        tracking: 1.8,
                                      ),
                                    ),
                                    SizedBox(height: 5 * s),
                                    SizedBox(
                                      width: math.min(
                                        constraints.maxWidth,
                                        540 * s,
                                      ),
                                      child: Column(
                                        children: [
                                          Semantics(
                                            label: 'Session progress',
                                            value:
                                                '${_clock(elapsed.round())} of ${_clock(total)}',
                                            child: SizedBox(
                                              height: 32 * s,
                                              child: CupertinoSlider(
                                                key: const ValueKey(
                                                  'guided-progress',
                                                ),
                                                value: elapsed,
                                                min: 0,
                                                max: total.toDouble(),
                                                activeColor: _mint,
                                                thumbColor: _pearl,
                                                onChangeStart:
                                                    app.canSeekGuidedSession
                                                    ? (value) => setState(
                                                        () => _scrubSeconds =
                                                            value,
                                                      )
                                                    : null,
                                                onChanged:
                                                    app.canSeekGuidedSession
                                                    ? (value) => setState(
                                                        () => _scrubSeconds =
                                                            value,
                                                      )
                                                    : null,
                                                onChangeEnd:
                                                    app.canSeekGuidedSession
                                                    ? (value) async {
                                                        await app
                                                            .seekGuidedSession(
                                                              value.round(),
                                                            );
                                                        if (mounted)
                                                          setState(
                                                            () =>
                                                                _scrubSeconds =
                                                                    null,
                                                          );
                                                      }
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _clock(elapsed.round()),
                                                  key: const ValueKey(
                                                    'guided-elapsed',
                                                  ),
                                                  style: _type(
                                                    12 * s,
                                                    color: _mist,
                                                  ),
                                                ),
                                                Text(
                                                  _clock(total),
                                                  key: const ValueKey(
                                                    'guided-duration',
                                                  ),
                                                  style: _type(
                                                    12 * s,
                                                    color: _mist,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 13 * s),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _SeekControl(
                                          label: 'Back 10 seconds',
                                          caption: '−10 sec',
                                          buttonKey: const ValueKey(
                                            'guided-back-10',
                                          ),
                                          symbol: SanctuarySymbol.rewind,
                                          scale: s,
                                          onPressed: app.canSeekGuidedSession
                                              ? () => app.seekGuidedSession(
                                                  app.guidedElapsedSec - 10,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 27 * s),
                                        Semantics(
                                          label: loading
                                              ? 'Loading calming audio'
                                              : app.isGuidedPlaying
                                              ? 'Pause session'
                                              : app.guidedPlaybackError != null
                                              ? 'Retry audio'
                                              : 'Resume session',
                                          button: true,
                                          child: CupertinoButton(
                                            key: const ValueKey(
                                              'guided-play-pause',
                                            ),
                                            padding: EdgeInsets.zero,
                                            onPressed: loading
                                                ? null
                                                : () {
                                                    if (app.isGuidedPlaying) {
                                                      app.pauseGuidedSession();
                                                    } else {
                                                      app.resumeGuidedSession();
                                                    }
                                                  },
                                            child: Container(
                                              width: 78 * s,
                                              height: 78 * s,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const RadialGradient(
                                                  center: Alignment(-0.3, -0.5),
                                                  colors: [
                                                    Color(0xFF65E8CC),
                                                    Color(0xFF15A991),
                                                    Color(0xFF087B78),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFB8FFEB,
                                                  ),
                                                  width: 1.3,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x6635E4C5),
                                                    blurRadius: 26,
                                                    spreadRadius: 2,
                                                  ),
                                                  BoxShadow(
                                                    color: Color(0x33000000),
                                                    blurRadius: 15,
                                                    offset: Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: loading
                                                    ? const CupertinoActivityIndicator(
                                                        color: _pearl,
                                                      )
                                                    : SanctuaryIcon(
                                                        app.isGuidedPlaying
                                                            ? SanctuarySymbol
                                                                  .pause
                                                            : SanctuarySymbol
                                                                  .play,
                                                        size: 37 * s,
                                                        color: _pearl,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 27 * s),
                                        _SeekControl(
                                          label: 'Forward 10 seconds',
                                          caption: '+10 sec',
                                          buttonKey: const ValueKey(
                                            'guided-forward-10',
                                          ),
                                          symbol: SanctuarySymbol.forward,
                                          scale: s,
                                          onPressed: app.canSeekGuidedSession
                                              ? () => app.seekGuidedSession(
                                                  app.guidedElapsedSec + 10,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 17 * s),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 9 * s,
                                      runSpacing: 4,
                                      children: [
                                        _PlayerOption(
                                          label: '+10 Min',
                                          symbol: SanctuarySymbol.clock,
                                          scale: s,
                                          buttonKey: const ValueKey(
                                            'extend-guided-session',
                                          ),
                                          onPressed: () =>
                                              app.extendGuidedSession(10),
                                        ),
                                        _PlayerOption(
                                          label: app.isGuidedLooping
                                              ? 'Loop On'
                                              : 'Loop Off',
                                          symbol: SanctuarySymbol.loop,
                                          selected: app.isGuidedLooping,
                                          scale: s,
                                          buttonKey: const ValueKey(
                                            'loop-guided-session',
                                          ),
                                          onPressed: loading
                                              ? null
                                              : app.toggleGuidedLoop,
                                        ),
                                        _PlayerOption(
                                          label: 'Restart',
                                          symbol: SanctuarySymbol.restart,
                                          scale: s,
                                          buttonKey: const ValueKey(
                                            'restart-guided-session',
                                          ),
                                          onPressed: app.canSeekGuidedSession
                                              ? app.restartGuidedSession
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 24 * s),
                                  child: Semantics(
                                    label: 'Complete and end session',
                                    button: true,
                                    child: CupertinoButton(
                                      key: const ValueKey(
                                        'complete-guided-session',
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => app.stopGuidedSession(
                                        completed: true,
                                      ),
                                      child: _PlayerGlass(
                                        radius: 25 * s,
                                        child: Padding(
                                          padding: EdgeInsets.all(16 * s),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(9 * s),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF16CDA9),
                                                ),
                                                child: SanctuaryIcon(
                                                  SanctuarySymbol.check,
                                                  size: 22 * s,
                                                  color: _pearl,
                                                ),
                                              ),
                                              SizedBox(width: 14 * s),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Complete & End Session',
                                                      style: _type(
                                                        15 * s,
                                                        weight: FontWeight.w600,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4 * s),
                                                    Text(
                                                      'Take this little moment of calm with you.',
                                                      style: _type(
                                                        math.max(11, 11.5 * s),
                                                        color: _mist,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8 * s),
                                              SanctuaryIcon(
                                                SanctuarySymbol.arrowRight,
                                                size: 23 * s,
                                                color: _mist,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _type(
  double size, {
  Color color = _pearl,
  FontWeight weight = FontWeight.w400,
  double height = 1.25,
  double tracking = 0,
}) => TextStyle(
  fontFamily: 'MixerSans',
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: tracking,
  decoration: TextDecoration.none,
  shadows: const [Shadow(color: Color(0x33051520), blurRadius: 12)],
);

class _BreathingArtwork extends StatelessWidget {
  const _BreathingArtwork({
    required this.size,
    required this.scale,
    required this.pulse,
    required this.artwork,
  });
  final double size, scale, pulse;
  final String artwork;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: size + 32 * scale,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (final factor in const [1.02, 1.15, 1.28])
          Transform.scale(
            scale: 1 + pulse * 0.025,
            child: Container(
              width: size * factor,
              height: size * factor,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromRGBO(
                    211,
                    255,
                    243,
                    0.15 - (factor - 1) * 0.24,
                  ),
                ),
                boxShadow: factor == 1.02
                    ? [
                        BoxShadow(
                          color: _mint.withOpacity(0.08 + pulse * 0.06),
                          blurRadius: 44,
                          spreadRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        Container(
          key: const ValueKey('player-artwork-frame'),
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28 * scale),
            border: Border.all(color: const Color(0xB3F3FFF8), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77051929),
                blurRadius: 35,
                offset: Offset(0, 17),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                artwork,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              Positioned(
                top: 12 * scale,
                right: 12 * scale,
                child: _PlayerGlass(
                  radius: 100,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 6 * scale,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SanctuaryIcon(
                          SanctuarySymbol.leaf,
                          size: 13 * scale,
                          color: _mint,
                        ),
                        SizedBox(width: 5 * scale),
                        Text(
                          'Relax',
                          style: _type(10 * scale, weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlayerGlass extends StatelessWidget {
  const _PlayerGlass({
    required this.child,
    this.radius = 100,
    this.selected = false,
  });
  final Widget child;
  final double radius;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected ? _mint.withOpacity(0.7) : const Color(0x66C8E0E8),
      ),
      boxShadow: selected
          ? const [BoxShadow(color: Color(0x333BEAC8), blurRadius: 18)]
          : null,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? const [Color(0x99257575), Color(0xA80B484F)]
                  : const [Color(0x774C6478), Color(0x9910253B)],
            ),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.label,
    required this.symbol,
    required this.size,
    required this.onPressed,
    this.buttonKey,
  });
  final String label;
  final SanctuarySymbol symbol;
  final double size;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: CupertinoButton(
      key: buttonKey,
      padding: EdgeInsets.zero,
      minSize: 44,
      onPressed: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: _PlayerGlass(
          child: SizedBox.square(
            dimension: math.max(40, size),
            child: Center(
              child: SanctuaryIcon(symbol, size: size * 0.48, color: _pearl),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SeekControl extends StatelessWidget {
  const _SeekControl({
    required this.label,
    required this.caption,
    required this.symbol,
    required this.scale,
    required this.onPressed,
    required this.buttonKey,
  });
  final String label, caption;
  final SanctuarySymbol symbol;
  final double scale;
  final VoidCallback? onPressed;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _CircleControl(
        label: label,
        symbol: symbol,
        size: 44 * scale,
        onPressed: onPressed,
        buttonKey: buttonKey,
      ),
      SizedBox(height: 5 * scale),
      Text(caption, style: _type(math.max(10, 10 * scale), color: _mist)),
    ],
  );
}

class _PlayerOption extends StatelessWidget {
  const _PlayerOption({
    required this.label,
    required this.symbol,
    required this.scale,
    required this.onPressed,
    required this.buttonKey,
    this.selected = false,
  });
  final String label;
  final SanctuarySymbol symbol;
  final double scale;
  final VoidCallback? onPressed;
  final Key buttonKey;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    toggled: symbol == SanctuarySymbol.loop ? selected : null,
    child: CupertinoButton(
      key: buttonKey,
      padding: EdgeInsets.zero,
      minSize: 44,
      onPressed: onPressed,
      child: _PlayerGlass(
        selected: selected,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 13 * scale,
            vertical: 11 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SanctuaryIcon(
                symbol,
                size: 17 * scale,
                color: selected ? _mint : _mist,
              ),
              SizedBox(width: 7 * scale),
              Text(label, style: _type(12 * scale, weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    ),
  );
}
