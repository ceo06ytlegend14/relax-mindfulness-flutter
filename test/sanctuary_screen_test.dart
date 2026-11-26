import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';
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
      expect(find.byType(SanctuaryBackdrop), findsNothing);
      expect(
        tester
            .widget<CupertinoPageScaffold>(find.byType(CupertinoPageScaffold))
            .backgroundColor,
        MixerTheme.background,
      );
      expect(find.textContaining('No spoken guidance.'), findsOneWidget);
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

  for (final width in [320.0, 390.0, 431.0, 823.0]) {
    testWidgets('Sleep keeps compact covers and a scrollable fifth at $width', (
      tester,
    ) async {
      await mountSanctuary(tester, const SleepScreen(), width: width);
      final tray = find.byKey(const ValueKey('sleep-winddown-tray'));
      final first = find.byKey(
        ValueKey('soundscape-${sleepSoundscapes.first.id}'),
      );
      await reveal(tester, first);
      final viewport = tester.getRect(tray);
      expect(tester.getSize(first).width, greaterThanOrEqualTo(84));
      if (width >= 390) {
        final fourth = find.byKey(
          ValueKey('soundscape-${sleepSoundscapes[3].id}'),
        );
        expect(tester.getRect(first).left, greaterThanOrEqualTo(viewport.left));
        expect(
          tester.getRect(fourth).right,
          lessThanOrEqualTo(viewport.right + 1),
        );
      }
      expect(sleepSoundscapes, hasLength(5));
      final last = find.byKey(
        ValueKey('soundscape-${sleepSoundscapes.last.id}'),
      );
      await tester.ensureVisible(last);
      await tester.pump();
      expect(
        tester.getRect(last).left,
        greaterThanOrEqualTo(viewport.left - 1),
      );
      expect(tester.getRect(last).right, lessThanOrEqualTo(viewport.right + 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'all five Sleep mixer controls have large distinct vector symbols',
    (tester) async {
      await mountSanctuary(tester, const SleepScreen(), width: 390);
      final symbols = <SanctuarySymbol>[];
      for (final label in ['Ocean', 'Rain', 'Wind', 'Thunder', 'Nature']) {
        final control = find.byKey(ValueKey('quick-$label'));
        await reveal(tester, control);
        final icon = tester.widget<SanctuaryIcon>(
          find.descendant(of: control, matching: find.byType(SanctuaryIcon)),
        );
        symbols.add(icon.symbol);
        final orb = tester.getSize(find.byKey(ValueKey('sleep-orb-$label')));
        final hitTarget = tester.getSize(control);
        expect(orb.width, greaterThanOrEqualTo(44));
        expect(icon.size! / orb.width, closeTo(0.9, 0.01));
        expect(hitTarget.width, greaterThanOrEqualTo(44));
        expect(hitTarget.height, greaterThanOrEqualTo(44));
        expect(icon.glow, isFalse, reason: 'No playback means no active glow');
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
    },
  );

  testWidgets('daily journey begins and pauses the correct session', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const MeditationScreen());
    await tester.tap(find.byKey(const ValueKey('begin-daily-journey')));
    await tester.pump();
    expect(app.guidedRequests.single, ('Calm Mountain Horizon', 10));
    expect(find.text(dailyMeditation.sourceLabel), findsOneWidget);
    expect(app.guidedPlaying, isTrue);
    await tester.tap(find.byKey(const ValueKey('begin-daily-journey')));
    await tester.pump();
    expect(app.guidedPlaying, isFalse);
  });

  testWidgets('emotional intent chips filter real session data', (
    tester,
  ) async {
    await mountSanctuary(tester, const MeditationScreen());
    await tester.tap(find.byKey(const ValueKey('intent-Calm')));
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
    await reveal(tester, find.byKey(const ValueKey('begin-gentle-relief')));
    await tester.tap(find.byKey(const ValueKey('begin-gentle-relief')));
    await tester.pump();
    expect(app.guidedRequests.single, ('Gentle Relief & Comfort', 15));
    expect(find.text('Bamboo Chimes + Soft Rain'), findsOneWidget);
    await tester.longPress(
      find.byKey(const ValueKey('practice-gentle-relief')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Save practice'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.libraryFavorites, contains('meditation-gentle-relief'));
  });

  testWidgets(
    'practice options are visible buttons and clipboard errors stay recoverable',
    (tester) async {
      final app = await mountSanctuary(
        tester,
        const MeditationScreen(),
        width: 320,
        textScale: 1.28,
      );
      final options = find.byKey(
        const ValueKey('practice-options-gentle-relief'),
      );
      await reveal(tester, options);
      await tester.tap(options);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('Save practice'), findsOneWidget);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData')
              throw PlatformException(code: 'denied');
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.tap(find.text('Copy session details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('Could not copy details'), findsOneWidget);
      expect(find.text('Session details copied'), findsNothing);
      expect(app.libraryFavorites, isEmpty);
      await tester.tap(find.text('Done'));
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('timer confirms 30 minutes and cancel clears the shared timer', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await tester.tap(find.byKey(const ValueKey('set-sleep-timer')));
    // Let the modal finish entering before hit-testing its header controls.
    await tester.pumpAndSettle();
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
    // Let the modal finish entering before hit-testing its header controls.
    await tester.pumpAndSettle();
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
      SanctuaryIcon symbol(String label) => tester.widget<SanctuaryIcon>(
        find.descendant(
          of: find.byKey(ValueKey('quick-$label')),
          matching: find.byType(SanctuaryIcon),
        ),
      );
      await reveal(tester, ocean);
      expect(symbol('Ocean').glow, isFalse);
      expect(symbol('Rain').glow, isFalse);
      await tester.tap(ocean);
      await tester.pump();
      expect(app.active, {'Ocean Waves': 0.6});
      expect(symbol('Ocean').glow, isTrue);
      expect(symbol('Ocean').color, SanctuaryPalette.mint);
      expect(symbol('Rain').glow, isFalse);
      await tester.tap(find.byKey(const ValueKey('quick-Rain')));
      await tester.pump();
      expect(app.active, {'Ocean Waves': 0.6, 'Soft Rain': 0.6});
      expect(symbol('Rain').glow, isTrue);
      await tester.tap(ocean);
      await tester.pump();
      expect(app.active, {'Soft Rain': 0.6});
      expect(symbol('Ocean').glow, isFalse);
      expect(symbol('Rain').glow, isTrue);
      final resume = find.byKey(const ValueKey('resume-sleep-mix'));
      await tester.ensureVisible(resume);
      await tester.pump();
      await tester.tap(resume);
      await tester.pump();
      expect(app.active, isEmpty);
      expect(app.cached, {'Soft Rain': 0.6});
      expect(symbol('Rain').glow, isFalse);
      await tester.tap(resume);
      await tester.pump();
      expect(app.active, {'Soft Rain': 0.6});
      expect(symbol('Rain').glow, isTrue);
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

  testWidgets(
    'My Journeys filters saved stories and has a useful empty state',
    (tester) async {
      final app = await mountSanctuary(tester, const SleepScreen());
      await reveal(tester, find.byKey(const ValueKey('stories-My Journeys')));
      await tester.tap(find.byKey(const ValueKey('stories-My Journeys')));
      await tester.pump();
      expect(find.text('Your quiet collection'), findsOneWidget);
      await tester.tap(find.text('Browse all journeys'));
      await tester.pump();
      await reveal(
        tester,
        find.byKey(const ValueKey('save-story-starry-night')),
      );
      await tester.tap(find.byKey(const ValueKey('save-story-starry-night')));
      await tester.pump();
      expect(app.libraryFavorites, contains('story-starry-night'));
      await tester.ensureVisible(
        find.byKey(const ValueKey('stories-My Journeys')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('stories-My Journeys')));
      await tester.pump();
      expect(find.byKey(const ValueKey('story-starry-night')), findsOneWidget);
      expect(find.byKey(const ValueKey('story-dreamland')), findsNothing);
    },
  );

  testWidgets('stories keep their original title and duration when played', (
    tester,
  ) async {
    final app = await mountSanctuary(tester, const SleepScreen());
    await reveal(tester, find.byKey(const ValueKey('play-story-starry-night')));
    await tester.tap(find.byKey(const ValueKey('play-story-starry-night')));
    await tester.pump();
    expect(app.guidedRequests.single, ('The Starry Night', 35));
  });

  testWidgets(
    'Meditate offers three starters and an explicit route to all fourteen',
    (tester) async {
      final app = await mountSanctuary(tester, const MeditationScreen());
      int count() => tester
          .widget<SliverList>(find.byType(SliverList))
          .delegate
          .estimatedChildCount!;
      expect(count(), 3);
      for (final id in featuredMeditationIds) {
        await reveal(tester, find.byKey(ValueKey('practice-$id')));
      }
      final browse = find.byKey(const ValueKey('browse-practices'));
      await reveal(tester, browse);
      expect(find.text('Browse all 14 practices'), findsOneWidget);
      await tester.tap(browse);
      await tester.pump();
      expect(count(), 14);
      // Expanding the lazy list moves its footer below the viewport.
      await reveal(tester, browse);
      expect(find.text('Show featured practices'), findsOneWidget);
      await tester.tap(browse);
      // Shrinking the lazy list must also settle its corrected scroll extent.
      await tester.pumpAndSettle();
      expect(count(), 3);
      expect(app.guidedRequests, isEmpty);
      expect(app.active, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'visible Save and Saved keep favorite identities and never begin audio',
    (tester) async {
      final app = await mountSanctuary(tester, const MeditationScreen());
      final dailySave = find.byKey(const ValueKey('daily-practice-save'));
      await tester.tap(dailySave);
      expect(app.libraryFavorites, contains('meditation-calm-mountain'));
      final save = find.byKey(const ValueKey('save-practice-body-rest'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pump();
      final savedFilter = find.byKey(const ValueKey('intent-Saved'));
      await tester.ensureVisible(savedFilter);
      await tester.pump();
      await tester.tap(savedFilter);
      await tester.pump();
      expect(
        tester
            .widget<SliverList>(find.byType(SliverList))
            .delegate
            .estimatedChildCount,
        1,
      );
      await reveal(tester, save);
      expect(find.byKey(const ValueKey('practice-body-rest')), findsOneWidget);
      expect(
        app.libraryFavorites,
        containsAll(['meditation-calm-mountain', 'meditation-body-rest']),
      );
      await tester.tap(save);
      await tester.pump();
      expect(
        find.text(
          'No saved practices in this collection yet. Tap a heart to keep one here.',
        ),
        findsOneWidget,
      );
      expect(app.libraryFavorites, {'meditation-calm-mountain'});
      expect(app.guidedRequests, isEmpty);
      expect(app.active, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filtering retains the current session and truthful pause/loading controls',
    (tester) async {
      final app = await mountSanctuary(tester, const MeditationScreen());
      final begin = find.byKey(const ValueKey('begin-quiet-mind'));
      await reveal(tester, begin);
      await tester.tap(begin);
      await tester.pump();
      for (final filter in ['Rest', 'Focus']) {
        final chip = find.byKey(ValueKey('intent-$filter'));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump();
      }
      await reveal(tester, begin);
      expect(app.guidedTitle, 'Quiet Mind Sanctuary');
      expect(app.guidedRequests, hasLength(1));
      expect(app.guidedPlaying, isTrue);
      final pauseIcon = tester.widget<SanctuaryIcon>(
        find.descendant(of: begin, matching: find.byType(SanctuaryIcon)),
      );
      expect(pauseIcon.symbol, SanctuarySymbol.pause);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Pause Quiet Mind Sanctuary',
        ),
        findsOneWidget,
      );
      app.guidedPlaying = false;
      app.guidedLoading = true;
      app.notifyListeners();
      await tester.pump();
      expect(tester.widget<CupertinoButton>(begin).onPressed, isNull);
      expect(
        find.descendant(
          of: begin,
          matching: find.byType(CupertinoActivityIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Opening Quiet Mind Sanctuary' &&
              widget.properties.enabled == false,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 538.0]) {
    testWidgets(
      'Meditate separates the featured moment from compact art-first rows at $width',
      (tester) async {
        final app = await mountSanctuary(
          tester,
          const MeditationScreen(),
          width: width,
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('daily-journey'))).height,
          lessThan(310),
        );
        final card = find.byKey(const ValueKey('practice-gentle-relief'));
        await reveal(tester, card);
        expect(tester.getSize(card).height, lessThan(160));
        final art = find.descendant(of: card, matching: find.byType(Image));
        final title = find.descendant(
          of: card,
          matching: find.text('Gentle Relief & Comfort'),
        );
        expect(tester.getRect(art).right, lessThan(tester.getRect(title).left));
        expect(tester.widget<Text>(title).maxLines, isNull);
        for (final key in [
          'save-practice-gentle-relief',
          'practice-options-gentle-relief',
          'begin-gentle-relief',
        ]) {
          final button = find.byKey(ValueKey(key));
          expect(tester.getSize(button), const Size(44, 44));
          expect(button.hitTestable(), findsOneWidget);
        }
        expect(app.guidedRequests, isEmpty);
        expect(app.active, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'compact practice actions stay reachable with 1.6 scale at 320 pixels',
    (tester) async {
      await mountSanctuary(
        tester,
        const MeditationScreen(),
        width: 320,
        textScale: 1.6,
      );
      for (final key in [
        'daily-practice-save',
        'save-practice-gentle-relief',
        'begin-body-rest',
        'browse-practices',
      ]) {
        final button = find.byKey(ValueKey(key));
        await reveal(tester, button);
        expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
