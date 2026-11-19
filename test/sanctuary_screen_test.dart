import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/meditation_screen.dart';
import 'package:relax_mindfulness/screens/sleep_screen.dart';

import 'support/fake_mixer_app_state.dart';

Future<FakeMixerAppState> mountSanctuary(
  WidgetTester tester,
  Widget screen, {
  double width = 823,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1500));
  final app = FakeMixerAppState();
  final mixer = MixerController(app);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    mixer.dispose();
    app.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<MixerController>.value(value: mixer),
      ],
      child: CupertinoApp(
        localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return app;
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MixerSans',
    )..addFont(rootBundle.load('assets/fonts/mixer/Roboto.ttf'))).load();
    await (FontLoader('SanctuarySerif')..addFont(
          rootBundle.load('assets/fonts/editorial/CormorantGaramond.ttf'),
        ))
        .load();
  });

  for (final width in [320.0, 390.0, 823.0]) {
    testWidgets('Meditate renders without autoplay or overflow at $width', (
      tester,
    ) async {
      final app = await mountSanctuary(
        tester,
        const MeditationScreen(),
        width: width,
      );
      expect(find.byKey(const ValueKey('meditation-title')), findsOneWidget);
      expect(find.text('Calm Mountain Horizon'), findsOneWidget);
      expect(app.guidedRequests, isEmpty);
      expect(app.active, isEmpty);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'Sleep renders without autoplay or fictional progress at $width',
      (tester) async {
        final app = await mountSanctuary(
          tester,
          const SleepScreen(),
          width: width,
        );
        expect(find.byKey(const ValueKey('sleep-title')), findsOneWidget);
        expect(
          find.text('Good evening. Let the day drift away.'),
          findsOneWidget,
        );
        expect(find.text('31 min remaining'), findsNothing);
        expect(find.text('68%'), findsNothing);
        expect(app.active, isEmpty);
        expect(app.timerSeconds, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final screen in [const MeditationScreen(), const SleepScreen()]) {
    testWidgets(
      '${screen.runtimeType} accommodates larger text on a narrow phone',
      (tester) async {
        await mountSanctuary(tester, screen, width: 320, textScale: 1.28);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Sleep uses the new local moonlit ocean art, not a screenshot UI',
    (tester) async {
      await mountSanctuary(tester, const SleepScreen(), width: 390);
      final hero = find.byKey(const ValueKey('moonlit-ocean-journey'));
      final image = tester.widget<Image>(
        find.descendant(of: hero, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/sleep/moonlit_shore.webp',
      );
      expect(
        find.descendant(of: hero, matching: find.text('Ocean Sleep')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all five Sleep mixer controls have distinct vector symbols', (
    tester,
  ) async {
    await mountSanctuary(tester, const SleepScreen(), width: 390);
    final symbols = <SanctuarySymbol>[];
    for (final label in ['Ocean', 'Rain', 'Wind', 'Thunder', 'Nature']) {
      final control = find.byKey(ValueKey('quick-$label'));
      await reveal(tester, control);
      final icon = tester.widget<SanctuaryIcon>(
        find.descendant(of: control, matching: find.byType(SanctuaryIcon)),
      );
      symbols.add(icon.symbol);
      expect(
        find.descendant(of: control, matching: find.byType(Icon)),
        findsNothing,
      );
    }
    expect(symbols, [
      SanctuarySymbol.waves,
      SanctuarySymbol.rain,
      SanctuarySymbol.wind,
      SanctuarySymbol.bolt,
      SanctuarySymbol.tree,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily journey begins and pauses the correct session', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const MeditationScreen());
    await tester.tap(find.byKey(const ValueKey('begin-daily-journey')));
    await tester.pump();
    expect(app.guidedRequests.single, ('Calm Mountain Horizon', 10));
    expect(app.guidedPlaying, isTrue);
    await tester.tap(find.byKey(const ValueKey('begin-daily-journey')));
    await tester.pump();
    expect(app.guidedPlaying, isFalse);
  });

  testWidgets('emotional intent chips filter real session data', (
    tester,
  ) async {
    await mountSanctuary(tester, const MeditationScreen());
    await tester.tap(find.byKey(const ValueKey('intent-Comfort')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('practice-gentle-relief')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('practice-body-rest')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('practice-morning-awakening')),
      findsNothing,
    );
  });

  testWidgets('practice begin and long-press save actions are functional', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const MeditationScreen());
    await tester.tap(find.byKey(const ValueKey('begin-gentle-relief')));
    await tester.pump();
    expect(app.guidedRequests.single, ('Gentle Relief & Comfort', 15));
    await tester.longPress(
      find.byKey(const ValueKey('practice-gentle-relief')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save practice'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.libraryFavorites, contains('meditation-gentle-relief'));
  });

  testWidgets('timer confirms 30 minutes and cancel clears the shared timer', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await tester.tap(find.byKey(const ValueKey('set-sleep-timer')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('confirm-sleep-timer')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.timerSeconds, 1800);
    expect(find.text('Auto-Fade Timer · 30:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel-sleep-timer')));
    await tester.pump();
    expect(app.timerSeconds, isNull);
  });

  testWidgets('dismissing the timer picker does not start a timer', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await tester.tap(find.byKey(const ValueKey('set-sleep-timer')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.timerSeconds, isNull);
  });

  testWidgets('Ocean Sleep starts ocean and rain with a 45-minute timer', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await tester.tap(find.byKey(const ValueKey('begin-ocean-sleep')));
    await tester.pump();
    expect(app.active, oceanSleepJourney.levels);
    expect(app.timerSeconds, 2700);
    expect(app.guidedRequests, isEmpty);
    await tester.tap(find.byKey(const ValueKey('begin-ocean-sleep')));
    await tester.pump();
    expect(app.active, isEmpty);
    expect(app.cached, oceanSleepJourney.levels);
  });

  testWidgets(
    'different playlists start their own tracks rather than Rainy Cabin',
    (tester) async {
      final app = await mountSanctuary(tester, const SleepScreen());
      await tester.tap(find.byKey(const ValueKey('soundscape-campfire')));
      await tester.pump();
      expect(app.active, {'Campfire': 0.6});
      expect(app.timerSeconds, 35 * 60);
      await tester.tap(find.byKey(const ValueKey('soundscape-ocean-waves')));
      await tester.pump();
      expect(app.active, {'Ocean Waves': 0.6});
      expect(app.timerSeconds, 45 * 60);
    },
  );

  testWidgets(
    'quick mixer toggles independent tracks and keeps selection in sync',
    (tester) async {
      final app = await mountSanctuary(tester, const SleepScreen());
      final ocean = find.byKey(const ValueKey('quick-Ocean'));
      await reveal(tester, ocean);
      await tester.tap(ocean);
      await tester.pump();
      expect(app.active, {'Ocean Waves': 0.6});
      await tester.tap(find.byKey(const ValueKey('quick-Rain')));
      await tester.pump();
      expect(app.active, {'Ocean Waves': 0.6, 'Soft Rain': 0.6});
      await tester.tap(ocean);
      await tester.pump();
      expect(app.active, {'Soft Rain': 0.6});
    },
  );

  testWidgets(
    'continue listening preserves a paused mix and uses real timer progress',
    (tester) async {
      final app = await mountSanctuary(tester, const SleepScreen());
      await tester.tap(find.byKey(const ValueKey('resume-sleep-mix')));
      await tester.pump();
      expect(app.active, {'Soft Rain': 0.3});
      await tester.tap(find.byKey(const ValueKey('resume-sleep-mix')));
      await tester.pump();
      expect(app.active, isEmpty);
      expect(find.text('Resume'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('resume-sleep-mix')));
      await tester.pump();
      expect(app.active, {'Soft Rain': 0.3});
      app.startSleepTimer(30);
      app.timerSeconds = 900;
      app.notifyListeners();
      await tester.pump();
      expect(find.text('15 min remaining'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    },
  );

  testWidgets('Customize opens the existing Sounds tab', (tester) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await reveal(tester, find.byKey(const ValueKey('customize-sleep-mix')));
    await tester.tap(find.byKey(const ValueKey('customize-sleep-mix')));
    await tester.pump();
    expect(app.selectedTab, AppTab.sounds);
  });

  testWidgets('My Stories filters saved stories and has a useful empty state', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await reveal(tester, find.byKey(const ValueKey('stories-My Stories')));
    await tester.tap(find.byKey(const ValueKey('stories-My Stories')));
    await tester.pump();
    expect(find.text('Your bedtime bookshelf'), findsOneWidget);
    await tester.tap(find.text('Browse all stories'));
    await tester.pump();
    await reveal(tester, find.byKey(const ValueKey('save-story-starry-night')));
    await tester.tap(find.byKey(const ValueKey('save-story-starry-night')));
    await tester.pump();
    expect(app.libraryFavorites, contains('story-starry-night'));
    await tester.ensureVisible(
      find.byKey(const ValueKey('stories-My Stories')),
    );
    await tester.tap(find.byKey(const ValueKey('stories-My Stories')));
    await tester.pump();
    expect(find.byKey(const ValueKey('story-starry-night')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-dreamland')), findsNothing);
  });

  testWidgets('stories keep their original title and duration when played', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await reveal(tester, find.byKey(const ValueKey('play-story-starry-night')));
    await tester.tap(find.byKey(const ValueKey('play-story-starry-night')));
    await tester.pump();
    expect(app.guidedRequests.single, ('The Starry Night', 35));
  });
}
