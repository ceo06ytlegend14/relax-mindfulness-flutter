import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

import 'support/fake_mixer_app_state.dart';

void main() {
  late FakeMixerAppState app;
  late MixerController mixer;

  setUp(() {
    app = FakeMixerAppState();
    mixer = MixerController(app, random: Random(17));
  });

  tearDown(() {
    mixer.dispose();
    app.dispose();
  });

  test('default selection matches the reference without autoplay', () {
    expect(mixer.volume('Soft Rain'), 0.3);
    expect(mixer.selectedCount, 1);
    expect(mixer.isPlaying, isFalse);
    expect(app.active, isEmpty);
  });

  test(
    'preferences arriving after the first frame hydrate a paused selection',
    () {
      app.cached = {'Ocean Waves': 0.6};
      app.notifyListeners();
      expect(mixer.volume('Ocean Waves'), 0.6);
      expect(mixer.volume('Soft Rain'), 0);
      expect(mixer.isPlaying, isFalse);
    },
  );

  test('master pause and resume preserve levels', () {
    mixer.setVolume('Soft Rain', 0.45);
    expect(mixer.isPlaying, isTrue);
    mixer.togglePlayback();
    expect(mixer.isPlaying, isFalse);
    expect(mixer.volume('Soft Rain'), 0.45);
    mixer.togglePlayback();
    expect(app.active, {'Soft Rain': 0.45});
  });

  test(
    'sound switches stay inline on first start, additions and re-enable',
    () {
      mixer.toggleTrack('Fireplace');
      expect(app.active, {'Soft Rain': .3, 'Fireplace': .3});
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
      mixer.toggleTrack('Ocean Waves');
      expect(app.active, {'Soft Rain': .3, 'Fireplace': .3, 'Ocean Waves': .3});
      expect(app.isAmbientPlayerExpanded, isFalse);
      app.showAmbientPlayer();
      mixer.setVolume('Fireplace', .42);
      expect(
        app.isAmbientPlayerExpanded,
        isTrue,
        reason: 'An edit does not close an explicitly opened player either',
      );
      app.minimizeAmbientPlayer();
      mixer.toggleTrack('Ocean Waves');
      mixer.toggleTrack('Soft Rain');
      expect(app.active, {'Fireplace': .42});
      expect(app.isAmbientPlayerExpanded, isFalse);
      mixer.toggleTrack('Fireplace');
      expect(app.active, isEmpty);
      expect(app.hasAmbientSession, isFalse);
      mixer.toggleTrack('Fireplace');
      expect(app.active, {'Fireplace': .3});
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
    },
  );

  test(
    'first slider edit stays inline while explicit master resume still expands',
    () {
      mixer.setVolume('Soft Rain', .41);
      expect(app.active, {'Soft Rain': .41});
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
      mixer.togglePlayback();
      expect(app.active, isEmpty);
      expect(app.hasAmbientSession, isTrue);
      mixer.togglePlayback();
      expect(app.active, {'Soft Rain': .41});
      expect(app.isAmbientPlayerExpanded, isTrue);
    },
  );

  test(
    'a collapsed transport request is honored even without a prior session',
    () {
      mixer.togglePlayback(expandPlayer: false);
      expect(app.active, {'Soft Rain': .3});
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
    },
  );

  test('intentional starts expand, but gain edits do not undo minimize', () {
    mixer.applyMix({'Soft Rain': .65, 'Coffee Shop': .25}, name: 'Window');
    expect(app.isAmbientPlayerExpanded, isTrue);
    app.minimizeAmbientPlayer();
    mixer.setVolume('Coffee Shop', .21);
    expect(app.isAmbientPlayerExpanded, isFalse);
    expect(app.active, {'Soft Rain': .65, 'Coffee Shop': .21});
    mixer.applyMix({'Ocean Waves': .6}, name: 'Shore');
    expect(app.isAmbientPlayerExpanded, isTrue);
  });

  test('paused session survives mini resume and paused level edits', () async {
    mixer.applyMix({'Soft Rain': .45}, name: 'Rain');
    app.minimizeAmbientPlayer();
    mixer.togglePlayback(expandPlayer: false);
    expect(app.hasAmbientSession, isTrue);
    expect(app.isAmbientPlayerExpanded, isFalse);
    expect(app.active, isEmpty);
    mixer.setVolume('Soft Rain', .41, preservePaused: true);
    expect(app.active, isEmpty);
    expect(mixer.volume('Soft Rain'), .41);
    expect(mixer.transportLabel, 'Resume soundscape');
    mixer.togglePlayback(expandPlayer: false);
    expect(app.active, {'Soft Rain': .41});
    expect(app.isAmbientPlayerExpanded, isFalse);
    await app.stopAllAudio();
    expect(app.hasAmbientSession, isFalse);
    expect(mixer.volume('Soft Rain'), .41);
  });

  test(
    'starting a timed practice replaces the ambient presentation owner',
    () async {
      mixer.applyMix({'Soft Rain': .45});
      expect(app.isAmbientPlayerExpanded, isTrue);
      await app.playGuidedSession('Gentle Relief & Comfort', 15);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(app.hasAmbientSession, isFalse);
      expect(app.isGuidedPlayerExpanded, isTrue);
      mixer.applyMix({'Ocean Waves': .6});
      expect(app.isGuidedPlayerExpanded, isFalse);
      expect(app.isAmbientPlayerExpanded, isTrue);
      expect(app.guidedPlaying, isFalse);
    },
  );

  test('volume edits are clamped, finite and persisted', () {
    mixer.setVolume('Soft Rain', 4);
    expect(mixer.volume('Soft Rain'), 1);
    mixer.setVolume('Soft Rain', double.nan);
    expect(mixer.volume('Soft Rain'), 1);
    mixer.setVolume('Soft Rain', -2);
    expect(mixer.volume('Soft Rain'), 0);
    expect(app.cached['Soft Rain'], 0);
    expect(mixer.isPlaying, isFalse);
  });

  test('a preset replaces active tracks instead of accumulating them', () {
    mixer.togglePlayback();
    mixer.applyMix({'Ocean Waves': 0.7, 'Bamboo Chimes': 0.2}, name: 'Beach');
    expect(app.active, {'Ocean Waves': 0.7, 'Bamboo Chimes': 0.2});
    expect(mixer.volume('Soft Rain'), 0);
    expect(mixer.preset, 'Beach');
  });

  test(
    'the shared controller follows audio changes from other screens',
    () async {
      mixer.togglePlayback();
      await app.stopAllAudio();
      await app.updateSoundTrackVolume('Campfire', 0.5);
      expect(mixer.levels, {'Campfire': 0.5});
      expect(mixer.isPlaying, isTrue);
    },
  );

  test('guided playback is not reported as an active ambient mixer', () async {
    await app.playGuidedSession('Gentle Relief & Comfort', 15);
    expect(app.isGuidedPlaying, isTrue);
    expect(mixer.isPlaying, isFalse);
    expect(mixer.levels, {'Soft Rain': 0.3});
    mixer.togglePlayback();
    expect(mixer.isPlaying, isTrue);
    expect(app.isGuidedPlaying, isFalse);
    expect(app.hasGuidedSession, isTrue);
  });

  test('shuffle selects exactly three independent tracks', () {
    mixer.shuffle();
    expect(mixer.selectedCount, 3);
    expect(mixer.levels.values.every((v) => v >= 0.3 && v <= 0.6), isTrue);
  });

  test('saving snapshots the mix and rejects empty names', () {
    expect(mixer.saveMix('   '), isFalse);
    expect(mixer.saveMix(' Rainy evening '), isTrue);
    mixer.setVolume('Soft Rain', 0.8);
    expect(app.saved.single.name, 'Rainy evening');
    expect(app.saved.single.volumes['Soft Rain'], 0.3);
  });

  test(
    'a paused share link includes selected levels and preserves the host',
    () {
      final uri = mixer.shareUri(
        base: Uri.parse('https://example.com/preview/?lang=en'),
      );
      expect(uri.host, 'example.com');
      expect(uri.path, '/preview/');
      expect(uri.queryParameters['lang'], 'en');
      expect(uri.queryParameters['mix'], 'Soft Rain:30');
      expect(mixer.isPlaying, isFalse);
    },
  );

  test(
    'categories accept the catalog and favorites, not arbitrary strings',
    () {
      mixer.selectCategory('nature');
      expect(mixer.category, 'nature');
      mixer.selectCategory('invalid-category');
      expect(mixer.category, 'nature');
      mixer.selectCategory('favorites');
      expect(mixer.category, 'favorites');
    },
  );
  test(
    'replacing one playing layer preserves its level and every other layer',
    () {
      mixer.applyMix({'Soft Rain': .63, 'Forest Birds': .21}, name: 'Original');
      expect(mixer.replaceTrack('Soft Rain', 'Ocean Waves'), isTrue);
      expect(mixer.levels, {'Ocean Waves': .63, 'Forest Birds': .21});
      expect(app.active, {'Ocean Waves': .63, 'Forest Birds': .21});
      expect(mixer.preset, isNull);
      expect(mixer.category, 'nature');
      expect(app.cached, mixer.levels);
    },
  );

  test(
    'a paused replacement stays paused, persists and can return to the original',
    () {
      expect(mixer.replaceTrack('Soft Rain', 'Ocean Waves'), isTrue);
      expect(app.active, isEmpty);
      expect(mixer.levels, {'Ocean Waves': .3});
      final restored = MixerController(app);
      expect(restored.levels, {'Ocean Waves': .3});
      expect(restored.isPlaying, isFalse);
      restored.dispose();
      expect(mixer.replaceTrack('Ocean Waves', 'Soft Rain'), isTrue);
      expect(mixer.levels, {'Soft Rain': .3});
      expect(app.active, isEmpty);
    },
  );

  test(
    'saving and sharing remember the replacement, not an invisible override',
    () {
      mixer.replaceTrack('Soft Rain', 'Ocean Waves');
      mixer.saveMix('New shoreline');
      expect(app.saved.single.volumes, {'Ocean Waves': .3});
      expect(mixer.shareUri().queryParameters['mix'], 'Ocean Waves:30');
      expect(mixer.isPlaying, isFalse);
    },
  );

  test(
    'an existing target or legacy alias cannot become a duplicate recording',
    () {
      mixer.applyMix({'Soft Rain': .4, 'Cozy Hearth': .2, 'Ocean Waves': .1});
      final before = mixer.levels;
      expect(mixer.replacementConflict('Soft Rain', 'Campfire'), 'Cozy Hearth');
      expect(mixer.replaceTrack('Soft Rain', 'Campfire'), isFalse);
      expect(mixer.replaceTrack('Soft Rain', 'Ocean Waves'), isFalse);
      expect(mixer.levels, before);
      expect(mixer.replaceTrack('Soft Rain', 'Temple Bowl'), isTrue);
    },
  );

  test('no-op, unknown and unbundled replacements leave the mix untouched', () {
    final before = mixer.levels;
    expect(mixer.replaceTrack('Soft Rain', 'Soft Rain'), isFalse);
    expect(mixer.replaceTrack('not a sound', 'Ocean Waves'), isFalse);
    expect(mixer.replaceTrack('Soft Rain', 'Rain on Leaves'), isFalse);
    expect(mixer.replaceTrack('Soft Rain', 'new.mp3'), isFalse);
    expect(mixer.levels, before);
    expect(app.active, isEmpty);
  });

  test(
    'replacing an off card selects the bundled layer at 30 percent without autoplay',
    () {
      expect(mixer.replaceTrack('Rain Cave', 'Ocean Waves'), isTrue);
      expect(mixer.levels, {'Soft Rain': .3, 'Ocean Waves': .3});
      expect(mixer.isPlaying, isFalse);
    },
  );

  test('pending requests stay cancellable without claiming playback', () {
    app.ambientLoading.add('Soft Rain');
    mixer.togglePlayback();
    expect(mixer.hasPlaybackRequest, isTrue);
    expect(mixer.isPreparing, isTrue);
    expect(mixer.isPlaying, isFalse);
    expect(mixer.playbackStatusLabel, 'Loading soundscape…');
    expect(mixer.transportLabel, 'Cancel pending soundscape');
    mixer.togglePlayback();
    expect(app.requestedAmbientTracks, isEmpty);
    expect(mixer.isPreparing, isFalse);
    expect(mixer.volume('Soft Rain'), .3);
    expect(app.cached['Soft Rain'], .3);
  });

  test('buffering does not change selected levels or the confirmed count', () {
    mixer.applyMix({'Soft Rain': .6, 'Ocean Waves': .2}, name: 'Evening');
    app.ambientBuffering.add('Soft Rain');
    app.notifyListeners();
    expect(mixer.levels, {'Soft Rain': .6, 'Ocean Waves': .2});
    expect(mixer.preset, 'Evening');
    expect(mixer.playbackStatusLabel, 'Playing · 1 layer · 1 buffering');
    expect(app.activeAmbientTracks, {'Ocean Waves': .2});
    app.ambientBuffering.clear();
    app.notifyListeners();
    expect(mixer.playbackStatusLabel, 'Playing · 2 layers');
  });

  test(
    'replacing a pending layer keeps intent without starting a paused mix',
    () {
      app.ambientLoading.add('Soft Rain');
      mixer.setVolume('Soft Rain', .58);
      expect(mixer.isPlaying, isFalse);
      expect(mixer.replaceTrack('Soft Rain', 'Ocean Waves'), isTrue);
      expect(app.requestedAmbientTracks, {'Ocean Waves': .58});
      expect(mixer.isPlaying, isTrue);
      mixer.togglePlayback();
      expect(mixer.replaceTrack('Ocean Waves', 'Campfire'), isTrue);
      expect(app.requestedAmbientTracks, isEmpty);
      expect(mixer.levels, {'Campfire': .58});
    },
  );

  test('failure removes a playing count, not the failed selected level', () {
    mixer.applyMix({'Soft Rain': .6, 'Ocean Waves': .2}, name: 'Evening');
    app.active.remove('Soft Rain');
    app.ambientErrors['Soft Rain'] = 'This recording could not play.';
    app.notifyListeners();
    expect(mixer.levels, {'Soft Rain': .6, 'Ocean Waves': .2});
    expect(mixer.preset, 'Evening');
    expect(mixer.hasPlaybackError, isTrue);
    expect(mixer.playbackStatusLabel, 'Playing · 1 layer · 1 unavailable');
    mixer.togglePlayback();
    expect(app.active, isEmpty);
    mixer.togglePlayback();
    expect(app.active, {'Soft Rain': .6, 'Ocean Waves': .2});
    expect(mixer.hasPlaybackError, isFalse);
  });

  test(
    'retry keeps every failed selected level and does not reapply healthy layers',
    () {
      mixer.applyMix({
        'Soft Rain': .6,
        'Ocean Waves': .2,
        'Forest Birds': .15,
      }, name: 'Evening');
      app.active.remove('Soft Rain');
      app.active.remove('Forest Birds');
      app.ambientErrors.addAll({
        'Soft Rain': 'Unavailable',
        'Forest Birds': 'Unavailable',
      });
      app.notifyListeners();
      expect(mixer.retryTrack('Ocean Waves'), isFalse);
      expect(mixer.retryTrack('not a sound'), isFalse);
      expect(mixer.retryTrack('Soft Rain'), isTrue);
      expect(mixer.levels, {
        'Soft Rain': .6,
        'Ocean Waves': .2,
        'Forest Birds': .15,
      });
      expect(mixer.preset, 'Evening');
      expect(app.activeAmbientTracks, {'Soft Rain': .6, 'Ocean Waves': .2});
      expect(app.ambientTrackError('Forest Birds'), isNotNull);
      expect(mixer.playbackStatusLabel, 'Playing · 2 layers · 1 unavailable');
      expect(mixer.retryTrack('Forest Birds'), isTrue);
      expect(mixer.playbackStatusLabel, 'Playing · 3 layers');
    },
  );

  test('gain edits retain platform-paused layers until explicit Resume', () {
    mixer.applyMix({'Soft Rain': .6, 'Ocean Waves': .2}, name: 'Evening');
    app.ambientPaused.addAll(app.active.keys);
    app.notifyListeners();
    expect(mixer.isPlaying, isFalse);
    expect(mixer.hasPlaybackRequest, isTrue);
    mixer.setVolume('Soft Rain', .54, preservePaused: true);
    expect(app.active, {'Soft Rain': .54, 'Ocean Waves': .2});
    expect(app.activeAmbientTracks, isEmpty);
    expect(app.ambientPaused, {'Soft Rain', 'Ocean Waves'});
    expect(mixer.transportLabel, 'Resume soundscape');
    expect(app.cached, {'Soft Rain': .54, 'Ocean Waves': .2});
    mixer.togglePlayback(expandPlayer: false);
    expect(app.activeAmbientTracks, {'Soft Rain': .54, 'Ocean Waves': .2});
  });

  test('Sounds gain edits are not transport commands during interruption', () {
    mixer.applyMix({'Soft Rain': .6, 'Ocean Waves': .2});
    app.ambientPaused.add('Soft Rain');
    app.notifyListeners();
    mixer.setVolume('Ocean Waves', .24);
    expect(app.activeAmbientTracks, {'Ocean Waves': .24});
    expect(app.ambientPaused, {'Soft Rain'});
    expect(mixer.playbackStatusLabel, 'Playing · 1 layer · 1 paused');
  });

  test('gain edits never retry this or unrelated failed selected layers', () {
    mixer.applyMix({
      'Soft Rain': .6,
      'Ocean Waves': .2,
      'Forest Birds': .15,
    }, name: 'Evening');
    app.active.remove('Soft Rain');
    app.active.remove('Forest Birds');
    app.ambientErrors.addAll({
      'Soft Rain': 'Unavailable',
      'Forest Birds': 'Unavailable',
    });
    app.notifyListeners();
    mixer.setVolume('Ocean Waves', .24, preservePaused: true);
    mixer.setVolume('Soft Rain', .53, preservePaused: true);
    expect(app.activeAmbientTracks, {'Ocean Waves': .24});
    expect(app.ambientErrors.keys.toSet(), {'Soft Rain', 'Forest Birds'});
    expect(mixer.levels, {
      'Soft Rain': .53,
      'Ocean Waves': .24,
      'Forest Birds': .15,
    });
    expect(mixer.retryTrack('Soft Rain'), isTrue);
    expect(app.activeAmbientTracks, {'Ocean Waves': .24, 'Soft Rain': .53});
    expect(app.ambientTrackError('Forest Birds'), isNotNull);
    expect(mixer.volume('Forest Birds'), .15);
  });

  test('default library is all bundled sources, with honest scoped counts', () {
    expect(mixer.availableOnly, isTrue);
    expect(mixer.category, 'all');
    expect(
      allMixerTracks
          .where(mixer.isVisibleTrack)
          .map((track) => track.name)
          .toSet(),
      bundledRecordings.map((recording) => recording.name).toSet(),
    );
    expect(mixer.categoryCount('all'), 18);
    expect(mixer.categoryCount('rain'), 1);
    expect(mixer.categoryCount('solfeggio'), 0);
    expect(
      AppState.curatedPresets.values.where(mixer.isVisiblePreset),
      hasLength(11),
    );
    mixer.setAvailableOnly(false);
    expect(allMixerTracks.where(mixer.isVisibleTrack), hasLength(77));
    expect(mixer.categoryCount('rain'), 12);
    expect(
      AppState.curatedPresets.values.where(mixer.isVisiblePreset),
      hasLength(18),
    );
    expect(app.active, isEmpty);
    expect(app.cached, isEmpty);
  });

  test(
    'scope changes preserve legacy cached levels, favorites and saved mixes',
    () {
      app.cached = {'Rain on Umbrella': .22, 'Soft Rain': .31};
      app.savePreset('Kept', {'Rain on Umbrella': .22});
      app.starred.add('Rain on Umbrella');
      app.notifyListeners();
      final levels = Map<String, double>.of(mixer.levels);
      final favorites = Set<String>.of(app.starred);
      mixer.setAvailableOnly(false);
      mixer.selectCategory('solfeggio');
      mixer.setAvailableOnly(true);
      expect(
        mixer.category,
        'all',
        reason: 'An empty scoped category returns to All',
      );
      mixer.selectCategory('favorites');
      mixer.setAvailableOnly(false);
      expect(mixer.category, 'favorites');
      expect(mixer.levels, levels);
      expect(app.cached, levels);
      expect(app.saved.single.volumes, {'Rain on Umbrella': .22});
      expect(app.starred, favorites);
      expect(app.active, isEmpty);
    },
  );

  test('changing a library view never pauses or reapplies a playing mix', () {
    mixer.applyMix({'Soft Rain': .42, 'Fireplace': .2}, name: 'Kept recipe');
    final levels = Map<String, double>.of(mixer.levels);
    mixer.setAvailableOnly(false);
    mixer.selectCategory('favorites');
    mixer.setAvailableOnly(true);
    expect(mixer.levels, levels);
    expect(app.active, levels);
    expect(mixer.preset, 'Kept recipe');
  });

  test(
    'shuffle always chooses three different canonical bundled recordings',
    () {
      final canonical = bundledRecordings
          .map((recording) => recording.name)
          .toSet();
      for (var index = 0; index < 20; index++) {
        mixer.shuffle();
        expect(mixer.levels, hasLength(3));
        expect(canonical.containsAll(mixer.levels.keys), isTrue);
        expect(
          mixer.levels.keys.map((name) => bundledSoundAssets[name]).toSet(),
          hasLength(3),
        );
        expect(
          mixer.levels.values.every((level) => level >= .3 && level <= .6),
          isTrue,
        );
      }
    },
  );
}
