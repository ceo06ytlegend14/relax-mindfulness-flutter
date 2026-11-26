import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/wellbeing_components.dart';
import 'package:relax_mindfulness/main.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/screens/ai_studio_screen.dart';
import 'package:relax_mindfulness/screens/breathe_screen.dart';
import 'package:relax_mindfulness/screens/data_backup_screen.dart';
import 'package:relax_mindfulness/screens/meditation_screen.dart';
import 'package:relax_mindfulness/screens/mindfulness_screen.dart';
import 'package:relax_mindfulness/screens/wellbeing_screen.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/inert_audio_player.dart';

Future<AppState> mountWellbeing(
  WidgetTester tester, {
  Widget screen = const WellbeingScreen(),
  double width = 390,
  double textScale = 1,
  bool shell = false,
  void Function(AppState)? prepare,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  SharedPreferences.setMockInitialValues({});
  final app = AppState(
    guidedPlayer: InertAudioPlayer(),
    preferences: await SharedPreferences.getInstance(),
    now: () => DateTime(2026, 11, 19, 12),
  );
  prepare?.call(app);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: app,
      child: shell
          ? const SanctuaryApp()
          : CupertinoApp(
              localizationsDelegates: const [
                DefaultMaterialLocalizations.delegate,
              ],
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
  await tester.pump(const Duration(milliseconds: 350));
  return app;
}

Future<void> tapWellbeing(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  // Start the pushed route's animation before advancing its duration.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
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
    testWidgets(
      'wellbeing is a plain, scrollable page with real zero activity at $width',
      (tester) async {
        final app = await mountWellbeing(tester, width: width, textScale: 1.28);
        expect(find.byKey(const ValueKey('wellbeing-title')), findsOneWidget);
        expect(find.text('0 / 7'), findsOneWidget);
        expect(find.textContaining('A fresh page.'), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(find.byType(PracticeWeek), findsOneWidget);
        expect(app.sessions, isEmpty);
        final scaffold = tester.widget<CupertinoPageScaffold>(
          find.byType(CupertinoPageScaffold),
        );
        expect(scaffold.backgroundColor, MixerTheme.background);
        await tester.ensureVisible(
          find.byKey(const ValueKey('open-data-backup')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'recording a session without a mood prompt refreshes real weekly activity',
    (tester) async {
      final app = await mountWellbeing(tester);
      expect(find.text('0 / 7'), findsOneWidget);
      app.recordSession('Quiet pause', 'Breathing', 7, showMoodCheckIn: false);
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('1 / 7'), findsOneWidget);
      expect(app.showMoodDialog, isFalse);
      expect(app.weeklyMinutes.fold<int>(0, (sum, day) => sum + day.value), 7);
    },
  );

  testWidgets(
    'Home → wellbeing → breathing is a real pushed route, not the Meditate alias',
    (tester) async {
      final app = await mountWellbeing(tester, shell: true);
      await tapWellbeing(tester, 'home-wellbeing');
      expect(find.byType(WellbeingScreen), findsOneWidget);
      await tapWellbeing(tester, 'wellbeing-open-breathe');
      expect(find.byType(BreatheScreen), findsOneWidget);
      expect(find.byType(MeditationScreen), findsNothing);
      expect(find.byKey(const ValueKey('breathing-title')), findsOneWidget);
      expect(app.tab, AppTab.home);
      expect(app.currentGuidedTitle, isNull);
      expect(app.activeAmbientTracks, isEmpty);
      final footer = tester.widget<CupertinoTabBar>(
        find.byWidgetPredicate((widget) => widget is CupertinoTabBar),
      );
      expect(footer.items.map((item) => item.label), [
        'Home',
        'Sounds',
        'Meditate',
        'Sleep',
      ]);
      await tester.tap(find.byType(CupertinoNavigationBarBackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.byType(WellbeingScreen), findsOneWidget);
      expect(find.byType(BreatheScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final destination in [
    ('wellbeing-open-progress', MindfulnessScreen),
    ('wellbeing-open-reflection', AiStudioScreen),
    ('open-data-backup', DataBackupScreen),
  ]) {
    testWidgets(
      'wellbeing opens ${destination.$2} and Back returns without changing tabs',
      (tester) async {
        final app = await mountWellbeing(tester);
        await tapWellbeing(tester, destination.$1);
        expect(find.byType(destination.$2), findsOneWidget);
        expect(app.tab, AppTab.home);
        await tester.tap(find.byType(CupertinoNavigationBarBackButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        expect(find.byKey(const ValueKey('wellbeing-title')), findsOneWidget);
        expect(app.sessions, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'progress distinguishes this week from all saved history and does not invent mood',
    (tester) async {
      final app = await mountWellbeing(
        tester,
        screen: const MindfulnessScreen(),
        prepare: (app) {
          expect(
            app.importUserDataFromJson('''{
        "sessions":[
          {"id":"old","title":"Older practice","type":"Meditation","dur":120,"ts":1794470400000,"mood":0},
          {"id":"new","title":"Quiet pause","type":"Breathing","dur":12,"ts":1795003200000,"mood":0}
        ]
      }'''),
            isTrue,
          );
        },
      );
      // Pin the dates explicitly instead of depending on when this test is run.
      expect(
        app.sessions.firstWhere((s) => s.id == 'new').timestamp,
        DateTime.fromMillisecondsSinceEpoch(1795003200000),
      );
      expect(app.totalMinutes, 132);
      final weekMinutes = app.weeklyMinutes.fold<int>(
        0,
        (sum, day) => sum + day.value,
      );
      expect(weekMinutes, 12);
      expect(find.text('12 min'), findsWidgets);
      expect(
        find.byKey(const ValueKey('progress-weekly-minutes')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('progress-weekly-minutes')))
            .data,
        '12 min',
      );
      await tester.ensureVisible(find.text('Older practice'));
      await tester.pump();
      expect(find.text('Older practice'), findsOneWidget);
      expect(find.textContaining('Mood check-in:'), findsNothing);
      expect(find.text('65%'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty progress has zero-height bars and its breathing action opens breathing',
    (tester) async {
      await mountWellbeing(
        tester,
        screen: const MindfulnessScreen(),
        width: 320,
        textScale: 1.28,
      );
      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(
          tester.getSize(find.byKey(ValueKey('progress-bar-$day'))).height,
          0,
        );
      }
      expect(find.byKey(const ValueKey('progress-empty')), findsOneWidget);
      await tapWellbeing(tester, 'progress-open-breathe');
      expect(find.byType(BreatheScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'breathing starts in its selected phase and resumes without restarting the cycle',
    (tester) async {
      await mountWellbeing(tester, screen: const BreatheScreen());
      await tapWellbeing(tester, 'breathing-toggle');
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('breathing-phase-seconds')))
            .data,
        '2',
      );
      await tapWellbeing(tester, 'breathing-toggle');
      final pausedTime = tester
          .widget<Text>(find.byKey(const ValueKey('breathing-time')))
          .data;
      await tester.pump(const Duration(seconds: 8));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('breathing-time'))).data,
        pausedTime,
      );
      await tapWellbeing(tester, 'breathing-toggle');
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('breathing-phase-seconds')))
            .data,
        '1',
      );
      expect(find.text('Breathe in'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Hold gently'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('changing pattern resets; the even pattern skips both holds', (
    tester,
  ) async {
    final app = await mountWellbeing(
      tester,
      screen: const BreatheScreen(),
      width: 320,
      textScale: 1.28,
    );
    await tapWellbeing(tester, 'breathing-toggle');
    await tester.pump(const Duration(seconds: 2));
    await tapWellbeing(tester, 'breathing-pattern-resonance55');
    expect(app.pattern, BreathingPattern.resonance55);
    expect(find.text('03:00'), findsOneWidget);
    expect(find.text('Begin practice'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('breathing-phase-seconds')))
          .data,
      '5',
    );
    await tapWellbeing(tester, 'breathing-toggle');
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Breathe out'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Breathe in'), findsOneWidget);
    expect(app.sessions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'background pauses breathing; returning never resumes automatically or records it',
    (tester) async {
      final app = await mountWellbeing(tester, screen: const BreatheScreen());
      await tapWellbeing(tester, 'breathing-toggle');
      await tester.pump(const Duration(seconds: 2));
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      final time = tester
          .widget<Text>(find.byKey(const ValueKey('breathing-time')))
          .data;
      await tester.pump(const Duration(minutes: 10));
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('breathing-time'))).data,
        time,
      );
      expect(find.text('Resume practice'), findsOneWidget);
      expect(app.sessions, isEmpty);
      expect(app.showMoodDialog, isFalse);
    },
  );

  testWidgets(
    'a finished breathing timer records once, and reset does not create another session',
    (tester) async {
      final app = await mountWellbeing(tester, screen: const BreatheScreen());
      await tapWellbeing(tester, 'breathing-duration-1');
      await tapWellbeing(tester, 'breathing-toggle');
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('00:00'), findsOneWidget);
      expect(app.showMoodDialog, isTrue);
      app.dismissMood();
      await tester.pump();
      expect(app.sessions, hasLength(1));
      expect(app.sessions.single.type, 'Breathing');
      expect(app.sessions.single.durationMinutes, 1);
      await tester.pump(const Duration(minutes: 1));
      await tapWellbeing(tester, 'breathing-reset');
      expect(find.text('01:00'), findsOneWidget);
      expect(app.sessions, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
