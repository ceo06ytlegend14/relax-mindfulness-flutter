import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  String _selectedIntent = 'All';

  static const _intentIcons = [
    CupertinoIcons.leaf_arrow_circlepath,
    CupertinoIcons.sun_max,
    CupertinoIcons.sunrise,
    CupertinoIcons.moon,
    Icons.spa_outlined,
    CupertinoIcons.heart,
  ];

  void _toggleSession(MeditationSession session) {
    HapticFeedback.lightImpact();
    final app = context.read<AppState>();
    if (app.isGuidedPlaying && app.currentGuidedTitle == session.title) {
      app.pauseGuidedSession();
    } else {
      app.playGuidedSession(session.title, session.minutes);
    }
  }

  Future<void> _showSessionActions(MeditationSession session) async {
    final app = context.read<AppState>();
    final saved = app.isFavoriteSoundId(session.favoriteId);
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(session.title),
        message: Text('${session.minutes} min · ${session.intent}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'play'),
            child: const Text('Begin session'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(saved ? 'Remove saved practice' : 'Save practice'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'copy'),
            child: const Text('Copy session details'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'play') {
      _toggleSession(session);
    } else if (action == 'save') {
      app.toggleFavorite(session.favoriteId);
    } else if (action == 'copy') {
      await Clipboard.setData(
        ClipboardData(
          text:
              '${session.title} · ${session.minutes} min\n${session.description}\nSanctuary — Meditate',
        ),
      );
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Session details copied'),
          content: const Text(
            'Share a little calm with someone you care about.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final filtered = meditationSessions
        .where(
          (session) =>
              _selectedIntent == 'All' || session.intent == _selectedIntent,
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = SanctuaryMetrics(constraints.maxWidth);
        return CupertinoPageScaffold(
          backgroundColor: SanctuaryPalette.forest,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SanctuaryBackdrop(
                  asset: 'assets/images/meditate/forest_sunrise.webp',
                  color: SanctuaryPalette.forest,
                  height: m.space(650),
                  darkenLeft: true,
                ),
              ),
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  key: const PageStorageKey('meditation-scroll'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        m.space(32),
                        m.space(70),
                        m.space(32),
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Meditate',
                                    key: const ValueKey('meditation-title'),
                                    style: m.serif(72, min: 38),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: m.space(3)),
                                  child: Icon(
                                    Icons.spa_outlined,
                                    size: math.max(24.0, m.space(43)),
                                    color: SanctuaryPalette.mint,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: m.space(10)),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: m.space(515),
                              ),
                              child: Text(
                                'Search by how you feel — curated practices for your emotional state.',
                                style: m.sans(
                                  22,
                                  color: SanctuaryPalette.cream,
                                  min: 12,
                                ),
                              ),
                            ),
                            SizedBox(height: m.space(20)),
                            _DailyJourney(
                              metrics: m,
                              playing:
                                  app.isGuidedPlaying &&
                                  app.currentGuidedTitle ==
                                      dailyMeditation.title,
                              onPressed: () => _toggleSession(dailyMeditation),
                              onLongPress: () =>
                                  _showSessionActions(dailyMeditation),
                            ),
                            SizedBox(height: m.space(22)),
                            Row(
                              children: [
                                Icon(
                                  Icons.spa_outlined,
                                  size: m.font(27, min: 17),
                                  color: SanctuaryPalette.mint,
                                ),
                                SizedBox(width: m.space(12)),
                                Expanded(
                                  child: Text(
                                    'BROWSE BY EMOTIONAL INTENT',
                                    style: m.sans(
                                      15,
                                      min: 9.5,
                                      color: SanctuaryPalette.mint,
                                      weight: FontWeight.w600,
                                      tracking: 2.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: m.space(8)),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  for (
                                    var i = 0;
                                    i < meditationIntents.length;
                                    i++
                                  )
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: i == meditationIntents.length - 1
                                            ? 0
                                            : m.space(10),
                                      ),
                                      child: _IntentChip(
                                        label: meditationIntents[i],
                                        icon: _intentIcons[i],
                                        selected:
                                            _selectedIntent ==
                                            meditationIntents[i],
                                        metrics: m,
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(
                                            () => _selectedIntent =
                                                meditationIntents[i],
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: m.space(12)),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: m.space(32)),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final session = filtered[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: m.space(20)),
                            child: _PracticeCard(
                              key: ValueKey('practice-${session.id}'),
                              session: session,
                              metrics: m,
                              saved: app.isFavoriteSoundId(session.favoriteId),
                              playing:
                                  app.isGuidedPlaying &&
                                  app.currentGuidedTitle == session.title,
                              onPressed: () => _toggleSession(session),
                              onLongPress: () => _showSessionActions(session),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          m.space(32),
                          m.space(6),
                          m.space(32),
                          130,
                        ),
                        child: Text(
                          'A little space to breathe. A moment just for you.',
                          textAlign: TextAlign.center,
                          style: m.sans(18, color: SanctuaryPalette.sage),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DailyJourney extends StatelessWidget {
  const _DailyJourney({
    required this.metrics,
    required this.playing,
    required this.onPressed,
    required this.onLongPress,
  });
  final SanctuaryMetrics metrics;
  final bool playing;
  final VoidCallback onPressed, onLongPress;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Semantics(
      hint: 'Long press for practice options',
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          key: const ValueKey('daily-journey'),
          padding: EdgeInsets.all(m.space(14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(m.space(25)),
            gradient: const LinearGradient(
              colors: [Color(0xEB113B30), Color(0xD002201B)],
            ),
            border: Border.all(color: SanctuaryPalette.sage.withOpacity(0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(m.space(20)),
                child: Image.asset(
                  dailyMeditation.artwork,
                  width: m.space(164),
                  height: m.space(174),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              SizedBox(width: m.space(22)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dailyMeditation.eyebrow,
                      style: m.sans(
                        15,
                        min: 9,
                        weight: FontWeight.w600,
                        tracking: 2,
                        color: SanctuaryPalette.mint,
                      ),
                    ),
                    SizedBox(height: m.space(6)),
                    Text(dailyMeditation.title, style: m.serif(37, min: 20)),
                    SizedBox(height: m.space(8)),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: m.font(20, min: 12),
                          color: SanctuaryPalette.sage,
                        ),
                        SizedBox(width: m.space(7)),
                        Expanded(
                          child: Text(
                            '10 Min  ·  Deep Relaxation',
                            style: m.sans(
                              19,
                              min: 10.5,
                              color: SanctuaryPalette.sage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: m.space(10)),
                    SanctuaryPillButton(
                      buttonKey: const ValueKey('begin-daily-journey'),
                      label: playing ? 'Pause Session' : 'Begin Session',
                      semanticLabel:
                          '${playing ? 'Pause' : 'Begin'} ${dailyMeditation.title}',
                      trailingIcon: playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.arrow_right,
                      metrics: m,
                      onPressed: onPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentChip extends StatelessWidget {
  const _IntentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.metrics,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final SanctuaryMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final color = selected ? const Color(0xFF002B26) : SanctuaryPalette.cream;
    return Semantics(
      selected: selected,
      child: CupertinoButton(
        key: ValueKey('intent-$label'),
        padding: EdgeInsets.symmetric(vertical: m.space(3)),
        minSize: 44,
        onPressed: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: m.space(label == 'All' ? 22 : 13),
            vertical: m.space(12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: selected
                  ? const [SanctuaryPalette.mintLight, SanctuaryPalette.mint]
                  : const [Color(0xC01B3D31), Color(0xB00C3028)],
            ),
            border: Border.all(
              color: selected
                  ? SanctuaryPalette.mintLight
                  : SanctuaryPalette.sage.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: m.font(25, min: 16), color: color),
              SizedBox(width: m.space(10)),
              Text(
                label,
                style: m.sans(
                  18,
                  min: 11.5,
                  color: color,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.session,
    required this.metrics,
    required this.saved,
    required this.playing,
    required this.onPressed,
    required this.onLongPress,
    super.key,
  });
  final MeditationSession session;
  final SanctuaryMetrics metrics;
  final bool saved, playing;
  final VoidCallback onPressed, onLongPress;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Semantics(
      hint: 'Long press to save this practice or copy its details',
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SanctuaryPalette.forestSurface,
            borderRadius: BorderRadius.circular(m.space(23)),
            border: Border.all(
              color: playing
                  ? SanctuaryPalette.mint
                  : SanctuaryPalette.sage.withOpacity(0.4),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: m.space(196)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    session.backdrop,
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
                          const Color(0xFF062B23),
                          const Color(0xD0083028),
                          const Color(0x55001B16),
                        ],
                        stops: const [0.2, 0.57, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: m.space(180),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(m.space(22)),
                    child: Image.asset(
                      session.artwork,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    m.space(208),
                    m.space(18),
                    m.space(18),
                    m.space(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.eyebrow,
                              style: m.sans(
                                14,
                                min: 9,
                                color: SanctuaryPalette.mint,
                                tracking: 2,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (saved)
                            Icon(
                              CupertinoIcons.heart_fill,
                              color: SanctuaryPalette.mint,
                              size: m.font(18, min: 12),
                              semanticLabel: 'Saved practice',
                            ),
                        ],
                      ),
                      SizedBox(height: m.space(7)),
                      Text(session.title, style: m.serif(32)),
                      SizedBox(height: m.space(7)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: m.space(365)),
                        child: Text(
                          session.description,
                          style: m.sans(
                            19,
                            min: 11.5,
                            color: const Color(0xFFD9E5DD),
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: m.space(4)),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: m.space(12),
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: m.font(19, min: 12),
                                  color: SanctuaryPalette.sage,
                                ),
                                SizedBox(width: m.space(7)),
                                Text(
                                  '${session.minutes} min  ·  Guided Session',
                                  style: m.sans(
                                    17,
                                    min: 10,
                                    color: SanctuaryPalette.sage,
                                  ),
                                ),
                              ],
                            ),
                            SanctuaryPillButton(
                              buttonKey: ValueKey('begin-${session.id}'),
                              label: playing ? 'Pause' : 'Begin',
                              semanticLabel:
                                  '${playing ? 'Pause' : 'Begin'} ${session.title}',
                              trailingIcon: playing
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.arrow_right,
                              metrics: m,
                              onPressed: onPressed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
