import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  String _selectedIntent = 'All';
  bool _showAllPractices = false;

  static const _intentSymbols = [
    SanctuarySymbol.leaf,
    SanctuarySymbol.heart,
    SanctuarySymbol.meditate,
    SanctuarySymbol.moon,
    SanctuarySymbol.book,
  ];

  void _toggleSession(MeditationSession session) {
    HapticFeedback.lightImpact();
    final app = context.read<AppState>();
    if (app.isGuidedLoading && app.currentGuidedTitle == session.title) return;
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
        message: Text(
          '${session.minutes} min · Ambient mix\n${session.sourceLabel}\nNo narration',
        ),
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
      var copied = true;
      try {
        await Clipboard.setData(
          ClipboardData(
            text:
                '${session.title} · ${session.minutes} min\n${session.description}\n${session.sourceLabel}\nAmbient mix · No narration · Sanctuary — Meditate',
          ),
        );
      } catch (_) {
        copied = false;
      }
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            copied ? 'Session details copied' : 'Could not copy details',
          ),
          content: Text(
            copied
                ? 'Share a little calm with someone you care about.'
                : 'Clipboard access was unavailable. Your saved practices have not changed.',
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
    final featured = _selectedIntent == 'All' && !_showAllPractices;
    final filtered = featured
        ? [
            for (final id in featuredMeditationIds)
              meditationSessions.firstWhere((session) => session.id == id),
          ]
        : meditationSessions
              .where(
                (session) => meditationMatchesFilter(
                  session,
                  _selectedIntent,
                  app.isFavoriteSoundId(session.favoriteId),
                ),
              )
              .toList();
    return SanctuaryPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = SanctuaryMetrics(constraints.maxWidth);
          final padding = math.max(18.0, m.space(32));
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              key: const PageStorageKey('meditation-scroll'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    math.max(30.0, m.space(54)),
                    padding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meditate',
                          key: const ValueKey('meditation-title'),
                          style: m.serif(72, min: 40),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ambient practice · No spoken guidance.',
                          style: m.sans(
                            18,
                            min: 12,
                            color: MixerTheme.muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _DailyJourney(
                          metrics: m,
                          saved: app.isFavoriteSoundId(
                            dailyMeditation.favoriteId,
                          ),
                          onSave: () =>
                              app.toggleFavorite(dailyMeditation.favoriteId),
                          playing:
                              app.isGuidedPlaying &&
                              app.currentGuidedTitle == dailyMeditation.title,
                          loading:
                              app.isGuidedLoading &&
                              app.currentGuidedTitle == dailyMeditation.title,
                          onPressed: () => _toggleSession(dailyMeditation),
                          onOptions: () => _showSessionActions(dailyMeditation),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              Text(
                                'Find a quiet moment',
                                style: m.serif(39, min: 26),
                              ),
                              Text(
                                '${filtered.length} ${featured
                                    ? 'featured'
                                    : filtered.length == 1
                                    ? 'practice'
                                    : 'practices'}',
                                style: m.sans(
                                  16,
                                  min: 11,
                                  color: MixerTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (
                                var i = 0;
                                i < simpleMeditationFilters.length;
                                i++
                              )
                                Padding(
                                  padding: const EdgeInsets.only(right: 9),
                                  child: _IntentChip(
                                    label: simpleMeditationFilters[i],
                                    symbol: _intentSymbols[i],
                                    selected:
                                        _selectedIntent ==
                                        simpleMeditationFilters[i],
                                    metrics: m,
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _selectedIntent =
                                            simpleMeditationFilters[i],
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Text(
                        'No saved practices in this collection yet. Tap a heart to keep one here.',
                        style: m.sans(21, min: 13, color: MixerTheme.muted),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PracticeCard(
                          key: ValueKey('practice-${session.id}'),
                          session: session,
                          metrics: m,
                          saved: app.isFavoriteSoundId(session.favoriteId),
                          playing:
                              app.isGuidedPlaying &&
                              app.currentGuidedTitle == session.title,
                          loading:
                              app.isGuidedLoading &&
                              app.currentGuidedTitle == session.title,
                          onPressed: () => _toggleSession(session),
                          onSave: () => app.toggleFavorite(session.favoriteId),
                          onOptions: () => _showSessionActions(session),
                        ),
                      );
                    }, childCount: filtered.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: CupertinoButton(
                      key: const ValueKey('browse-practices'),
                      onPressed: () => setState(() {
                        _showAllPractices =
                            _selectedIntent != 'All' || !_showAllPractices;
                        _selectedIntent = 'All';
                      }),
                      child: Text(
                        _selectedIntent == 'All' && _showAllPractices
                            ? 'Show featured practices'
                            : 'Browse all ${meditationSessions.length} practices',
                        style: m.sans(22, min: 13, color: MixerTheme.mintLight),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      12,
                      padding,
                      MediaQuery.paddingOf(context).bottom +
                          (app.hasGuidedSession ||
                                  app.hasAmbientSession ||
                                  app.hasAmbientPlaybackRequest
                              ? 130
                              : 40),
                    ),
                    child: Text(
                      'A little space to breathe. A moment just for you.\n\nEach practice repeats an approximately 30-second mix of existing library recordings. Names and artwork are themes, not narration, verified frequency tuning or medical claims.',
                      textAlign: TextAlign.center,
                      style: m.sans(
                        19,
                        min: 12,
                        color: MixerTheme.muted,
                        height: 1.6,
                      ),
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
}

Color _intentColor(String intent) => switch (intent) {
  'Morning' => const Color(0xFFF5C998),
  'Sleep' => const Color(0xFFB9B8F1),
  'Focus' => const Color(0xFF9AD1EE),
  'Healing' => const Color(0xFFE5BACF),
  _ => MixerTheme.mintLight,
};

/// The featured moment has its own editorial hierarchy. It is not a large
/// version of every library row, and all copy remains free to wrap and grow.
class _DailyJourney extends StatelessWidget {
  const _DailyJourney({
    required this.metrics,
    required this.playing,
    required this.loading,
    required this.onPressed,
    required this.onOptions,
    required this.saved,
    required this.onSave,
  });
  final SanctuaryMetrics metrics;
  final bool playing, loading, saved;
  final VoidCallback onPressed, onOptions, onSave;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final narrow = m.scale <= 360 / MixerTheme.maxWidth;
    return GestureDetector(
      onLongPress: onOptions,
      child: Container(
        key: const ValueKey('daily-journey'),
        padding: EdgeInsets.all(math.max(18.0, m.space(30))),
        decoration: BoxDecoration(
          color: MixerTheme.surfaceActive,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(26),
            topRight: Radius.circular(narrow ? 46 : 64),
            bottomLeft: const Radius.circular(26),
            bottomRight: const Radius.circular(26),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          CupertinoIcons.sunrise,
                          size: 19,
                          color: Color(0xFFE1D6B3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'TODAY’S QUIET MOMENT',
                          style: m.sans(
                            15,
                            min: 10,
                            color: const Color(0xFFE1D6B3),
                            tracking: 1.2,
                            weight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: MixerTheme.control,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: _SessionMeta(
                    minutes: dailyMeditation.minutes,
                    metrics: m,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyMeditation.title,
                        style: m.serif(52, min: 30).copyWith(height: 1.03),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dailyMeditation.sourceLabel,
                        key: const ValueKey('daily-session-sources'),
                        style: m.sans(
                          18,
                          min: 12,
                          color: const Color(0xFFC1D8D2),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: narrow ? 12 : 16),
                SizedBox(
                  width: narrow ? 96 : math.max(106.0, m.space(190)),
                  child: _PracticeArt(
                    asset: dailyMeditation.artwork,
                    accent: const Color(0xFFD9CC9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BeginButton(
                    buttonKey: const ValueKey('begin-daily-journey'),
                    label: playing ? 'Pause Session' : 'Begin Session',
                    title: dailyMeditation.title,
                    playing: playing,
                    loading: loading,
                    onPressed: onPressed,
                    metrics: m,
                  ),
                ),
                const SizedBox(width: 10),
                _PracticeSaveButton(
                  buttonKey: const ValueKey('daily-practice-save'),
                  title: dailyMeditation.title,
                  saved: saved,
                  onPressed: onSave,
                  filled: true,
                ),
                const SizedBox(width: 10),
                _OptionsButton(
                  buttonKey: const ValueKey('daily-practice-options'),
                  title: dailyMeditation.title,
                  onPressed: onOptions,
                  filled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentChip extends StatelessWidget {
  const _IntentChip({
    required this.label,
    required this.symbol,
    required this.selected,
    required this.metrics,
    required this.onPressed,
  });
  final String label;
  final SanctuarySymbol symbol;
  final bool selected;
  final SanctuaryMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: CupertinoButton(
      key: ValueKey('intent-$label'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? MixerTheme.primary : MixerTheme.action,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SanctuaryIcon(
              symbol,
              size: 17,
              color: selected ? MixerTheme.onPrimary : MixerTheme.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label == 'Healing' ? 'Self-care' : label,
              style: metrics
                  .sans(
                    19,
                    min: 12,
                    color: selected ? MixerTheme.onPrimary : MixerTheme.text,
                    weight: FontWeight.w600,
                  )
                  .copyWith(
                    decoration: selected
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationThickness: 2,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A compact art-first library row. On narrow phones the toolbar gets the full
/// width; neither layout truncates a title or shrinks the controls to make room.
class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.session,
    required this.metrics,
    required this.saved,
    required this.playing,
    required this.loading,
    required this.onPressed,
    required this.onOptions,
    required this.onSave,
    super.key,
  });
  final MeditationSession session;
  final SanctuaryMetrics metrics;
  final bool saved, playing, loading;
  final VoidCallback onPressed, onOptions, onSave;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final accent = _intentColor(session.intent);
    Widget actions() => Row(
      children: [
        Expanded(
          child: _SessionMeta(minutes: session.minutes, metrics: m),
        ),
        const SizedBox(width: 4),
        _PracticeSaveButton(
          buttonKey: ValueKey('save-practice-${session.id}'),
          title: session.title,
          saved: saved,
          onPressed: onSave,
        ),
        const SizedBox(width: 4),
        _OptionsButton(
          buttonKey: ValueKey('practice-options-${session.id}'),
          title: session.title,
          onPressed: onOptions,
        ),
        const SizedBox(width: 4),
        _BeginButton(
          buttonKey: ValueKey('begin-${session.id}'),
          label: playing ? 'Pause' : 'Begin',
          title: session.title,
          playing: playing,
          loading: loading,
          onPressed: onPressed,
          metrics: m,
          iconOnly: true,
        ),
      ],
    );
    return Semantics(
      hint: 'Long press for save and copy options, or use the options button',
      child: GestureDetector(
        onLongPress: onOptions,
        child: Container(
          padding: EdgeInsets.all(math.max(14.0, m.space(22))),
          decoration: BoxDecoration(
            color: playing ? MixerTheme.surfaceActive : MixerTheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 300;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: math.max(68.0, m.space(128)),
                        child: _PracticeArt(
                          asset: session.artwork,
                          accent: accent,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              session.title,
                              style: m
                                  .serif(39, min: 23)
                                  .copyWith(height: 1.08),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.sourceLabel,
                              key: ValueKey('practice-sources-${session.id}'),
                              style: m.sans(
                                18,
                                min: 12,
                                color: accent,
                                height: 1.45,
                              ),
                            ),
                            if (!narrow) ...[
                              const SizedBox(height: 6),
                              actions(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (narrow) ...[const SizedBox(height: 8), actions()],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SessionMeta extends StatelessWidget {
  const _SessionMeta({required this.minutes, required this.metrics});
  final int minutes;
  final SanctuaryMetrics metrics;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SanctuaryIcon(
        SanctuarySymbol.clock,
        size: 15,
        color: MixerTheme.muted,
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          '$minutes min',
          style: metrics.sans(18, min: 12, color: MixerTheme.muted),
        ),
      ),
    ],
  );
}

class _BeginButton extends StatelessWidget {
  const _BeginButton({
    required this.buttonKey,
    required this.label,
    required this.title,
    required this.playing,
    required this.loading,
    required this.onPressed,
    required this.metrics,
    this.iconOnly = false,
  });
  final Key buttonKey;
  final String label, title;
  final bool playing, loading;
  final bool iconOnly;
  final VoidCallback onPressed;
  final SanctuaryMetrics metrics;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${loading
            ? 'Opening'
            : playing
            ? 'Pause'
            : 'Begin'} $title',
    button: true,
    enabled: !loading,
    excludeSemantics: true,
    onTap: loading ? null : onPressed,
    child: CupertinoButton(
      key: buttonKey,
      padding: EdgeInsets.zero,
      onPressed: loading ? null : onPressed,
      child: Container(
        width: iconOnly ? 44 : null,
        height: iconOnly ? 44 : null,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: iconOnly
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: BoxDecoration(
          color: MixerTheme.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const CupertinoActivityIndicator(
                radius: 8,
                color: MixerTheme.background,
              )
            else
              SanctuaryIcon(
                playing ? SanctuarySymbol.pause : SanctuarySymbol.play,
                size: iconOnly ? 18 : 16,
                color: MixerTheme.onPrimary,
              ),
            if (!iconOnly) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  loading ? 'Opening…' : label,
                  textAlign: TextAlign.center,
                  style: metrics.sans(
                    22,
                    min: 13,
                    color: MixerTheme.onPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _PracticeSaveButton extends StatelessWidget {
  const _PracticeSaveButton({
    required this.buttonKey,
    required this.title,
    required this.saved,
    required this.onPressed,
    this.filled = false,
  });
  final Key buttonKey;
  final String title;
  final bool saved, filled;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${saved ? 'Unsave' : 'Save'} $title',
    button: true,
    selected: saved,
    child: CupertinoButton(
      key: buttonKey,
      padding: EdgeInsets.zero,
      minSize: 44,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: filled
            ? const BoxDecoration(
                color: MixerTheme.control,
                shape: BoxShape.circle,
              )
            : null,
        child: Center(
          child: SanctuaryIcon(
            saved ? SanctuarySymbol.heartFill : SanctuarySymbol.heart,
            size: 21,
            color: saved
                ? MixerTheme.mintLight
                : filled
                ? const Color(0xFFC1D8D2)
                : MixerTheme.muted,
          ),
        ),
      ),
    ),
  );
}

class _OptionsButton extends StatelessWidget {
  const _OptionsButton({
    required this.buttonKey,
    required this.title,
    required this.onPressed,
    this.filled = false,
  });
  final Key buttonKey;
  final String title;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: buttonKey,
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: Semantics(
      label: 'Options for $title',
      excludeSemantics: true,
      child: Container(
        width: 44,
        height: 44,
        decoration: filled
            ? const BoxDecoration(
                color: MixerTheme.control,
                shape: BoxShape.circle,
              )
            : null,
        child: Center(
          child: Text(
            '···',
            style: TextStyle(
              color: filled ? const Color(0xFFC1D8D2) : MixerTheme.muted,
              fontSize: 25,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ),
  );
}

/// An arched, inset illustration with orbital linework. It never becomes a
/// full-page wallpaper, and is decorative rather than a claim about the audio.
class _PracticeArt extends StatelessWidget {
  const _PracticeArt({
    required this.asset,
    required this.accent,
    this.compact = false,
  });
  final String asset;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 0.92,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _OrbitPainter(accent)),
        Padding(
          padding: compact
              ? const EdgeInsets.fromLTRB(6, 4, 3, 8)
              : const EdgeInsets.fromLTRB(10, 4, 4, 12),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(140),
              topRight: Radius.circular(140),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      -math.pi * 0.92,
      math.pi * 1.65,
      false,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.93),
      3,
      Paint()..color = accent,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.98),
      Offset(size.width * 0.94, size.height * 0.98),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
