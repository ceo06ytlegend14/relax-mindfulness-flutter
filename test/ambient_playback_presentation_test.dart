import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/glass_components.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/main.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/home_screen.dart';
import 'package:relax_mindfulness/screens/sleep_screen.dart';
import 'package:relax_mindfulness/screens/sounds_screen.dart';

import 'support/fake_mixer_app_state.dart';

Future<MixerController> mountPlaybackPresentation(
  WidgetTester tester,
  FakeMixerAppState app,
  Widget child, {
  double width = 823,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1500));
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
        home: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return mixer;
}

SanctuaryIcon playbackIcon(WidgetTester tester, String key) =>
    tester.widget<SanctuaryIcon>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(SanctuaryIcon),
      ),
    );

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

  testWidgets(
    'Home counts only ready layers through partial loading and failure',
    (tester) async {
      final app = FakeMixerAppState()
        ..active.addAll({'Soft Rain': .6, 'Ocean Waves': .2})
        ..ambientLoading.add('Soft Rain');
      final mixer = await mountPlaybackPresentation(
        tester,
        app,
        const HomeScreen(),
      );
      expect(find.text('Playing · 1 layer · 1 loading'), findsOneWidget);
      expect(
        playbackIcon(tester, 'home-mix-toggle').symbol,
        SanctuarySymbol.close,
      );
      app.active.remove('Soft Rain');
      app.ambientLoading.clear();
      app.ambientErrors['Soft Rain'] = 'This recording could not play.';
      app.notifyListeners();
      await tester.pump();
      expect(find.text('Playing · 1 layer · 1 unavailable'), findsOneWidget);
      expect(mixer.levels, {'Soft Rain': .6, 'Ocean Waves': .2});
      expect(app.activeAmbientTracks, {'Ocean Waves': .2});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a narrow large-text Home can cancel before playback starts', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final app = FakeMixerAppState()
      ..active['Soft Rain'] = .48
      ..ambientLoading.add('Soft Rain');
    final mixer = await mountPlaybackPresentation(
      tester,
      app,
      const HomeScreen(),
      width: 320,
      textScale: 1.6,
    );
    final toggle = find.byKey(const ValueKey('home-mix-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pump();
    expect(find.text('Loading soundscape…'), findsOneWidget);
    expect(find.bySemanticsLabel('Cancel pending soundscape'), findsOneWidget);
    expect(tester.getSize(toggle).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));
    expect(app.isAnyAudioPlaying, isFalse);
    await tester.tap(toggle);
    await tester.pump();
    expect(app.hasAmbientPlaybackRequest, isFalse);
    expect(mixer.volume('Soft Rain'), .48);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sounds shows buffering and unavailable states without active claims',
    (tester) async {
      final app = FakeMixerAppState()
        ..active['Soft Rain'] = .6
        ..ambientBuffering.add('Soft Rain');
      final mixer = await mountPlaybackPresentation(
        tester,
        app,
        const SoundsScreen(),
      );
      expect(find.text('Preparing Soundscape'), findsOneWidget);
      expect(find.text('Buffering soundscape…'), findsOneWidget);
      expect(find.text('Buffering recording…'), findsOneWidget);
      expect(find.text('Soundscape Active'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mixer-play')));
      await tester.pump();
      expect(app.requestedAmbientTracks, isEmpty);
      expect(mixer.volume('Soft Rain'), .6);
      app.ambientErrors['Soft Rain'] = 'This recording could not play.';
      app.notifyListeners();
      await tester.pump();
      expect(find.text('Audio unavailable'), findsOneWidget);
      expect(
        find.text('Audio unavailable · tap play to retry'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('mixer-play')));
      await tester.pump();
      expect(app.activeAmbientTracks, {'Soft Rain': .6});
      expect(find.text('Playing · 1 layer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sleep symbols glow only for ready playback, not loading or interruption',
    (tester) async {
      final app = FakeMixerAppState()
        ..active.addAll({'Ocean Waves': .57, 'Soft Rain': .4})
        ..ambientLoading.add('Ocean Waves');
      final mixer = await mountPlaybackPresentation(
        tester,
        app,
        const SleepScreen(),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('quick-Ocean')));
      await tester.pump();
      expect(playbackIcon(tester, 'quick-Ocean').glow, isFalse);
      expect(playbackIcon(tester, 'quick-Rain').glow, isTrue);
      expect(
        playbackIcon(tester, 'quick-Thunder').color,
        SanctuaryPalette.gold,
      );
      expect(find.text('Playing · 1 layer · 1 loading'), findsWidgets);
      app.ambientLoading.clear();
      app.ambientBuffering.add('Ocean Waves');
      app.notifyListeners();
      await tester.pump();
      expect(playbackIcon(tester, 'quick-Ocean').glow, isFalse);
      expect(find.text('Playing · 1 layer · 1 buffering'), findsWidgets);
      app.ambientBuffering.clear();
      app.ambientPaused.add('Ocean Waves');
      app.notifyListeners();
      await tester.pump();
      expect(playbackIcon(tester, 'quick-Ocean').glow, isFalse);
      expect(playbackIcon(tester, 'quick-Rain').glow, isTrue);
      expect(mixer.levels, {'Ocean Waves': .57, 'Soft Rain': .4});
      app.ambientPaused.clear();
      app.notifyListeners();
      await tester.pump();
      expect(playbackIcon(tester, 'quick-Ocean').glow, isTrue);
      expect(playbackIcon(tester, 'quick-Ocean').color, SanctuaryPalette.mint);
      app.active.remove('Ocean Waves');
      app.ambientErrors['Ocean Waves'] = 'This recording could not play.';
      app.notifyListeners();
      await tester.pump();
      expect(playbackIcon(tester, 'quick-Ocean').glow, isFalse);
      expect(playbackIcon(tester, 'quick-Rain').glow, isTrue);
      expect(mixer.volume('Ocean Waves'), .57);
      await tester.tap(find.byKey(const ValueKey('quick-Ocean')));
      await tester.pump();
      expect(app.activeAmbientTracks, {'Ocean Waves': .57, 'Soft Rain': .4});
      expect(playbackIcon(tester, 'quick-Ocean').glow, isTrue);
      expect(playbackIcon(tester, 'quick-Rain').glow, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ocean Sleep can be cancelled while both layers are loading', (
    tester,
  ) async {
    final app = FakeMixerAppState()
      ..ambientLoading.addAll(['Ocean Waves', 'Soft Rain']);
    final mixer = await mountPlaybackPresentation(
      tester,
      app,
      const SleepScreen(),
    );
    final begin = find.byKey(const ValueKey('begin-ocean-sleep'));
    await tester.tap(begin);
    await tester.pump();
    expect(app.requestedAmbientTracks, oceanSleepJourney.levels);
    expect(app.activeAmbientTracks, isEmpty);
    expect(find.text('Cancel Sleep'), findsOneWidget);
    expect(find.text('Pause Sleep'), findsNothing);
    await tester.tap(begin);
    await tester.pump();
    expect(app.hasAmbientPlaybackRequest, isFalse);
    expect(mixer.levels, oceanSleepJourney.levels);
    expect(app.cached, oceanSleepJourney.levels);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending mini-player stays visible and its cancel target is enabled',
    (tester) async {
      final app = FakeMixerAppState()
        ..active['Soft Rain'] = .57
        ..ambientLoading.add('Soft Rain');
      final mixer = await mountPlaybackPresentation(
        tester,
        app,
        const CupertinoPageScaffold(
          child: Center(child: SanctuaryMiniPlayer()),
        ),
        width: 390,
      );
      expect(find.text('Loading soundscape…'), findsOneWidget);
      final toggle = find.byKey(const ValueKey('mini-player-play-pause'));
      expect(
        playbackIcon(tester, 'mini-player-play-pause').symbol,
        SanctuarySymbol.close,
      );
      expect(tester.getSize(toggle).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));
      expect(tester.widget<CupertinoButton>(toggle).onPressed, isNotNull);
      await tester.tap(toggle);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('sanctuary-mini-player')),
        findsOneWidget,
      );
      expect(find.text('Paused · Your sounds are kept'), findsOneWidget);
      expect(app.activeAmbientTracks, isEmpty);
      expect(mixer.volume('Soft Rain'), .57);
    },
  );

  testWidgets(
    'an interrupted mini-player offers resume rather than false pause',
    (tester) async {
      final app = FakeMixerAppState()
        ..active['Soft Rain'] = .55
        ..ambientPaused.add('Soft Rain');
      await mountPlaybackPresentation(
        tester,
        app,
        const CupertinoPageScaffold(
          child: Center(child: SanctuaryMiniPlayer()),
        ),
        width: 390,
      );
      expect(find.text('Playback paused · tap play to resume'), findsOneWidget);
      expect(
        playbackIcon(tester, 'mini-player-play-pause').symbol,
        SanctuarySymbol.play,
      );
      expect(app.isAnyAudioPlaying, isFalse);
      await tester.tap(find.byKey(const ValueKey('mini-player-play-pause')));
      await tester.pump();
      expect(app.activeAmbientTracks, {'Soft Rain': .55});
      expect(find.text('Playing · 1 layer'), findsOneWidget);
      expect(
        playbackIcon(tester, 'mini-player-play-pause').symbol,
        SanctuarySymbol.pause,
      );
    },
  );

  testWidgets(
    'sound controls count ready layers but retain pending removal controls',
    (tester) async {
      final app = FakeMixerAppState()
        ..active.addAll({'Soft Rain': .6, 'Ocean Waves': .2})
        ..ambientLoading.add('Soft Rain');
      await mountPlaybackPresentation(
        tester,
        app,
        const CupertinoPageScaffold(
          child: Center(child: ActivePlayingListModal()),
        ),
        width: 390,
      );
      expect(find.text('Active Soundscapes (1)'), findsOneWidget);
      expect(find.text('Loading · Level: 60%'), findsOneWidget);
      expect(find.text('Playing · Level: 20%'), findsOneWidget);
      final remove = find.byKey(
        const ValueKey('remove-active-track-Soft Rain'),
      );
      expect(tester.getSize(remove).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(remove).height, greaterThanOrEqualTo(44));
      await tester.tap(remove);
      await tester.pump();
      expect(app.requestedAmbientTracks, {'Ocean Waves': .2});
      expect(find.text('Active Soundscapes (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the real shell retains pending and interrupted ambient controls',
    (tester) async {
      final app = FakeMixerAppState()
        ..selectedTab = AppTab.meditate
        ..active['Soft Rain'] = .4
        ..ambientLoading.add('Soft Rain');
      await mountPlaybackPresentation(
        tester,
        app,
        const AppShell(),
        width: 390,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.isAnyAudioPlaying, isFalse);
      expect(
        find.byKey(const ValueKey('sanctuary-mini-player')),
        findsOneWidget,
      );
      app.ambientLoading.clear();
      app.ambientPaused.add('Soft Rain');
      app.notifyListeners();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('sanctuary-mini-player')),
        findsOneWidget,
      );
      expect(
        playbackIcon(tester, 'mini-player-play-pause').symbol,
        SanctuarySymbol.play,
      );
      await tester.tap(find.byKey(const ValueKey('close-mini-player')));
      await tester.pump();
      expect(find.byKey(const ValueKey('sanctuary-mini-player')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed Sounds layer has a 44px retry without resetting its level',
    (tester) async {
      final app = FakeMixerAppState()
        ..active.addAll({'Soft Rain': .63, 'Ocean Waves': .21});
      final mixer = await mountPlaybackPresentation(
        tester,
        app,
        const SoundsScreen(),
        width: 320,
        textScale: 1.6,
      );
      app.active.remove('Soft Rain');
      app.ambientErrors['Soft Rain'] =
          'This recording could not play. Try again or replace this sound.';
      app.notifyListeners();
      await tester.pump();
      final retry = find.byKey(const ValueKey('retry-Soft Rain'));
      await tester.ensureVisible(retry);
      await tester.pump();
      expect(tester.getSize(retry).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
      expect(mixer.volume('Soft Rain'), .63);
      expect(find.byKey(const ValueKey('retry-Rain Cave')), findsNothing);
      await tester.tap(retry);
      await tester.pump();
      expect(app.activeAmbientTracks, {'Soft Rain': .63, 'Ocean Waves': .21});
      expect(mixer.levels, {'Soft Rain': .63, 'Ocean Waves': .21});
      expect(find.byKey(const ValueKey('retry-Soft Rain')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
