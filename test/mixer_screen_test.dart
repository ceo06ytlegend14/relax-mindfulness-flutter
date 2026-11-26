import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/models/vibe_sound_sets.dart';
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

Future<void> openFullCatalog(WidgetTester tester) async {
  final review = find.byKey(const ValueKey('catalog-review'));
  await tester.ensureVisible(review);
  await tester.tap(review);
  await tester.pump();
  final full = find.byKey(const ValueKey('library-full'));
  await tester.ensureVisible(full);
  await tester.tap(full);
  await tester.pump();
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

  testWidgets(
    'unfinished inventory needs explicit review without touching saved or playing levels',
    (tester) async {
      final app = await mountMixer(tester, 823);
      final mixer = tester
          .element(find.byType(SoundsScreen))
          .read<MixerController>();
      mixer.applyMix({'Soft Rain': .31, 'Campfire': .22});
      app.savePreset('Kept', {'Rain on Umbrella': .22});
      final favorites = Set<String>.of(app.starred);
      await tester.pump();
      expect(mixer.categoryCount('all'), 18);
      expect(find.byKey(const ValueKey('library-full')), findsNothing);
      final review = find.byKey(const ValueKey('catalog-review'));
      await tester.ensureVisible(review);
      expect(tester.getSize(review).height, greaterThanOrEqualTo(44));
      await tester.tap(review);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('catalog-review-description')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('library-full')), findsOneWidget);
      expect(
        mixer.availableOnly,
        isTrue,
        reason: 'Disclosure is not a view or playback action',
      );
      expect(app.active, {'Soft Rain': .31, 'Campfire': .22});
      expect(app.cached, mixer.levels);
      expect(app.saved.single.volumes, {'Rain on Umbrella': .22});
      expect(app.starred, favorites);
      await tester.ensureVisible(find.byKey(const ValueKey('library-full')));
      await tester.tap(find.byKey(const ValueKey('library-full')));
      await tester.pump();
      expect(mixer.categoryCount('all'), 77);
      await tester.ensureVisible(
        find.byKey(const ValueKey('library-available')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('library-available')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('library-available')));
      await tester.pump();
      expect(mixer.categoryCount('all'), 18);
      expect(find.byKey(const ValueKey('library-full')), findsNothing);
      expect(app.active, {'Soft Rain': .31, 'Campfire': .22});
      expect(app.cached, mixer.levels);
      expect(app.saved.single.volumes, {'Rain on Umbrella': .22});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved non-bundled selections have a deliberate non-destructive review path',
    (tester) async {
      final app = await mountMixer(tester, 823);
      app.cached = {'Soft Rain': .31, 'Rain on Umbrella': .22};
      app.starred.add('Rain on Umbrella');
      app.savePreset('Kept', {'Rain on Umbrella': .22});
      app.notifyListeners();
      await tester.pump();
      final review = find.byKey(const ValueKey('library-review-selected'));
      await tester.ensureVisible(review);
      await tester.tap(review);
      await tester.pump();
      final mixer = tester
          .element(find.byType(SoundsScreen))
          .read<MixerController>();
      expect(mixer.availableOnly, isFalse);
      expect(mixer.category, 'all');
      expect(find.byKey(const ValueKey('library-full')), findsOneWidget);
      expect(mixer.levels, {'Soft Rain': .31, 'Rain on Umbrella': .22});
      expect(app.saved.single.volumes, {'Rain on Umbrella': .22});
      expect(app.starred, contains('Rain on Umbrella'));
      expect(app.active, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

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
    await openFullCatalog(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('toggle-Thunderstorm')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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
    await openFullCatalog(tester);
    await tester.ensureVisible(find.text('🌧️ Rainy Cabin'));
    await tester.pump();
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
      expect(find.text('Change Soft Rain'), findsOneWidget);
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
        await tester.pump();
        await tester.ensureVisible(options);
        await tester.pump();
        expect(options.hitTestable(), findsOneWidget);
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
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(player.disposed, isTrue);
      expect(app.previewDucked, isFalse);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
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
    'new sources are searchable and the Use button stays above the keyboard',
    (tester) async {
      final previews = <FakeSoundPreviewPlayer>[];
      final app = await mountMixer(
        tester,
        390,
        height: 844,
        textScale: 1.28,
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
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      final search = find.byKey(const ValueKey('search-replacement-sounds'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'not a sound');
      await tester.pump();
      expect(
        find.text('No local sounds match. Try a different name.'),
        findsOneWidget,
      );
      await tester.enterText(search, 'Blue Noise');
      await tester.pump();
      expect(find.text('Sanctuary project · CC0'), findsOneWidget);
      final choice = find.byKey(
        const ValueKey('select-replacement-Blue Noise'),
      );
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();
      expect(
        previews,
        isEmpty,
        reason: 'Search and selection do not preview audio',
      );
      final use = find.byKey(const ValueKey('use-replacement-sound'));
      expect(tester.getBottomLeft(use).dy, lessThanOrEqualTo(544));
      expect(use.hitTestable(), findsOneWidget);
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(app.active, isEmpty);
      expect(app.cached, {'Blue Noise': .3});
      expect(tester.takeException(), isNull);
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
      await openFullCatalog(tester);
      final cave = find.byKey(const ValueKey('track-Rain Cave'));
      await tester.scrollUntilVisible(
        cave,
        450,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No recording configured · unavailable'), findsWidgets);
      expect(find.byKey(const ValueKey('cover-Rain Cave')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final soundSet in vibeSoundSets) {
    testWidgets(
      'one tap selects the exact ${soundSet.name} recipe without editing it',
      (tester) async {
        final app = await mountMixer(tester, 390);
        final button = find.byKey(ValueKey('curated-${soundSet.name}'));
        await tester.ensureVisible(button);
        await tester.pump();
        expect(app.activeAmbientTracks, isEmpty);
        expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        await tester.tap(button);
        await tester.pump();
        expect(app.activeAmbientTracks, soundSet.levels);
        expect(app.cached, soundSet.levels);
        final mixer = Provider.of<MixerController>(
          tester.element(find.byType(SoundsScreen)),
          listen: false,
        );
        for (final track in allMixerTracks) {
          expect(
            mixer.volume(track.name),
            soundSet.levels[track.name] ?? 0,
            reason: 'Unselected sounds remain disabled',
          );
        }
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('vibe-set-purpose')))
              .data,
          soundSet.purpose,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('vibe-set-levels')))
              .data,
          soundSet.recipe,
        );
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('vibe-set-name'))).data,
          soundSet.name,
        );
        await tester.tap(find.byKey(const ValueKey('mixer-play')));
        await tester.pump();
        expect(app.activeAmbientTracks, isEmpty);
        expect(app.cached, soundSet.levels);
        expect(find.byKey(const ValueKey('vibe-set-details')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'edited and same-named custom mixes never retain a false official recipe',
    (tester) async {
      final app = await mountMixer(tester, 390);
      final button = find.byKey(const ValueKey('curated-Rainy Window Café'));
      await tester.tap(button);
      await tester.pump();
      final mixer = Provider.of<MixerController>(
        tester.element(find.byType(SoundsScreen)),
        listen: false,
      );
      mixer.setVolume('Soft Rain', .31);
      await tester.pump();
      expect(find.byKey(const ValueKey('vibe-set-details')), findsNothing);
      mixer.applyMix({'Soft Rain': .19}, name: 'Rainy Window Café');
      await tester.pump();
      expect(find.byKey(const ValueKey('vibe-set-details')), findsNothing);
      expect(app.activeAmbientTracks, {'Soft Rain': .19});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'vibe recipes wrap on a narrow screen with larger accessibility text',
    (tester) async {
      await mountMixer(tester, 320, textScale: 1.6);
      final button = find.byKey(
        const ValueKey('curated-Enchanted Forest Morning'),
      );
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      final recipe = find.byKey(const ValueKey('vibe-set-details'));
      await tester.ensureVisible(recipe);
      await tester.pump();
      expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      expect(
        find.text(vibeSoundSetForName('Enchanted Forest Morning')!.recipe),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'library views retain unsupported saved selections without playing',
    (tester) async {
      final app = await mountMixer(tester, 823);
      app.cached = {'Soft Rain': .31, 'Rain on Umbrella': .22};
      app.starred.add('Rain on Umbrella');
      app.savePreset('Kept', {'Rain on Umbrella': .22});
      app.notifyListeners();
      await tester.pump();
      final mixer = tester
          .element(find.byType(SoundsScreen))
          .read<MixerController>();
      expect(find.text('Available (18)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('library-selection-notice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('track-Rain on Umbrella')),
        findsNothing,
      );
      await openFullCatalog(tester);
      await tester.tap(find.byKey(const ValueKey('library-available')));
      await tester.pump();
      expect(mixer.levels, {'Soft Rain': .31, 'Rain on Umbrella': .22});
      expect(app.cached, mixer.levels);
      expect(app.saved.single.volumes, {'Rain on Umbrella': .22});
      expect(app.starred, contains('Rain on Umbrella'));
      expect(app.active, isEmpty);
      expect(
        find.byKey(const ValueKey('choose-recording-Soft Rain')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final (from, to, family) in [
    ('Campfire', 'Fireplace', 'fire'),
    ('Forest Birds', 'Woodland Morning', 'birds'),
  ]) {
    testWidgets(
      '$family recording choice shows only two sources and keeps paused levels',
      (tester) async {
        var previewCalls = 0;
        final app = await mountMixer(
          tester,
          390,
          previewPlayerFactory: () {
            previewCalls++;
            return FakeSoundPreviewPlayer();
          },
        );
        final mixer = tester
            .element(find.byType(SoundsScreen))
            .read<MixerController>();
        mixer.applyMix({from: .43, 'Pink Noise': .12});
        mixer.togglePlayback();
        await tester.pump();
        final chooser = find.byKey(ValueKey('choose-recording-$from'));
        await tester.scrollUntilVisible(
          chooser,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(chooser);
        await tester.pumpAndSettle();
        expect(find.text('Choose $family recording'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('search-replacement-sounds')),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'select-replacement-',
                ),
          ),
          findsNWidgets(2),
        );
        expect(
          tester
              .widget<CupertinoButton>(
                find.byKey(ValueKey('select-replacement-$from')),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(ValueKey('select-replacement-$to')));
        await tester.pump();
        expect(find.text('Use recording'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('use-replacement-sound')));
        await tester.pumpAndSettle();
        expect(app.cached, {to: .43, 'Pink Noise': .12});
        expect(app.active, isEmpty);
        expect(previewCalls, 0, reason: 'Opening and selecting do not preview');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'full catalog keeps configured streams enabled and missing sources disabled',
    (tester) async {
      final app = await mountMixer(tester, 823);
      await openFullCatalog(tester);
      for (final (name, configured) in [
        ('Rain on Umbrella', true),
        ('Rain Cave', false),
      ]) {
        final toggle = find.byKey(ValueKey('toggle-$name'));
        await tester.scrollUntilVisible(
          toggle,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester.widget<CupertinoSwitch>(toggle).onChanged != null,
          configured,
        );
      }
      expect(find.text('No recording configured · unavailable'), findsWidgets);
      expect(app.active, isEmpty);
      expect(app.cached, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
