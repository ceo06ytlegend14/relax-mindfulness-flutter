import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/glass_components.dart';
import 'package:relax_mindfulness/components/guided_player.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/main.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';

import 'support/fake_mixer_app_state.dart';

Future<FakeMixerAppState> mountSessionPlayer(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double textScale = 1,
  String title = 'Gentle Relief & Comfort',
  int minutes = 15,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  final app = FakeMixerAppState();
  await app.playGuidedSession(title, minutes);
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
            padding: const EdgeInsets.only(top: 24, bottom: 34),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const AppShell(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return app;
}

Future<void> tapPlayer(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
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
    // Do not load either icon font: all new player and Sleep symbols are vectors.
  });

  for (final size in const [
    Size(320, 640),
    Size(390, 844),
    Size(823, 1568),
    Size(844, 390),
  ]) {
    testWidgets('player stays scrollable and font-independent at $size', (
      tester,
    ) async {
      await mountSessionPlayer(tester, width: size.width, height: size.height);
      expect(find.byKey(const ValueKey('player-landscape')), findsOneWidget);
      expect(find.byKey(const ValueKey('guided-player-title')), findsOneWidget);
      expect(find.text('15:00'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(GuidedPlayerOverlay),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('complete-guided-session')),
      );
      await tester.pump();
      expect(
        tester
            .getBottomLeft(
              find.byKey(const ValueKey('complete-guided-session')),
            )
            .dy,
        lessThanOrEqualTo(size.height - 34),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'large text on a short phone does not clip the completion control',
    (tester) async {
      await mountSessionPlayer(
        tester,
        width: 320,
        height: 640,
        textScale: 1.28,
        title: 'A longer moment of gentle relief and comfort',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('complete-guided-session')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tapPlayer(tester, 'complete-guided-session');
      expect(find.byType(GuidedPlayerOverlay), findsNothing);
    },
  );

  testWidgets(
    'pause keeps the full player visible and resume keeps the position',
    (tester) async {
      final app = await mountSessionPlayer(tester);
      app.guidedSeconds = 827;
      app.notifyListeners();
      await tester.pump();
      await tapPlayer(tester, 'guided-play-pause');
      expect(app.guidedPlaying, isFalse);
      expect(app.guidedSeconds, 827);
      expect(find.byType(GuidedPlayerOverlay), findsOneWidget);
      expect(find.text('13:47'), findsOneWidget);
      expect(find.text('PAUSED · STAY A LITTLE LONGER'), findsOneWidget);
      await tapPlayer(tester, 'guided-play-pause');
      expect(app.guidedPlaying, isTrue);
      expect(app.guidedSeconds, 827);
      expect(app.guidedRequests, hasLength(1));
    },
  );

  testWidgets('transport buttons seek the shared state in both directions', (
    tester,
  ) async {
    final app = await mountSessionPlayer(tester);
    app.guidedSeconds = 800;
    app.notifyListeners();
    await tester.pump();
    await tapPlayer(tester, 'guided-back-10');
    expect(app.guidedElapsedSec, 90);
    await tapPlayer(tester, 'guided-forward-10');
    expect(app.guidedElapsedSec, 100);
    expect(app.guidedPlaying, isTrue);
  });

  testWidgets('extend updates total and remaining time while paused', (
    tester,
  ) async {
    final app = await mountSessionPlayer(tester);
    app.guidedSeconds = 870;
    await app.pauseGuidedSession();
    await tester.pump();
    await tapPlayer(tester, 'extend-guided-session');
    expect(app.guidedTotalSec, 1500);
    expect(app.guidedRemainingSec, 1470);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('24:30'), findsOneWidget);
    expect(app.guidedPlaying, isFalse);
  });

  testWidgets('restart uses 35 minutes rather than hardcoded ten', (
    tester,
  ) async {
    final app = await mountSessionPlayer(
      tester,
      title: 'The Starry Night',
      minutes: 35,
    );
    app.guidedSeconds = 1800;
    await app.pauseGuidedSession();
    await tester.pump();
    await tapPlayer(tester, 'restart-guided-session');
    expect(app.guidedRemainingSec, 2100);
    expect(app.guidedPlaying, isFalse);
    expect(find.text('35:00'), findsNWidgets(2));
  });

  testWidgets(
    'loop control toggles actual state and no unsupported quality is offered',
    (tester) async {
      final app = await mountSessionPlayer(tester);
      await tapPlayer(tester, 'loop-guided-session');
      expect(app.isGuidedLooping, isFalse);
      expect(find.text('Loop Off'), findsOneWidget);
      expect(find.text('HD'), findsNothing);
      expect(find.text('Fastest'), findsNothing);
    },
  );

  testWidgets(
    'minimizing retains playing audio and a paused mini-player can resume',
    (tester) async {
      final app = await mountSessionPlayer(tester);
      await tapPlayer(tester, 'minimize-guided-player');
      expect(find.byType(GuidedPlayerOverlay), findsNothing);
      expect(find.byType(SanctuaryMiniPlayer), findsOneWidget);
      expect(app.guidedPlaying, isTrue);
      await tapPlayer(tester, 'mini-player-play-pause');
      expect(app.guidedPlaying, isFalse);
      expect(app.hasGuidedSession, isTrue);
      expect(
        find.byKey(const ValueKey('sanctuary-mini-player')),
        findsOneWidget,
      );
      await tapPlayer(tester, 'mini-player-play-pause');
      expect(app.guidedPlaying, isTrue);
      expect(app.guidedRequests, hasLength(1));
      await tapPlayer(tester, 'open-mini-player');
      expect(find.byType(GuidedPlayerOverlay), findsOneWidget);
    },
  );

  testWidgets('full-player completion ends the session once', (tester) async {
    final app = await mountSessionPlayer(tester);
    await tapPlayer(tester, 'complete-guided-session');
    expect(app.guidedCompletions, [true]);
    expect(app.hasGuidedSession, isFalse);
    expect(find.byType(GuidedPlayerOverlay), findsNothing);
    expect(find.byKey(const ValueKey('sanctuary-mini-player')), findsNothing);
  });

  testWidgets('loading disables transport rather than showing fake playback', (
    tester,
  ) async {
    final app = await mountSessionPlayer(tester);
    app.guidedPlaying = false;
    app.guidedLoading = true;
    app.notifyListeners();
    await tester.pump();
    final button = tester.widget<CupertinoButton>(
      find.byKey(const ValueKey('guided-play-pause')),
    );
    final slider = tester.widget<CupertinoSlider>(
      find.byKey(const ValueKey('guided-progress')),
    );
    expect(button.onPressed, isNull);
    expect(slider.onChanged, isNull);
    expect(find.text('PREPARING YOUR SOUNDSCAPE'), findsOneWidget);
  });

  testWidgets('an audio error is visible and the center control retries', (
    tester,
  ) async {
    final app = await mountSessionPlayer(tester);
    app.guidedPlaying = false;
    app.guidedError =
        'Audio could not start. Check your connection and try again.';
    app.notifyListeners();
    await tester.pump();
    expect(find.byKey(const ValueKey('guided-playback-error')), findsOneWidget);
    await tapPlayer(tester, 'guided-play-pause');
    expect(app.guidedError, isNull);
    expect(app.guidedPlaying, isTrue);
  });

  for (final symbol in const [
    SanctuarySymbol.waves,
    SanctuarySymbol.rain,
    SanctuarySymbol.wind,
    SanctuarySymbol.bolt,
    SanctuarySymbol.tree,
    SanctuarySymbol.loop,
    SanctuarySymbol.rewind,
    SanctuarySymbol.forward,
    SanctuarySymbol.restart,
    SanctuarySymbol.check,
  ]) {
    testWidgets('${symbol.name} paints without either icon font', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SanctuaryIcon(
              symbol,
              size: 64,
              color: const Color(0xFF56EBCB),
            ),
          ),
        ),
      );
      expect(find.byType(Icon), findsNothing);
      final painter = tester
          .widget<CustomPaint>(find.byType(CustomPaint))
          .painter!;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(64, 64));
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(64, 64));
      final pixels = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      final data = pixels!;
      var visible = 0;
      for (var offset = 3; offset < data.lengthInBytes; offset += 4) {
        if (data.getUint8(offset) > 24) visible++;
      }
      expect(visible, greaterThan(80));
      image!.dispose();
      picture.dispose();
    });
  }
}
