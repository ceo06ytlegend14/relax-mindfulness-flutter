import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/main.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/home_screen.dart';

import 'support/fake_mixer_app_state.dart';

Future<({FakeMixerAppState app, MixerController mixer})> mountHome(
  WidgetTester tester, {
  double width = 823,
  double textScale = 1,
  Map<String, double> cached = const {},
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1500));
  final app = FakeMixerAppState()..cached = Map.of(cached);
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return (app: app, mixer: mixer);
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
    // Intentionally do not load MaterialIcons or CupertinoIcons fonts.
  });

  for (final width in [320.0, 390.0, 823.0, 1440.0]) {
    testWidgets('Home is a distinct, non-autoplaying dashboard at $width', (
      tester,
    ) async {
      final state = await mountHome(tester, width: width);
      expect(find.byKey(const ValueKey('home-title')), findsOneWidget);
      expect(find.text('A little calm,\njust for you.'), findsOneWidget);
      expect(find.text('Calm Mountain Horizon'), findsOneWidget);
      expect(find.byKey(const ValueKey('mixer-title')), findsNothing);
      expect(find.byKey(const ValueKey('mixer-categories')), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(state.app.active, isEmpty);
      expect(state.app.guidedRequests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home fits a narrow screen with larger accessibility text', (
    tester,
  ) async {
    await mountHome(tester, width: 320, textScale: 1.28);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home groups content with matte fills, not borders or glow', (
    tester,
  ) async {
    await mountHome(tester, width: 390);
    for (final name in [
      'sounds',
      'meditate',
      'sleep',
      'soundscape',
      'wellbeing',
    ]) {
      final panel = find.descendant(
        of: find.byKey(ValueKey('home-surface-$name')),
        matching: find.byType(DecoratedBox),
      );
      final decoration =
          tester.widget<DecoratedBox>(panel.first).decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNull);
      expect(decoration.gradient, isNull);
      expect(decoration.borderRadius, isNotNull);
    }
    final playDisc = find.descendant(
      of: find.byKey(const ValueKey('home-mix-toggle')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    final disc =
        tester.widget<Container>(playDisc).decoration! as BoxDecoration;
    expect(disc.color, const Color(0xFF223F5C));
    expect(disc.border, isNull);
    expect(disc.boxShadow, isNull);
  });

  testWidgets('soft Home actions retain 44px targets with larger text', (
    tester,
  ) async {
    final state = await mountHome(tester, width: 320, textScale: 1.6);
    for (final name in [
      'home-daily',
      'home-open-sounds',
      'home-open-meditate',
      'home-open-sleep',
      'home-mix-toggle',
      'home-edit-mix',
      'home-wellbeing',
    ]) {
      final button = find.byKey(ValueKey(name));
      await tester.ensureVisible(button);
      await tester.pump();
      final size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(44), reason: name);
      expect(size.height, greaterThanOrEqualTo(44), reason: name);
    }
    expect(state.app.active, isEmpty);
    expect(state.app.guidedRequests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final target in [AppTab.sounds, AppTab.meditate, AppTab.sleep]) {
    testWidgets(
      'Home quick action opens ${target.name} without starting audio',
      (tester) async {
        final state = await mountHome(tester);
        await tester.tap(find.byKey(ValueKey('home-open-${target.name}')));
        await tester.pump();
        expect(state.app.tab, target);
        expect(state.app.active, isEmpty);
        expect(state.app.guidedRequests, isEmpty);
      },
    );
  }

  testWidgets('Home begins and pauses the catalog daily meditation', (
    tester,
  ) async {
    final state = await mountHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-daily')));
    await tester.pump();
    expect(state.app.guidedRequests.single, (
      dailyMeditation.title,
      dailyMeditation.minutes,
    ));
    expect(find.text('Pause session'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-daily')));
    await tester.pump();
    expect(state.app.guidedPlaying, false);
    expect(find.text('Resume session'), findsOneWidget);
  });

  testWidgets('Home soundscape play/pause preserves the shared selection', (
    tester,
  ) async {
    final state = await mountHome(tester, cached: {'Soft Rain': 0.65});
    await tester.tap(find.byKey(const ValueKey('home-mix-toggle')));
    await tester.pump();
    expect(state.app.active, {'Soft Rain': 0.65});
    expect(find.text('Playing · 1 layer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-mix-toggle')));
    await tester.pump();
    expect(state.app.active, isEmpty);
    expect(state.mixer.volume('Soft Rain'), 0.65);
    expect(state.mixer.hasPlaybackRequest, isFalse);
    expect(state.mixer.transportLabel, 'Resume soundscape');
    expect(find.text('Paused · Your sounds are kept'), findsOneWidget);
  });

  testWidgets('Home displays the actual selection and later named mixes', (
    tester,
  ) async {
    final state = await mountHome(tester, cached: {'Campfire': 0.6});
    expect(find.text('Campfire'), findsOneWidget);
    state.mixer.applyMix({'Ocean Waves': 0.4}, name: 'Evening Coast');
    await tester.pump();
    expect(find.text('Evening Coast'), findsOneWidget);
    expect(find.text('Campfire'), findsNothing);
    expect(find.text('Playing · 1 layer'), findsOneWidget);
  });

  testWidgets(
    'An empty Home selection starts the explicit Soft Rain fallback',
    (tester) async {
      final state = await mountHome(tester);
      state.mixer.applyMix({});
      await tester.pump();
      expect(find.text('A fresh soundscape'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-mix-toggle')));
      await tester.pump();
      expect(state.app.active, {'Soft Rain': 0.3});
    },
  );

  testWidgets('Open sound mixer changes tabs without changing the mix', (
    tester,
  ) async {
    final state = await mountHome(tester, cached: {'Campfire': 0.6});
    await tester.tap(find.byKey(const ValueKey('home-edit-mix')));
    await tester.pump();
    expect(state.app.tab, AppTab.sounds);
    expect(state.mixer.levels, {'Campfire': 0.6});
    expect(state.app.active, isEmpty);
  });

  testWidgets(
    'The real shell has four vector icons and four distinct destinations',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1000));
      final app = FakeMixerAppState();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: app,
          child: const SanctuaryApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final bar = tester.widget<CupertinoTabBar>(
        find.byWidgetPredicate((widget) => widget is CupertinoTabBar),
      );
      expect(bar.items.map((item) => item.label), [
        'Home',
        'Sounds',
        'Meditate',
        'Sleep',
      ]);
      for (final item in bar.items) {
        expect(item.icon, isA<SanctuaryIcon>());
        expect(item.activeIcon, isA<SanctuaryIcon>());
      }
      expect(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is CupertinoTabBar),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('home-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('mixer-title')), findsNothing);
      for (final destination in const [
        ('Sounds', AppTab.sounds, 'mixer-title'),
        ('Meditate', AppTab.meditate, 'meditation-title'),
        ('Sleep', AppTab.sleep, 'sleep-title'),
        ('Home', AppTab.home, 'home-title'),
      ]) {
        await tester.tap(
          find.descendant(
            of: find.byWidgetPredicate((widget) => widget is CupertinoTabBar),
            matching: find.text(destination.$1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(app.tab, destination.$2);
        expect(find.byKey(ValueKey(destination.$3)), findsOneWidget);
        expect(
          find.byKey(
            ValueKey(
              destination.$2 == AppTab.home ? 'mixer-title' : 'home-title',
            ),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pump();
      await tester.drag(
        find.byKey(const PageStorageKey('home-dashboard-scroll')),
        const Offset(0, -2000),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .getBottomLeft(find.text('No rush. Your quiet moment is here.'))
            .dy,
        lessThanOrEqualTo(
          tester
              .getTopLeft(
                find.byWidgetPredicate((widget) => widget is CupertinoTabBar),
              )
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final symbol in const [
    SanctuarySymbol.home,
    SanctuarySymbol.sounds,
    SanctuarySymbol.meditate,
    SanctuarySymbol.sleep,
  ]) {
    for (final glow in [false, true]) {
      testWidgets(
        '${symbol.name} paints visible pixels without an icon font (glow=$glow)',
        (tester) async {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SanctuaryIcon(
                  symbol,
                  size: 64,
                  color: const Color(0xFF43E9CD),
                  glow: glow,
                ),
              ),
            ),
          );
          expect(find.byType(Icon), findsNothing);
          expect(find.byType(Text), findsNothing);
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
        },
      );
    }
  }
}
