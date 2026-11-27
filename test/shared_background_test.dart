import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/glass_components.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/onboarding_screen.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';
import 'package:relax_mindfulness/theme/neumorphism_demo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_mixer_app_state.dart';
import 'support/shared_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'MixerSans',
    )..addFont(rootBundle.load('assets/fonts/mixer/Roboto.ttf'))).load();
  });

  for (final width in [320.0, 390.0, 823.0, 1440.0]) {
    testWidgets(
      'one decorative sky stays pinned outside safe-area scrolls at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var taps = 0;
        await tester.pumpWidget(
          CupertinoApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
              ),
              child: child!,
            ),
            home: SanctuaryPageScaffold(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CupertinoButton(
                        key: const ValueKey('background-hit-target'),
                        onPressed: () => taps++,
                        child: const Text('Continue'),
                      ),
                      const SizedBox(height: 1800),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sky = expectSharedBackground(tester);
        final canvasWidth = math.min(width, MixerTheme.maxWidth);
        final before = tester.getRect(sky);
        expect(before.top, 0);
        expect(before.left, (width - canvasWidth) / 2);
        expect(before.width, canvasWidth);
        expect(
          before.height,
          closeTo(SanctuaryMetrics(canvasWidth).space(620), 0.01),
        );
        final fade =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: sky,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        final gradient = fade.gradient! as LinearGradient;
        expect(gradient.begin, Alignment.topCenter);
        expect(gradient.end, Alignment.bottomCenter);
        expect(gradient.stops, [0, .5, 1]);
        expect(gradient.colors, [
          MixerTheme.background.withOpacity(0),
          MixerTheme.background.withOpacity(.12),
          MixerTheme.background,
        ]);
        final button = find.byKey(const ValueKey('background-hit-target'));
        expect(tester.getTopLeft(button).dy, greaterThanOrEqualTo(24));
        await tester.tap(button);
        expect(taps, 1, reason: 'Decorative paint never intercepts controls');
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .pixels,
          greaterThan(0),
        );
        expect(tester.getRect(sky), before);
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'The wallpaper has no ticker',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final entry in const <String, Widget>{
    'onboarding': OnboardingScreen(),
    'Twilight controls': NeumorphismDemoScreen(),
    'legacy Zen player': ZenFullscreenModal(),
  }.entries) {
    testWidgets(
      '${entry.key} uses the same bundled sky instead of alternate wallpaper',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        SharedPreferences.setMockInitialValues({});
        await SharedPreferences.getInstance();
        final app = FakeMixerAppState();
        final mixer = MixerController(app);
        try {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AppState>.value(value: app),
                ChangeNotifierProvider<MixerController>.value(value: mixer),
              ],
              child: CupertinoApp(
                localizationsDelegates: const [
                  DefaultMaterialLocalizations.delegate,
                ],
                theme: const CupertinoThemeData(brightness: Brightness.dark),
                home: Material(child: entry.value),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          expectSharedBackground(tester);
          expect(app.active, isEmpty);
          expect(app.guidedRequests, isEmpty);
          if (entry.key == 'Twilight controls') {
            await tester.tap(find.byTooltip('Shared night-sky background'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 450));
            expect(find.text('Night sky'), findsOneWidget);
            expect(
              find.byType(CupertinoActionSheetAction),
              findsOneWidget,
              reason: 'Only Done; no alternate wallpapers',
            );
            await tester.tap(find.text('Done'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 450));
            expectSharedBackground(tester);
          }
          expect(tester.takeException(), isNull);
        } finally {
          // The legacy Zen foreground owns a timer/ticker; dispose before the
          // widget binding verifies pending work, not in package:test teardown.
          await tester.pumpWidget(const SizedBox.shrink());
          mixer.dispose();
          app.dispose();
          await tester.binding.setSurfaceSize(null);
        }
      },
    );
  }
}
