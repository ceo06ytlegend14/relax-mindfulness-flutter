import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/models/vibe_sound_sets.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';

import 'support/fake_ambient_audio_player.dart';
import 'support/fake_mixer_app_state.dart';
import 'support/inert_audio_player.dart';

const requestedMixLevels = <String, Map<String, double>>{
  'Rainy Window Café': {
    'Soft Rain': 0.65,
    'Coffee Shop': 0.25,
    'Brown Noise': 0.15,
    'Bamboo Chimes': 0.10,
  },
  'Enchanted Forest Morning': {
    'Woodland Morning': 0.65,
    'Forest Birds': 0.55,
    'Meadow Breeze': 0.25,
    'Mountain Stream': 0.20,
  },
  'Ocean Deep Sleep': {
    'Ocean Waves': 0.65,
    'Brown Noise': 0.35,
    'Crickets': 0.15,
  },
  'Mountain Meditation': {
    'Mountain Stream': 0.50,
    'Meadow Breeze': 0.30,
    'Forest Birds': 0.25,
    'Temple Bowl': 0.15,
  },
  'Cozy Fireplace Night': {
    'Fireplace': 0.65,
    'Crickets': 0.30,
    'Soft Rain': 0.20,
    'Brown Noise': 0.15,
  },
  'Tropical Rainforest': {
    'Mountain Stream': 0.55,
    'Soft Rain': 0.40,
    'Forest Birds': 0.40,
    'Meadow Breeze': 0.15,
  },
  'Zen Temple Sanctuary': {
    'Temple Bowl': 0.55,
    'Meadow Breeze': 0.25,
    'Mountain Stream': 0.20,
    'Bamboo Chimes': 0.15,
  },
  'Midnight Focus': {
    'Brown Noise': 0.55,
    'White Noise': 0.30,
    'Coffee Shop': 0.15,
    'Soft Rain': 0.10,
  },
  'Campfire Under Stars': {
    'Campfire': 0.65,
    'Crickets': 0.50,
    'Meadow Breeze': 0.20,
    'Ocean Waves': 0.10,
  },
  'Peaceful Ocean Journey': {
    'Boat Deck': 0.45,
    'Ocean Waves': 0.65,
    'Meadow Breeze': 0.20,
    'Bamboo Chimes': 0.10,
  },
};

const requestedMixPurposes = <String, String>{
  'Rainy Window Café': 'Focus',
  'Enchanted Forest Morning': 'Morning',
  'Ocean Deep Sleep': 'Sleep',
  'Mountain Meditation': 'Meditate',
  'Cozy Fireplace Night': 'Comfort',
  'Tropical Rainforest': 'Relax',
  'Zen Temple Sanctuary': 'Meditate',
  'Midnight Focus': 'Focus',
  'Campfire Under Stars': 'Relax',
  'Peaceful Ocean Journey': 'Escape',
};

Future<void> flushVibeLoads() async {
  for (var i = 0; i < 32; i++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ten requested canonical local recipes retain independent slider levels',
    () {
      expect(vibeSoundSets, hasLength(10));
      expect(vibeSoundSets.map((set) => set.name), requestedMixLevels.keys);
      expect(
        vibeSoundSets.map((soundSet) => soundSet.id).toSet(),
        hasLength(10),
      );
      expect(
        vibeSoundSets.map((soundSet) => soundSet.name).toSet(),
        hasLength(10),
      );
      final signatures = <String>{};
      final used = <String>{};
      for (final soundSet in vibeSoundSets) {
        expect(soundSet.levels, requestedMixLevels[soundSet.name]);
        expect(soundSet.purpose, requestedMixPurposes[soundSet.name]);
        expect(soundSet.levels.length, inInclusiveRange(3, 4));
        final assets = <String>{};
        var sum = 0.0;
        for (final entry in soundSet.levels.entries) {
          final recording = bundledRecordings.singleWhere(
            (recording) => recording.name == entry.key,
          );
          expect(AppState.localSoundAssets[entry.key], recording.assetPath);
          expect(
            assets.add(recording.assetPath),
            isTrue,
            reason: 'Aliases cannot duplicate a recording',
          );
          expect(entry.value, inInclusiveRange(.10, .65));
          sum += entry.value;
          used.add(entry.key);
        }
        expect(sum, inInclusiveRange(1.10 - .000001, 1.65 + .000001));
        final signature = (assets.toList()..sort()).join('|');
        expect(signatures.add(signature), isTrue, reason: soundSet.name);
      }
      expect(used, hasLength(15));
    },
  );

  test(
    'recipe text and name lookup do not identify a different custom mix',
    () {
      final soundSet = vibeSoundSetForName('Rainy Window Café')!;
      expect(
        soundSet.recipe,
        'Soft Rain 65% · Coffee Shop 25% · Brown Noise 15% · Bamboo Chimes 10%',
      );
      expect(soundSet.matchesLevels(Map.of(soundSet.levels)), isTrue);
      expect(soundSet.matchesLevels({'Soft Rain': .19}), isFalse);
      expect(
        soundSet.matchesLevels({...soundSet.levels, 'Ocean Waves': .1}),
        isFalse,
      );
      expect(vibeSoundSetForName('not a set'), isNull);
      expect(vibeSoundSetForName(null), isNull);
      expect(() => soundSet.levels['Soft Rain'] = .9, throwsUnsupportedError);
    },
  );

  test(
    'new curated sets lead the existing eight without mutating old names or maps',
    () {
      expect(AppState.curatedPresets, hasLength(18));
      expect(
        AppState.curatedPresets.keys.take(10),
        vibeSoundSets.map((soundSet) => soundSet.name),
      );
      expect(AppState.curatedPresets['🌧️ Rainy Cabin'], {
        'Soft Rain': .70,
        'Cozy Hearth': .35,
        'Ambient Piano': .20,
      });
      expect(AppState.curatedPresets['🕊️ Peace Flow'], {
        'Ambient Piano': .65,
        'Soft Rain': .30,
        'Singing Bowls': .25,
      });
      for (final soundSet in vibeSoundSets) {
        expect(AppState.curatedPresets[soundSet.name], soundSet.levels);
      }
      expect(
        () => AppState.curatedPresets.remove('Rainy Window Café'),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'restoring a selection and exposing ten set choices never autoplays or changes saved mixes',
    () {
      final app = FakeMixerAppState()..cached = {'Ocean Waves': .27};
      app.savePreset('My kept shoreline', {'Ocean Waves': .27});
      final mixer = MixerController(app);
      addTearDown(() {
        mixer.dispose();
        app.dispose();
      });
      expect(vibeSoundSets, hasLength(10));
      expect(mixer.levels, {'Ocean Waves': .27});
      expect(app.requestedAmbientTracks, isEmpty);
      expect(mixer.isPlaying, isFalse);
      expect(app.saved.single.name, 'My kept shoreline');
      expect(app.saved.single.volumes, {'Ocean Waves': .27});
    },
  );

  for (final soundSet in vibeSoundSets) {
    test(
      'native preset ${soundSet.name} starts its exact bundled layers',
      () async {
        final players = <FakeAmbientAudioPlayer>[];
        final app = AppState(
          guidedPlayer: InertAudioPlayer(),
          ambientPlayerFactory: () {
            final player = FakeAmbientAudioPlayer();
            players.add(player);
            return player;
          },
        );
        addTearDown(app.dispose);
        await app.applyCuratedPreset(soundSet.name);
        expect(app.requestedAmbientTracks, soundSet.levels);
        expect(app.activeAmbientTracks, soundSet.levels);
        expect(players, hasLength(soundSet.levels.length));
        expect(
          players.map((player) => player.sources.single).toSet(),
          soundSet.levels.keys.map((name) => bundledSoundAssets[name]!).toSet(),
        );
        for (final player in players) {
          final source = player.sources.single;
          final name = soundSet.levels.keys.singleWhere(
            (name) => bundledSoundAssets[name] == source,
          );
          final total = soundSet.levels.values.fold<double>(
            0,
            (sum, level) => sum + level,
          );
          expect(
            player.volume,
            closeTo(soundSet.levels[name]! / total, .000001),
          );
          expect(
            app.getTrackVolume(name),
            soundSet.levels[name],
            reason: 'Output gain does not rewrite the selected level',
          );
          expect(player.playCalls, 1);
          expect(player.plays.single.isCompleted, isFalse);
        }
      },
    );
  }

  test(
    'switching native sets reuses shared loops and silences removed layers',
    () async {
      final players = <FakeAmbientAudioPlayer>[];
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        ambientPlayerFactory: () {
          final player = FakeAmbientAudioPlayer();
          players.add(player);
          return player;
        },
      );
      addTearDown(app.dispose);
      await app.applyCuratedPreset('Rainy Window Café');
      final rain = players.singleWhere(
        (player) => player.sources.single == bundledSoundAssets['Soft Rain'],
      );
      final brown = players.singleWhere(
        (player) => player.sources.single == bundledSoundAssets['Brown Noise'],
      );
      final chimes = players.singleWhere(
        (player) =>
            player.sources.single == bundledSoundAssets['Bamboo Chimes'],
      );
      await app.applyCuratedPreset('Midnight Focus');
      expect(
        app.activeAmbientTracks,
        vibeSoundSetForName('Midnight Focus')!.levels,
      );
      expect(players, hasLength(5));
      expect(rain.sources, hasLength(1));
      expect(brown.sources, hasLength(1));
      expect(rain.playCalls, 1);
      expect(brown.playCalls, 1);
      expect(rain.volume, closeTo(.10 / 1.10, .000001));
      expect(brown.volume, closeTo(.55 / 1.10, .000001));
      expect(chimes.playing, isFalse);
      expect(chimes.volume, 0);
    },
  );

  test(
    'a failed bundled ingredient preserves its recipe and retries alone',
    () async {
      final players = <FakeAmbientAudioPlayer>[];
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        ambientPlayerFactory: () {
          final player = FakeAmbientAudioPlayer()..failLoads = players.isEmpty;
          players.add(player);
          return player;
        },
      );
      final mixer = MixerController(app);
      addTearDown(() {
        mixer.dispose();
        app.dispose();
      });
      final soundSet = vibeSoundSetForName('Enchanted Forest Morning')!;
      mixer.applyMix(soundSet.levels, name: soundSet.name);
      await flushVibeLoads();
      expect(mixer.levels, soundSet.levels);
      expect(mixer.preset, soundSet.name);
      expect(app.activeAmbientTracks, {
        'Forest Birds': .55,
        'Meadow Breeze': .25,
        'Mountain Stream': .20,
      });
      expect(app.ambientTrackError('Woodland Morning'), isNotNull);
      expect(players.first.sources, [bundledSoundAssets['Woodland Morning']]);
      expect(mixer.retryTrack('Woodland Morning'), isTrue);
      await flushVibeLoads();
      expect(app.activeAmbientTracks, soundSet.levels);
      expect(mixer.preset, soundSet.name);
      expect(players, hasLength(5));
      expect(players[1].playCalls, 1);
      expect(players[2].playCalls, 1);
      expect(players[3].playCalls, 1);
      expect(players.last.volume, closeTo(.65 / 1.65, .000001));
    },
  );

  test(
    'unknown preset names leave a currently playing source untouched',
    () async {
      final players = <FakeAmbientAudioPlayer>[];
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        ambientPlayerFactory: () {
          final player = FakeAmbientAudioPlayer();
          players.add(player);
          return player;
        },
      );
      addTearDown(app.dispose);
      await app.updateSoundTrackVolume('Soft Rain', .22);
      await app.applyCuratedPreset('not a set');
      expect(app.activeAmbientTracks, {'Soft Rain': .22});
      expect(players, hasLength(1));
      expect(players.single.playCalls, 1);
      expect(players.single.pauseCalls, 0);
    },
  );

  test(
    'a named preset link includes recordings absent from the remote URL map',
    () async {
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        ambientPlayerFactory: FakeAmbientAudioPlayer.new,
      );
      addTearDown(app.dispose);
      final soundSet = vibeSoundSetForName('Enchanted Forest Morning')!;
      expect(
        soundSet.levels.keys.where(
          (name) => !AppState.soundStreamUrls.containsKey(name),
        ),
        unorderedEquals([
          'Woodland Morning',
          'Meadow Breeze',
          'Mountain Stream',
        ]),
      );
      app.parseAndApplyMixFromUri(
        Uri.https('example.test', '/', {'preset': soundSet.name}),
      );
      await flushVibeLoads();
      expect(app.activeAmbientTracks, soundSet.levels);
    },
  );

  test(
    'a pending first ingredient cannot serialize or revive a cancelled preset',
    () async {
      final gate = Completer<Duration?>();
      final players = <FakeAmbientAudioPlayer>[];
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        ambientPlayerFactory: () {
          final player = FakeAmbientAudioPlayer();
          if (players.isEmpty) player.loadGate = gate;
          players.add(player);
          return player;
        },
      );
      addTearDown(app.dispose);
      final loading = app.applyCuratedPreset('Rainy Window Café');
      await flushVibeLoads();
      expect(players, hasLength(4));
      expect(
        app.activeAmbientTracks.keys,
        unorderedEquals(['Coffee Shop', 'Brown Noise', 'Bamboo Chimes']),
      );
      await app.stopAllAudio();
      await app.applyCuratedPreset('Peaceful Ocean Journey');
      gate.complete(const Duration(seconds: 30));
      await loading;
      expect(players.first.disposed, isTrue);
      expect(players.first.playCalls, 0);
      expect(
        app.activeAmbientTracks,
        vibeSoundSetForName('Peaceful Ocean Journey')!.levels,
      );
    },
  );

  test(
    'selected set levels, save and share survive master pause and resume',
    () {
      final app = FakeMixerAppState();
      final mixer = MixerController(app);
      addTearDown(() {
        mixer.dispose();
        app.dispose();
      });
      final soundSet = vibeSoundSetForName('Midnight Focus')!;
      mixer.applyMix(soundSet.levels, name: soundSet.name);
      expect(mixer.preset, soundSet.name);
      expect(mixer.saveMix('My quiet desk'), isTrue);
      mixer.togglePlayback();
      expect(app.activeAmbientTracks, isEmpty);
      expect(mixer.levels, soundSet.levels);
      final mix = mixer.shareUri().queryParameters['mix']!;
      expect(mix, 'Brown Noise:55,White Noise:30,Coffee Shop:15,Soft Rain:10');
      expect(app.saved.single.volumes, soundSet.levels);
      mixer.togglePlayback();
      expect(app.activeAmbientTracks, soundSet.levels);
      expect(mixer.preset, soundSet.name);
    },
  );

  test(
    'loading a requested preset stops all unrelated native sources',
    () async {
      final players = <FakeAmbientAudioPlayer>[];
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        ambientPlayerFactory: () {
          final player = FakeAmbientAudioPlayer();
          players.add(player);
          return player;
        },
      );
      addTearDown(app.dispose);
      await app.updateSoundTrackVolume('Pink Noise', .47);
      final prior = players.single;
      await app.applyCuratedPreset('Rainy Window Café');
      expect(
        app.requestedAmbientTracks,
        requestedMixLevels['Rainy Window Café'],
      );
      expect(app.activeAmbientTracks, requestedMixLevels['Rainy Window Café']);
      expect(app.getTrackVolume('Pink Noise'), 0);
      expect(prior.volume, 0);
      expect(prior.playing, isFalse);
    },
  );

  test(
    'customized mixes save separately from immutable official recipes and old snapshots',
    () {
      final app = FakeMixerAppState();
      final old = {'Soft Rain': .42, 'Fireplace': .20, 'Brown Noise': .08};
      app.savePreset('Rainlit Cabin', old);
      final mixer = MixerController(app);
      addTearDown(() {
        mixer.dispose();
        app.dispose();
      });
      final soundSet = vibeSoundSetForName('Rainy Window Café')!;
      mixer.applyMix(soundSet.levels, name: soundSet.name);
      mixer.setVolume('Soft Rain', .41);
      final custom = {...soundSet.levels, 'Soft Rain': .41};
      expect(mixer.preset, isNull);
      expect(mixer.saveMix('My window café'), isTrue);
      expect(app.saved.last.volumes, custom);
      expect(soundSet.levels, requestedMixLevels[soundSet.name]);
      expect(soundSet.matchesLevels(custom), isFalse);
      mixer.applyMix(soundSet.levels, name: soundSet.name);
      expect(mixer.levels, requestedMixLevels[soundSet.name]);
      expect(app.saved.last.volumes, custom);
      expect(app.saved.first.volumes, old);
      expect(() => soundSet.levels['Soft Rain'] = .01, throwsUnsupportedError);
      expect(mapEquals(app.saved.last.volumes, soundSet.levels), isFalse);
    },
  );
}
