import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/sounds_screen.dart';

import 'support/fake_mixer_app_state.dart';
import 'support/fake_sound_preview_player.dart';
import 'package:relax_mindfulness/services/sound_preview_controller.dart';

Future<FakeMixerAppState> mountMixer(
  WidgetTester tester,
  double width, {
  double height = 1400,
  double textScale = 1,
  SoundPreviewPlayer Function()? previewPlayerFactory,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
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
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: SoundsScreen(previewPlayerFactory: previewPlayerFactory),
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
    testWidgets('Sounds mixer renders without overflow at width $width', (
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
    await tester.pumpAndSettle();
    expect(app.renamed['🌧️ Rainy Cabin'], 'Quiet cabin');
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.text('Quiet cabin'), findsOneWidget);
  });
  testWidgets(
    'opening and canceling the chooser never autoplays or changes the mix',
    (tester) async {
      final previews = <FakeSoundPreviewPlayer>[];
      final app = await mountMixer(
        tester,
        390,
        height: 844,
        previewPlayerFactory: () {
          final player = FakeSoundPreviewPlayer();
          previews.add(player);
          return player;
        },
      );
      final options = find.byKey(const ValueKey('options-Soft Rain'));
      await tester.ensureVisible(options);
      await tester.tap(options);
      await tester.pumpAndSettle();
      expect(find.text('Replace Soft Rain'), findsOneWidget);
      expect(previews, isEmpty);
      expect(app.active, isEmpty);
      expect(app.cached, isEmpty);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const ValueKey('use-replacement-sound')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('close-sound-replacement')));
      await tester.pumpAndSettle();
      expect(app.active, isEmpty);
      expect(app.cached, isEmpty);
      expect(app.previewDucked, isFalse);
    },
  );

  testWidgets(
    'preview is explicit, short, cancelable and leaves selected levels untouched',
    (tester) async {
      final player = FakeSoundPreviewPlayer();
      final app = await mountMixer(
        tester,
        390,
        height: 844,
        previewPlayerFactory: () => player,
      );
      final options = find.byKey(const ValueKey('options-Soft Rain'));
      await tester.ensureVisible(options);
      await tester.tap(options);
      await tester.pumpAndSettle();
      final preview = find.byKey(const ValueKey('preview-Ocean Waves'));
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pump();
      expect(player.playCalls, 1);
      expect(app.previewDucked, isTrue);
      expect(app.cached, isEmpty);
      expect(app.active, isEmpty);
      await tester.pump(const Duration(seconds: 8));
      expect(player.disposed, isTrue);
      expect(app.previewDucked, isFalse);
      await tester.ensureVisible(
        find.byKey(const ValueKey('close-sound-replacement')),
      );
      await tester.tap(find.byKey(const ValueKey('close-sound-replacement')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Use sound keeps a paused selection paused and normal taps/favorites still work',
    (tester) async {
      final app = await mountMixer(tester, 390, height: 844);
      final options = find.byKey(const ValueKey('options-Soft Rain'));
      await tester.ensureVisible(options);
      await tester.tap(options);
      await tester.pumpAndSettle();
      final select = find.byKey(
        const ValueKey('select-replacement-Ocean Waves'),
      );
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pump();
      expect(app.cached, isEmpty);
      await tester.tap(find.byKey(const ValueKey('use-replacement-sound')));
      await tester.pumpAndSettle();
      expect(app.cached, {'Ocean Waves': .3});
      expect(app.active, isEmpty);
      final card = find.byKey(const ValueKey('track-Ocean Waves'));
      await tester.ensureVisible(card);
      await tester.longPress(find.text('Ocean Waves'));
      await tester.pump();
      expect(app.starred.contains('Ocean Waves'), isFalse);
      await tester.tap(find.byKey(const ValueKey('toggle-Ocean Waves')));
      await tester.pump();
      expect(app.cached['Ocean Waves'], 0);
      await tester.tap(find.text('Ocean Waves'));
      await tester.pump();
      expect(app.active['Ocean Waves'], .3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preview failure is visible and closing stops and restores playback gain',
    (tester) async {
      final player = FakeSoundPreviewPlayer()..failLoad = true;
      final app = await mountMixer(
        tester,
        390,
        height: 844,
        previewPlayerFactory: () => player,
      );
      final options = find.byKey(const ValueKey('options-Soft Rain'));
      await tester.ensureVisible(options);
      await tester.tap(options);
      await tester.pumpAndSettle();
      final preview = find.byKey(const ValueKey('preview-Ocean Waves'));
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pump();
      expect(
        find.text('Preview could not play. Your mix was not changed.'),
        findsOneWidget,
      );
      expect(app.previewDucked, isFalse);
      expect(app.active, isEmpty);
      expect(app.cached, isEmpty);
      await tester.ensureVisible(
        find.byKey(const ValueKey('close-sound-replacement')),
      );
      await tester.tap(find.byKey(const ValueKey('close-sound-replacement')));
      await tester.pumpAndSettle();
    },
  );

  for (final size in const [Size(320, 640), Size(390, 844), Size(844, 390)]) {
    testWidgets(
      'replacement controls stay scrollable with large text at $size',
      (tester) async {
        await mountMixer(
          tester,
          size.width,
          height: size.height,
          textScale: 1.6,
        );
        final options = find.byKey(const ValueKey('options-Soft Rain'));
        // In landscape the lazy SliverList has not built this card yet.
        await tester.scrollUntilVisible(
          options,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(options);
        await tester.pumpAndSettle();
        final select = find.byKey(
          const ValueKey('select-replacement-Temple Bowl'),
        );
        await tester.ensureVisible(select);
        await tester.tap(select);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('use-replacement-sound')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('use-replacement-sound')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'a preview stops on backgrounding and does not resume on return',
    (tester) async {
      final player = FakeSoundPreviewPlayer();
      final app = await mountMixer(
        tester,
        390,
        height: 844,
        previewPlayerFactory: () => player,
      );
      final options = find.byKey(const ValueKey('options-Soft Rain'));
      await tester.ensureVisible(options);
      await tester.tap(options);
      await tester.pumpAndSettle();
      final preview = find.byKey(const ValueKey('preview-Ocean Waves'));
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pump();
      expect(app.previewDucked, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(player.disposed, isTrue);
      expect(app.previewDucked, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(player.playCalls, 1);
      expect(app.active, isEmpty);
      await tester.ensureVisible(
        find.byKey(const ValueKey('close-sound-replacement')),
      );
      await tester.tap(find.byKey(const ValueKey('close-sound-replacement')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'missing and failed source state is readable instead of hidden fallback audio',
    (tester) async {
      final app = await mountMixer(tester, 823);
      app.ambientErrors['Soft Rain'] =
          'This recording could not play. Try again or replace this sound.';
      app.notifyListeners();
      await tester.pump();
      expect(find.byKey(const ValueKey('mixer-source-notice')), findsOneWidget);
      expect(
        find.text(
          'This recording could not play. Try again or replace this sound.',
        ),
        findsOneWidget,
      );
      final cave = find.byKey(const ValueKey('track-Rain Cave'));
      await tester.scrollUntilVisible(
        cave,
        450,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Needs a recording · tap ⋯ to replace'), findsWidgets);
      expect(find.byKey(const ValueKey('cover-Rain Cave')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
