import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/wellbeing_components.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

void expectMatte(BoxDecoration decoration) {
  expect(decoration.color, isNotNull);
  expect(decoration.borderRadius, isNotNull);
  expect(decoration.border, isNull);
  expect(decoration.gradient, isNull);
  expect(decoration.boxShadow, isNull);
}

void main() {
  test('Sleep panels use tonal emphasis, not decorative rings or shadows', () {
    final ordinary = sleepSurface();
    final emphasized = sleepSurface(glow: true);
    expectMatte(ordinary);
    expectMatte(emphasized);
    expect(ordinary.color, SanctuaryPalette.navySurface);
    expect(emphasized.color, SanctuaryPalette.navyActive);
    // Quick-control symbol outlines and playback glow are deliberately separate
    // from these panel decorations; sanctuary_screen_test covers those controls.
  });

  test('shared solid-fill text pairs retain at least 4.5 to 1 contrast', () {
    for (final pair in [
      (MixerTheme.onPrimary, MixerTheme.primary),
      (MixerTheme.muted, MixerTheme.surface),
      (MixerTheme.text, MixerTheme.action),
      (SanctuaryPalette.cream, SanctuaryPalette.navyControl),
      (SanctuaryPalette.mist, SanctuaryPalette.navySurface),
    ]) {
      final a = pair.$1.computeLuminance();
      final b = pair.$2.computeLuminance();
      final lighter = a > b ? a : b;
      final darker = a > b ? b : a;
      expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('shared mixer surfaces are matte in both selection states', (
    tester,
  ) async {
    final metrics = MixerMetrics(390);
    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: [
            MixerSurface(
              metrics: metrics,
              child: const SizedBox(width: 100, height: 50),
            ),
            MixerSurface(
              metrics: metrics,
              active: true,
              child: const SizedBox(width: 100, height: 50),
            ),
            MixerSectionHeading('YOUR SOUNDS', metrics: metrics),
          ],
        ),
      ),
    );
    final colors = <Color?>[];
    for (final surface in find.byType(MixerSurface).evaluate()) {
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byWidget(surface.widget),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expectMatte(decoration);
      colors.add(decoration.color);
    }
    expect(colors, [MixerTheme.surface, MixerTheme.surfaceActive]);
    expect(
      find.descendant(
        of: find.byType(MixerSectionHeading),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
      reason: 'Section labels no longer draw a trailing divider',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shared primary and quiet pills keep flat fills and 44px targets',
    (tester) async {
      final metrics = SanctuaryMetrics(390);
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final variant in ['primary', 'glow', 'quiet', 'gold'])
                  SanctuaryPillButton(
                    buttonKey: ValueKey('pill-$variant'),
                    label: variant,
                    metrics: metrics,
                    glow: variant == 'glow',
                    quiet: variant == 'quiet',
                    gold: variant == 'gold',
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        ),
      );
      for (final variant in ['primary', 'glow', 'quiet', 'gold']) {
        final button = find.byKey(ValueKey('pill-$variant'));
        final skin =
            tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: button,
                            matching: find.byWidgetPredicate(
                              (widget) =>
                                  widget is Container &&
                                  widget.decoration is BoxDecoration,
                            ),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        expectMatte(skin);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wellbeing panels are borderless without flattening activity cues',
    (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: WellbeingPage(
            title: 'Your wellbeing',
            scrollKey: const ValueKey('soft-wellbeing-scroll'),
            builder: (context, metrics) => const WellbeingSurface(
              child: PracticeWeek(
                minutes: [
                  MapEntry('Monday', 3),
                  MapEntry('Tuesday', 0),
                  MapEntry('Wednesday', 0),
                  MapEntry('Thursday', 0),
                  MapEntry('Friday', 0),
                  MapEntry('Saturday', 0),
                  MapEntry('Sunday', 0),
                ],
              ),
            ),
          ),
        ),
      );
      final surface =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(WellbeingSurface),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expectMatte(surface);
      expect(
        tester
            .widget<CupertinoNavigationBar>(find.byType(CupertinoNavigationBar))
            .border,
        isNull,
      );
      expect(find.text('–'), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    },
  );
}
