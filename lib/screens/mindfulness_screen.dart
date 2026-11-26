import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/components/wellbeing_components.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/screens/breathe_screen.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// The legacy route name is kept; its contents are the user's actual activity.
class MindfulnessScreen extends StatefulWidget {
  const MindfulnessScreen({super.key});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen> {
  int _visibleSessions = 12;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sessions = app.sessions.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final week = app.weeklyMinutes;
    final weeklyTotal = week.fold<int>(0, (sum, day) => sum + day.value);
    return WellbeingPage(
      title: 'Your progress',
      scrollKey: const PageStorageKey('progress-scroll'),
      builder: (context, m) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WellbeingEyebrow('SMALL MOMENTS ADD UP'),
          const SizedBox(height: 10),
          Text(
            'Your own pace.\nYour own progress.',
            key: const ValueKey('progress-title'),
            style: m.serif(60, min: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Only recorded practices appear here. Pausing, browsing, and saving a practice do not count as completing one.',
            style: m.sans(21, min: 13, color: MixerTheme.muted, height: 1.5),
          ),
          const SizedBox(height: 26),
          WellbeingSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WellbeingEyebrow('THIS WEEK · MONDAY TO SUNDAY'),
                const SizedBox(height: 12),
                Text(
                  '$weeklyTotal min',
                  key: const ValueKey('progress-weekly-minutes'),
                  style: m.serif(52, min: 36),
                ),
                const SizedBox(height: 24),
                _WeeklyChart(minutes: week),
                const SizedBox(height: 18),
                Text(
                  weeklyTotal == 0
                      ? 'Nothing recorded this week yet. Start whenever you are ready.'
                      : 'A little space you made for yourself this week.',
                  style: m.sans(
                    19,
                    min: 12,
                    color: MixerTheme.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WellbeingSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: WellbeingStat(
                    value: '${app.totalMinutes}',
                    label: 'minutes in saved history',
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: WellbeingStat(
                    value: '${sessions.length}',
                    label: 'recorded sessions',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Your recent moments', style: m.serif(39, min: 26)),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            WellbeingSurface(
              key: const ValueKey('progress-empty'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SanctuaryIcon(
                    SanctuarySymbol.leaf,
                    color: MixerTheme.mint,
                    size: 34,
                  ),
                  const SizedBox(height: 16),
                  Text('A fresh beginning', style: m.serif(32, min: 24)),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a breathing or timed audio practice to begin your history. No sample sessions, no made-up streaks.',
                    style: m.sans(
                      20,
                      min: 13,
                      color: MixerTheme.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    key: const ValueKey('progress-open-breathe'),
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const BreatheScreen(),
                      ),
                    ),
                    child: const Text(
                      'Try a breathing practice',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final session in sessions.take(_visibleSessions))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionTile(session: session, metrics: m),
              ),
            if (sessions.length > _visibleSessions)
              CupertinoButton(
                key: const ValueKey('progress-show-more'),
                onPressed: () => setState(() => _visibleSessions += 12),
                child: Text(
                  'Show more (${sessions.length - _visibleSessions} remaining)',
                ),
              ),
          ],
          const SizedBox(height: 22),
          Text(
            'Saved on this device, not a health score. Back up your data from Your wellbeing if you want to keep a copy.',
            textAlign: TextAlign.center,
            style: m.sans(18, min: 12, color: MixerTheme.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.minutes});
  final List<MapEntry<String, int>> minutes;

  @override
  Widget build(BuildContext context) {
    final maximum = minutes.fold<int>(
      1,
      (max, day) => math.max(max, day.value),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final day in minutes)
          Expanded(
            child: Semantics(
              label: '${day.key}, ${day.value} minutes',
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(
                    '${day.value}',
                    style: const TextStyle(
                      color: MixerTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 92,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        key: ValueKey('progress-bar-${day.key}'),
                        width: 18,
                        height: day.value / maximum * 92,
                        decoration: BoxDecoration(
                          color: MixerTheme.mint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    day.key.substring(0, 1),
                    style: const TextStyle(
                      color: MixerTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.metrics});
  final SessionRecord session;
  final SanctuaryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final symbol = switch (session.type) {
      'Breathing' => SanctuarySymbol.wind,
      'Sleep' => SanctuarySymbol.moon,
      'Meditation' => SanctuarySymbol.meditate,
      _ => SanctuarySymbol.sounds,
    };
    return WellbeingSurface(
      key: ValueKey('progress-session-${session.id}'),
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SanctuaryIcon(symbol, color: MixerTheme.mint, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: metrics.sans(23, min: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  '${session.type} · ${session.durationMinutes} min',
                  style: metrics.sans(19, min: 12, color: MixerTheme.muted),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat(
                    'EEE, MMM d · HH:mm',
                  ).format(session.timestamp.toLocal()),
                  style: metrics.sans(17, min: 11, color: MixerTheme.muted),
                ),
                if (session.moodRating > 0) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Mood check-in: ${session.moodRating} / 5',
                    style: metrics.sans(
                      18,
                      min: 12,
                      color: SanctuaryPalette.mint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
