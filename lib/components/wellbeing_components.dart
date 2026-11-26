import 'package:flutter/cupertino.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/services/pwa_player_visibility.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// The wellbeing tools are ordinary pushed pages, not extra footer tabs.
/// Opaque, local-color surfaces also work without an image/network connection.
class WellbeingPage extends StatefulWidget {
  const WellbeingPage({
    required this.title,
    required this.builder,
    required this.scrollKey,
    super.key,
  });

  final String title;
  final Key scrollKey;
  final Widget Function(BuildContext, SanctuaryMetrics) builder;

  @override
  State<WellbeingPage> createState() => _WellbeingPageState();
}

class _WellbeingPageState extends State<WellbeingPage> {
  final Object _visibilityOwner = Object();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setPwaWellbeingPageVisible(
      _visibilityOwner,
      TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true),
    );
  }

  @override
  void dispose() {
    setPwaWellbeingPageVisible(_visibilityOwner, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: MixerTheme.background,
    navigationBar: CupertinoNavigationBar(
      backgroundColor: MixerTheme.background,
      border: null,
      previousPageTitle: 'Back',
      middle: Text(
        widget.title,
        style: const TextStyle(
          fontFamily: MixerTheme.font,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: MixerTheme.text,
        ),
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MixerTheme.maxWidth),
            child: LayoutBuilder(
              builder: (context, inner) {
                final m = SanctuaryMetrics(inner.maxWidth);
                return SingleChildScrollView(
                  key: widget.scrollKey,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20 + m.space(8),
                    24 + m.space(10),
                    20 + m.space(8),
                    150 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: widget.builder(context, m),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class WellbeingSurface extends StatelessWidget {
  const WellbeingSurface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: MixerTheme.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class WellbeingDestination extends StatelessWidget {
  const WellbeingDestination({
    required this.title,
    required this.description,
    required this.symbol,
    required this.onPressed,
    this.accent = MixerTheme.mint,
    super.key,
  });

  final String title, description;
  final SanctuarySymbol symbol;
  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    child: WellbeingSurface(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SanctuaryIcon(symbol, size: 24, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: MixerTheme.font,
                    color: MixerTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: MixerTheme.font,
                    color: MixerTheme.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const SanctuaryIcon(
            SanctuarySymbol.chevronRight,
            color: MixerTheme.muted,
            size: 18,
          ),
        ],
      ),
    ),
  );
}

class WellbeingEyebrow extends StatelessWidget {
  const WellbeingEyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: MixerTheme.mint,
      fontFamily: MixerTheme.font,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.9,
      height: 1.5,
    ),
  );
}

/// The number is intentionally not replaced by illustrative/demo activity.
class WellbeingStat extends StatelessWidget {
  const WellbeingStat({required this.value, required this.label, super.key});
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'SanctuarySerif',
          color: MixerTheme.text,
          fontSize: 34,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: const TextStyle(
          fontFamily: MixerTheme.font,
          color: MixerTheme.muted,
          fontSize: 12,
          height: 1.45,
        ),
      ),
    ],
  );
}

class PracticeWeek extends StatelessWidget {
  const PracticeWeek({required this.minutes, super.key});
  final List<MapEntry<String, int>> minutes;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final day in minutes)
        Expanded(
          child: Semantics(
            label: '${day.key}, ${day.value} minutes recorded',
            excludeSemantics: true,
            child: Column(
              children: [
                Text(
                  day.key.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: MixerTheme.font,
                    color: MixerTheme.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: day.value > 0
                        ? MixerTheme.mint
                        : MixerTheme.background,
                    border: Border.all(
                      color: day.value > 0
                          ? MixerTheme.mint
                          : MixerTheme.border,
                    ),
                  ),
                  child: Center(
                    child: day.value > 0
                        ? const SanctuaryIcon(
                            SanctuarySymbol.check,
                            color: MixerTheme.background,
                            size: 16,
                          )
                        : const Text(
                            '–',
                            style: TextStyle(color: MixerTheme.muted),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
