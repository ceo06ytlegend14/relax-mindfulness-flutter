import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/wellbeing_screen.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// A daily dashboard, not a second copy of the Sounds mixer. Playback uses the
/// same selection/controller as Sounds; arriving here never starts audio.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  void _dailySession(AppState app) {
    HapticFeedback.lightImpact();
    if (app.isGuidedPlaying &&
        app.currentGuidedTitle == dailyMeditation.title) {
      app.pauseGuidedSession();
    } else {
      app.playGuidedSession(dailyMeditation.title, dailyMeditation.minutes);
    }
  }

  void _toggleSoundscape(AppState app, MixerController mixer) {
    HapticFeedback.lightImpact();
    if (app.hasAmbientPlaybackRequest) {
      mixer.togglePlayback();
    } else {
      final selected = Map<String, double>.of(mixer.levels)
        ..removeWhere((_, volume) => volume <= 0);
      mixer.applyMix(
        selected.isEmpty ? {'Soft Rain': 0.3} : selected,
        name: mixer.preset,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Consumer2<AppState, MixerController>(
    builder: (context, app, mixer, _) => LayoutBuilder(
      builder: (context, constraints) {
        final m = MixerMetrics(constraints.maxWidth);
        final dailyPlaying =
            app.isGuidedPlaying &&
            app.currentGuidedTitle == dailyMeditation.title;
        return CupertinoPageScaffold(
          backgroundColor: MixerTheme.background,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/mixer/moonlit_forest.webp',
                  fit: BoxFit.fitWidth,
                  excludeFromSemantics: true,
                ),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  key: const PageStorageKey('home-dashboard-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    m.space(29),
                    m.space(36),
                    m.space(29),
                    MediaQuery.paddingOf(context).bottom +
                        (app.hasGuidedSession ||
                                app.hasAmbientSession ||
                                app.hasAmbientPlaybackRequest
                            ? 130
                            : 36),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home',
                        key: const ValueKey('home-title'),
                        style: m.text(53, weight: FontWeight.w700),
                      ),
                      SizedBox(height: m.space(34)),
                      Text(
                        _greeting(),
                        style: m.text(23, color: MixerTheme.mintLight),
                      ),
                      SizedBox(height: m.space(8)),
                      Text(
                        'A little calm,\njust for you.',
                        style: m
                            .text(68, weight: FontWeight.w600, height: 1.02)
                            .copyWith(fontFamily: 'SanctuarySerif'),
                      ),
                      SizedBox(height: m.space(14)),
                      Text(
                        'Your daily space to breathe, listen, and unwind.',
                        style: m.text(23, color: MixerTheme.muted, height: 1.4),
                      ),
                      SizedBox(height: m.space(28)),
                      _DailyHomeCard(
                        metrics: m,
                        playing: dailyPlaying,
                        resumable:
                            app.currentGuidedTitle == dailyMeditation.title,
                        onPressed: () => _dailySession(app),
                      ),
                      SizedBox(height: m.space(30)),
                      _HomeSectionHeading('MAKE IT YOUR MOMENT', metrics: m),
                      SizedBox(height: m.space(16)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final action in const [
                            (
                              AppTab.sounds,
                              SanctuarySymbol.sounds,
                              'Sounds',
                              'Build a mix',
                            ),
                            (
                              AppTab.meditate,
                              SanctuarySymbol.meditate,
                              'Meditate',
                              'Find your focus',
                            ),
                            (
                              AppTab.sleep,
                              SanctuarySymbol.sleep,
                              'Sleep',
                              'Ease into rest',
                            ),
                          ]) ...[
                            if (action.$1 != AppTab.sounds)
                              SizedBox(width: m.space(14)),
                            Expanded(
                              child: _HomeAction(
                                metrics: m,
                                symbol: action.$2,
                                label: action.$3,
                                detail: action.$4,
                                onPressed: () => app.setTab(action.$1),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: m.space(30)),
                      _HomeSectionHeading('YOUR SOUNDSCAPE', metrics: m),
                      SizedBox(height: m.space(16)),
                      _HomeSoundscape(
                        app: app,
                        mixer: mixer,
                        metrics: m,
                        onToggle: () => _toggleSoundscape(app, mixer),
                        onOpen: () => app.setTab(AppTab.sounds),
                      ),
                      SizedBox(height: m.space(24)),
                      CupertinoButton(
                        key: const ValueKey('home-wellbeing'),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => const WellbeingScreen(),
                          ),
                        ),
                        child: _HomeSurface(
                          key: const ValueKey('home-surface-wellbeing'),
                          metrics: m,
                          color: _HomeStyle.quiet,
                          padding: EdgeInsets.all(m.space(22)),
                          child: Row(
                            children: [
                              SanctuaryIcon(
                                SanctuarySymbol.leaf,
                                size: math.max(26.0, m.space(38)),
                                color: MixerTheme.mintLight,
                              ),
                              SizedBox(width: m.space(18)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your wellbeing',
                                      style: m.text(
                                        25,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: m.space(4)),
                                    Text(
                                      'Breathing, progress & backup',
                                      style: m.text(
                                        22,
                                        color: MixerTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SanctuaryIcon(
                                SanctuarySymbol.arrowRight,
                                size: m.font(26),
                                color: MixerTheme.mint,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: m.space(26)),
                      Center(
                        child: Text(
                          'No rush. Your quiet moment is here.',
                          style: m.text(21, color: MixerTheme.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// Home-only matte surfaces. The outlined MixerSurface and the preferred Sleep
// controls deliberately keep their own styling; these tokens match home.css.
abstract final class _HomeStyle {
  static const surface = Color(0xFF0A3039);
  static const action = Color(0xFF082C35);
  static const quiet = Color(0xFF062831);
  static const control = Color(0xFF164D51);
  static const primary = Color(0xFF8CE7D0);
  static const section = Color(0xFF95BBB7);
}

class _HomeSurface extends StatelessWidget {
  const _HomeSurface({
    required this.child,
    required this.metrics,
    required this.padding,
    this.color = _HomeStyle.surface,
    super.key,
  });

  final Widget child;
  final MixerMetrics metrics;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(metrics.space(26)),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _HomeSectionHeading extends StatelessWidget {
  const _HomeSectionHeading(this.label, {required this.metrics});
  final String label;
  final MixerMetrics metrics;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      label,
      style: metrics.text(
        17,
        color: _HomeStyle.section,
        weight: FontWeight.w600,
        tracking: metrics.space(2.5),
      ),
    ),
  );
}

class _DailyHomeCard extends StatelessWidget {
  const _DailyHomeCard({
    required this.metrics,
    required this.playing,
    required this.resumable,
    required this.onPressed,
  });
  final MixerMetrics metrics;
  final bool playing, resumable;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return ClipRRect(
      borderRadius: BorderRadius.circular(math.max(18.0, m.space(28))),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              dailyMeditation.backdrop,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF06363C),
                    const Color(0xF006363C),
                    const Color(0x38002530),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(m.space(28)),
            child: FractionallySizedBox(
              widthFactor: 0.7,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY’S AMBIENT PRACTICE',
                    style: m.text(
                      16,
                      weight: FontWeight.w600,
                      color: MixerTheme.mintLight,
                      tracking: m.space(1.5),
                    ),
                  ),
                  SizedBox(height: m.space(14)),
                  Text(
                    dailyMeditation.title,
                    style: m
                        .text(44, weight: FontWeight.w600, height: 1.05)
                        .copyWith(fontFamily: 'SanctuarySerif'),
                  ),
                  SizedBox(height: m.space(12)),
                  Row(
                    children: [
                      SanctuaryIcon(
                        SanctuarySymbol.clock,
                        size: m.font(22),
                        color: MixerTheme.muted,
                      ),
                      SizedBox(width: m.space(8)),
                      Expanded(
                        child: Text(
                          '${dailyMeditation.minutes} min · ${dailyMeditation.description}',
                          style: m.text(22, color: const Color(0xFFC6DEDC)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: m.space(10)),
                  Text(
                    '${dailyMeditation.sourceLabel}\nAmbient mix · No narration',
                    key: const ValueKey('home-daily-sources'),
                    style: m.text(
                      19,
                      color: const Color(0xFFC6DEDC),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: m.space(16)),
                  _HomePill(
                    buttonKey: const ValueKey('home-daily'),
                    metrics: m,
                    label: playing
                        ? 'Pause session'
                        : resumable
                        ? 'Resume session'
                        : 'Begin session',
                    symbol: playing
                        ? SanctuarySymbol.pause
                        : SanctuarySymbol.play,
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.metrics,
    required this.symbol,
    required this.label,
    required this.detail,
    required this.onPressed,
  });
  final MixerMetrics metrics;
  final SanctuarySymbol symbol;
  final String label, detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return CupertinoButton(
      key: ValueKey('home-open-${label.toLowerCase()}'),
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: _HomeSurface(
        key: ValueKey('home-surface-${label.toLowerCase()}'),
        metrics: m,
        color: _HomeStyle.action,
        padding: EdgeInsets.symmetric(
          horizontal: m.space(8),
          vertical: m.space(23),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SanctuaryIcon(
                symbol,
                size: math.max(27.0, m.space(43)),
                color: MixerTheme.mintLight,
              ),
              SizedBox(height: m.space(14)),
              Text(label, style: m.text(25, weight: FontWeight.w600)),
              SizedBox(height: m.space(6)),
              Text(
                detail,
                style: m.text(19, color: MixerTheme.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSoundscape extends StatelessWidget {
  const _HomeSoundscape({
    required this.app,
    required this.mixer,
    required this.metrics,
    required this.onToggle,
    required this.onOpen,
  });
  final AppState app;
  final MixerController mixer;
  final MixerMetrics metrics;
  final VoidCallback onToggle, onOpen;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final selected =
        mixer.levels.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final first = selected.isEmpty ? null : selected.first.key;
    final title =
        mixer.preset ??
        (first == null
            ? 'A fresh soundscape'
            : selected.length == 1
            ? first
            : '$first + ${selected.length - 1} more');
    final active = mixer.isPlaying;
    final preparing = mixer.isPreparing;
    final track = allMixerTracks.where((track) => track.name == first);
    final artwork = track.isEmpty ? null : track.first.artwork;
    return _HomeSurface(
      key: const ValueKey('home-surface-soundscape'),
      metrics: m,
      padding: EdgeInsets.all(m.space(22)),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(m.space(16)),
                child: Image.asset(
                  artwork ?? 'assets/images/sleep/continue_listening.webp',
                  width: m.space(104),
                  height: m.space(104),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              SizedBox(width: m.space(20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      key: const ValueKey('home-mix-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: m.text(30, weight: FontWeight.w600),
                    ),
                    SizedBox(height: m.space(6)),
                    Text(
                      mixer.playbackStatusLabel,
                      key: const ValueKey('home-mix-status'),
                      style: m.text(21, color: MixerTheme.muted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: m.space(12)),
              CupertinoButton(
                key: const ValueKey('home-mix-toggle'),
                padding: EdgeInsets.zero,
                onPressed: onToggle,
                child: Semantics(
                  label: mixer.transportLabel,
                  child: Container(
                    width: math.max(44.0, m.space(64)),
                    height: math.max(44.0, m.space(64)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _HomeStyle.control,
                    ),
                    alignment: Alignment.center,
                    child: SanctuaryIcon(
                      preparing
                          ? SanctuarySymbol.close
                          : active
                          ? SanctuarySymbol.pause
                          : SanctuarySymbol.play,
                      size: m.font(31),
                      color: MixerTheme.mintLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: m.space(10)),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              key: const ValueKey('home-edit-mix'),
              padding: EdgeInsets.zero,
              onPressed: onOpen,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open sound mixer',
                    style: m.text(
                      22,
                      color: MixerTheme.mintLight,
                      weight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: m.space(12)),
                  SanctuaryIcon(
                    SanctuarySymbol.arrowRight,
                    size: m.font(24),
                    color: MixerTheme.mintLight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePill extends StatelessWidget {
  const _HomePill({
    required this.buttonKey,
    required this.metrics,
    required this.label,
    required this.symbol,
    required this.onPressed,
  });
  final Key buttonKey;
  final MixerMetrics metrics;
  final String label;
  final SanctuarySymbol symbol;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: buttonKey,
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.space(22),
        vertical: metrics.space(13),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: _HomeStyle.primary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SanctuaryIcon(
            symbol,
            size: metrics.font(23),
            color: const Color(0xFF004D48),
          ),
          SizedBox(width: metrics.space(10)),
          Flexible(
            child: Text(
              label,
              style: metrics.text(
                23,
                weight: FontWeight.w600,
                color: const Color(0xFF004D48),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
