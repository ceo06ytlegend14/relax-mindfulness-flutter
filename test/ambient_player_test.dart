import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/guided_player.dart';
import 'package:relax_mindfulness/main.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';

import 'support/fake_mixer_app_state.dart';

const _forest = {
  'Woodland Morning': .65,
  'Forest Birds': .55,
  'Meadow Breeze': .25,
  'Mountain Stream': .20,
};

Future<({FakeMixerAppState app, MixerController mixer})> mountAmbientPlayer(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double textScale = 1,
  bool start = true,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  final app = FakeMixerAppState();
  final mixer = MixerController(app);
  if (start) mixer.applyMix(_forest, name: 'Enchanted Forest Morning');
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
            padding: const EdgeInsets.only(top: 24, bottom: 34),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const AppShell(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return (app: app, mixer: mixer);
}

Future<void> tapAmbient(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
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

  testWidgets('an intentional Home mix start opens the full ambient player', (
    tester,
  ) async {
    final state = await mountAmbientPlayer(tester, start: false);
    expect(find.byType(AmbientPlayerOverlay), findsNothing);
    await tapAmbient(tester, 'home-mix-toggle');
    expect(find.byType(AmbientPlayerOverlay), findsOneWidget);
    expect(state.app.activeAmbientTracks, {'Soft Rain': .3});
    expect(
      find.byKey(const ValueKey('ambient-volume-Soft Rain')),
      findsOneWidget,
    );
  });

  testWidgets(
    'full player displays actual selection, percentages and layer statuses',
    (tester) async {
      final state = await mountAmbientPlayer(tester);
      expect(
        find.byKey(const ValueKey('ambient-player-title')),
        findsOneWidget,
      );
      expect(find.text('Enchanted Forest Morning'), findsWidgets);
      expect(find.byKey(const ValueKey('guided-progress')), findsNothing);
      for (final entry in _forest.entries) {
        final percent = tester.widget<Text>(
          find.byKey(ValueKey('ambient-layer-volume-${entry.key}')),
        );
        final slider = tester.widget<CupertinoSlider>(
          find.byKey(ValueKey('ambient-volume-${entry.key}')),
        );
        expect(percent.data, '${(entry.value * 100).round()}%');
        expect(slider.value, entry.value);
      }
      state.app.ambientBuffering.add('Forest Birds');
      state.app.notifyListeners();
      await tester.pump();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('ambient-layer-status-Forest Birds')),
            )
            .data,
        'Buffering…',
      );
      expect(state.app.activeAmbientTracks.length, 3);
      expect(state.mixer.levels, _forest);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'minimize and mini reopen retain playback; paused mini keeps its levels',
    (tester) async {
      final state = await mountAmbientPlayer(tester);
      await tapAmbient(tester, 'minimize-ambient-player');
      expect(find.byType(AmbientPlayerOverlay), findsNothing);
      expect(
        find.byKey(const ValueKey('sanctuary-mini-player')),
        findsOneWidget,
      );
      expect(state.app.activeAmbientTracks, _forest);
      for (final tab in [
        AppTab.home,
        AppTab.sounds,
        AppTab.meditate,
        AppTab.sleep,
      ]) {
        state.app.setTab(tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byKey(const ValueKey('sanctuary-mini-player')),
          findsOneWidget,
        );
      }
      await tapAmbient(tester, 'mini-player-play-pause');
      expect(state.app.activeAmbientTracks, isEmpty);
      expect(
        find.byKey(const ValueKey('sanctuary-mini-player')),
        findsOneWidget,
      );
      await tapAmbient(tester, 'open-mini-player');
      expect(find.byType(AmbientPlayerOverlay), findsOneWidget);
      expect(
        state.app.activeAmbientTracks,
        isEmpty,
        reason: 'Reopening is not a playback command',
      );
      expect(state.mixer.levels, _forest);
      await tapAmbient(tester, 'ambient-play-pause');
      expect(state.app.activeAmbientTracks, _forest);
      await tapAmbient(tester, 'ambient-stop');
      expect(find.byType(AmbientPlayerOverlay), findsNothing);
      expect(find.byKey(const ValueKey('sanctuary-mini-player')), findsNothing);
    },
  );

  testWidgets('Home and Sounds reserve space below the minimized player', (
    tester,
  ) async {
    final state = await mountAmbientPlayer(tester);
    await tapAmbient(tester, 'minimize-ambient-player');
    for (final target in const [
      (
        AppTab.home,
        'home-dashboard-scroll',
        'No rush. Your quiet moment is here.',
      ),
      (AppTab.sounds, 'ambient-mixer-scroll', 'Your wellbeing dashboard  →'),
    ]) {
      state.app.setTab(target.$1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.text(target.$3),
        400,
        scrollable: find
            .descendant(
              of: find.byKey(PageStorageKey(target.$2)),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      expect(
        tester.getBottomLeft(find.text(target.$3)).dy,
        lessThanOrEqualTo(
          tester
              .getTopLeft(find.byKey(const ValueKey('sanctuary-mini-player')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'paused full-player edits do not start audio or normalize independent levels',
    (tester) async {
      final state = await mountAmbientPlayer(tester);
      await tapAmbient(tester, 'ambient-play-pause');
      final slider = tester.widget<CupertinoSlider>(
        find.byKey(const ValueKey('ambient-volume-Meadow Breeze')),
      );
      slider.onChanged!(.31);
      await tester.pump();
      expect(state.mixer.levels, {..._forest, 'Meadow Breeze': .31});
      expect(state.app.activeAmbientTracks, isEmpty);
      expect(state.app.isAmbientPlayerExpanded, isTrue);
      await tapAmbient(tester, 'ambient-play-pause');
      expect(state.app.activeAmbientTracks, {..._forest, 'Meadow Breeze': .31});
      await tapAmbient(tester, 'minimize-ambient-player');
      state.mixer.setVolume('Meadow Breeze', .32);
      await tester.pump();
      expect(find.byType(AmbientPlayerOverlay), findsNothing);
      expect(state.app.isAmbientPlayerExpanded, isFalse);
    },
  );

  testWidgets('full-player gain edit preserves an interrupted native mix', (
    tester,
  ) async {
    final state = await mountAmbientPlayer(tester);
    state.app.ambientPaused.addAll(_forest.keys);
    state.app.notifyListeners();
    await tester.pump();
    expect(state.app.activeAmbientTracks, isEmpty);
    final slider = tester.widget<CupertinoSlider>(
      find.byKey(const ValueKey('ambient-volume-Meadow Breeze')),
    );
    slider.onChanged!(.31);
    await tester.pump();
    expect(state.mixer.levels, {..._forest, 'Meadow Breeze': .31});
    expect(state.app.activeAmbientTracks, isEmpty);
    expect(state.app.requestedAmbientTracks, state.mixer.levels);
    expect(state.app.isAmbientPlayerExpanded, isTrue);
    expect(
      find.descendant(
        of: find.byType(AmbientPlayerOverlay),
        matching: find.text('Playback paused · tap play to resume'),
      ),
      findsOneWidget,
    );
    await tapAmbient(tester, 'ambient-play-pause');
    expect(state.app.activeAmbientTracks, {..._forest, 'Meadow Breeze': .31});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'full-player save writes a separate custom mix, never into its source recipe',
    (tester) async {
      final state = await mountAmbientPlayer(tester);
      state.mixer.setVolume('Meadow Breeze', .31);
      await tester.pump();
      await tapAmbient(tester, 'ambient-save-mix');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byType(CupertinoTextField),
        'My morning forest',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Save mix'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.app.saved.single.name, 'My morning forest');
      expect(state.app.saved.single.volumes, {
        ..._forest,
        'Meadow Breeze': .31,
      });
      expect(_forest['Meadow Breeze'], .25);
      expect(find.byType(AmbientPlayerOverlay), findsOneWidget);
    },
  );

  testWidgets(
    'starting a timed practice replaces the ambient full view without discarding mix levels',
    (tester) async {
      final state = await mountAmbientPlayer(tester);
      await state.app.playGuidedSession('Gentle Relief & Comfort', 15);
      await tester.pump();
      expect(find.byType(AmbientPlayerOverlay), findsNothing);
      expect(find.byType(GuidedPlayerOverlay), findsOneWidget);
      expect(state.app.activeAmbientTracks, isEmpty);
      expect(state.mixer.levels, _forest);
    },
  );

  for (final size in const [
    Size(320, 640),
    Size(390, 844),
    Size(823, 1568),
    Size(844, 390),
  ]) {
    testWidgets('ambient controls remain reachable with 1.6x text at $size', (
      tester,
    ) async {
      await mountAmbientPlayer(
        tester,
        width: size.width,
        height: size.height,
        textScale: 1.6,
      );
      for (final key in [
        'minimize-ambient-player',
        'ambient-play-pause',
        'ambient-sleep-timer',
        'ambient-edit-mix',
        'ambient-volume-Meadow Breeze',
        'ambient-save-mix',
        'ambient-stop',
      ]) {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        expect(tester.getSize(finder).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
