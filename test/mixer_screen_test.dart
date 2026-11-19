import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/home_screen.dart';

import 'support/fake_mixer_app_state.dart';

Future<FakeMixerAppState> mountMixer(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 1400));
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('MixerSans')
      ..addFont(rootBundle.load('assets/fonts/mixer/Roboto.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0, 823.0]) {
    testWidgets('landing mixer renders without overflow at width $width', (
      tester,
    ) async {
      final app = await mountMixer(tester, width);
      expect(find.byKey(const ValueKey('mixer-title')), findsOneWidget);
      expect(find.text('Build Your Environment'), findsOneWidget);
      expect(find.text('Mixer Paused'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.byKey(const ValueKey('volume-Soft Rain')), findsOneWidget);
      expect(app.active, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('master controls play and pause the selected mix', (
    tester,
  ) async {
    final app = await mountMixer(tester, 823);
    await tester.tap(find.byKey(const ValueKey('mixer-play')));
    await tester.pump();
    expect(app.active['Soft Rain'], 0.3);
    expect(find.text('Soundscape Active'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mixer-play')));
    await tester.pump();
    expect(app.active, isEmpty);
    expect(find.text('Mixer Paused'), findsOneWidget);
  });

  testWidgets('category tray displays real category data', (tester) async {
    await mountMixer(tester, 823);
    await tester.tap(find.byKey(const ValueKey('category-nature')));
    await tester.pump();
    expect(find.text('Ocean Waves'), findsOneWidget);
    expect(find.text('Forest Birds'), findsOneWidget);
    expect(find.text('Thunderstorm'), findsNothing);
  });

  testWidgets('a switch updates playback and reveals its volume slider', (
    tester,
  ) async {
    final app = await mountMixer(tester, 823);
    await tester.tap(find.byKey(const ValueKey('toggle-Thunderstorm')));
    await tester.pump();
    expect(app.active['Thunderstorm'], 0.3);
    expect(find.byKey(const ValueKey('volume-Thunderstorm')), findsOneWidget);
  });

  testWidgets('favorites have a useful empty state', (tester) async {
    final app = await mountMixer(tester, 823);
    app.starred.clear();
    app.notifyListeners();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('category-favorites')));
    await tester.pump();
    expect(find.text('Your quiet favorites live here'), findsOneWidget);
    expect(find.text('Explore rain sounds'), findsOneWidget);
  });

  testWidgets('save dialog validates a name and saves the selected volumes', (
    tester,
  ) async {
    final app = await mountMixer(tester, 823);
    await tester.tap(find.byKey(const ValueKey('mixer-save')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Save your soundscape'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('mix-name')),
      'Night rain',
    );
    await tester.pump();
    await tester.tap(find.text('Save mix'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.saved.single.name, 'Night rain');
    expect(app.saved.single.volumes['Soft Rain'], 0.3);
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('recommended mixes can still be renamed with a long press', (
    tester,
  ) async {
    final app = await mountMixer(tester, 823);
    await tester.longPress(find.text('🌧️ Rainy Cabin'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('mix-name')),
      'Quiet cabin',
    );
    await tester.pump();
    await tester.tap(find.text('Save name'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.renamed['🌧️ Rainy Cabin'], 'Quiet cabin');
    expect(find.text('Quiet cabin'), findsOneWidget);
  });
}
