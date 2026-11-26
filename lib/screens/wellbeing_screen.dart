import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/components/wellbeing_components.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/screens/ai_studio_screen.dart';
import 'package:relax_mindfulness/screens/breathe_screen.dart';
import 'package:relax_mindfulness/screens/data_backup_screen.dart';
import 'package:relax_mindfulness/screens/mindfulness_screen.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  void _open(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(CupertinoPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final week = app.weeklyMinutes;
    final minutes = week.fold<int>(0, (sum, day) => sum + day.value);
    final days = week.where((day) => day.value > 0).length;
    return WellbeingPage(
      title: 'Your wellbeing',
      scrollKey: const PageStorageKey('wellbeing-scroll'),
      builder: (context, m) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WellbeingEyebrow('A LITTLE CARE, EVERY DAY'),
          const SizedBox(height: 10),
          Text(
            'Small steps.\nMore space for you.',
            key: const ValueKey('wellbeing-title'),
            style: m.serif(66, min: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'A place to find your breath, notice your progress, and keep your quiet moments close.',
            style: m.sans(23, min: 14, color: MixerTheme.muted, height: 1.5),
          ),
          const SizedBox(height: 26),
          WellbeingSurface(
            key: const ValueKey('wellbeing-week'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WellbeingEyebrow('YOUR WEEK, AT YOUR PACE'),
                const SizedBox(height: 18),
                PracticeWeek(minutes: week),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: WellbeingStat(
                        value: '$minutes',
                        label: 'minutes this week',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: WellbeingStat(
                        value: '$days / 7',
                        label: 'days with a recorded practice',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  minutes == 0
                      ? 'A fresh page. Your first completed practice will appear here.'
                      : 'Each completed practice adds to your week. There is no perfect score.',
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
          const SizedBox(height: 18),
          CupertinoButton(
            key: const ValueKey('wellbeing-open-breathe'),
            padding: EdgeInsets.zero,
            onPressed: () => _open(context, const BreatheScreen()),
            child: WellbeingSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      SanctuaryIcon(
                        SanctuarySymbol.wind,
                        color: MixerTheme.mint,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(child: WellbeingEyebrow('THE BREATHING ROOM')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Find your rhythm.', style: m.serif(44, min: 28)),
                  const SizedBox(height: 9),
                  Text(
                    'A simple visual timer. Choose a comfortable pace and take it one breath at a time.',
                    style: m.sans(
                      21,
                      min: 13,
                      color: MixerTheme.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Open breathing',
                          style: m.sans(
                            22,
                            min: 14,
                            color: MixerTheme.mint,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SanctuaryIcon(
                        SanctuarySymbol.arrowRight,
                        color: MixerTheme.mint,
                        size: 23,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          const WellbeingEyebrow('YOUR PERSONAL SPACE'),
          const SizedBox(height: 13),
          WellbeingDestination(
            key: const ValueKey('wellbeing-open-progress'),
            title: 'Your progress',
            description: 'Real activity, without the pressure',
            symbol: SanctuarySymbol.sounds,
            onPressed: () => _open(context, const MindfulnessScreen()),
          ),
          const SizedBox(height: 12),
          WellbeingDestination(
            key: const ValueKey('wellbeing-open-reflection'),
            title: 'Reflection studio',
            description: 'Make a little room for your thoughts',
            symbol: SanctuarySymbol.book,
            accent: SanctuaryPalette.lavender,
            onPressed: () => _open(context, const AiStudioScreen()),
          ),
          const SizedBox(height: 12),
          WellbeingDestination(
            key: const ValueKey('open-data-backup'),
            title: 'Backup & restore',
            description: 'Keep a private copy of your saved data',
            symbol: SanctuarySymbol.restart,
            accent: SanctuaryPalette.gold,
            onPressed: () => _open(context, const DataBackupScreen()),
          ),
          const SizedBox(height: 24),
          Text(
            'Yours, on this device. Nothing here is automatically uploaded or synced.',
            textAlign: TextAlign.center,
            style: m.sans(19, min: 12, color: MixerTheme.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
