import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

import 'support/fake_ambient_audio_player.dart';
import 'support/inert_audio_player.dart';

Future<void> flushAmbient() async {
  for (var i = 0; i < 24; i++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppState app;
  late List<FakeAmbientAudioPlayer> players;
  late FakeAmbientAudioPlayer Function() factory;
  setUp(() {
    players = [];
    factory = FakeAmbientAudioPlayer.new;
    app = AppState(
      guidedPlayer: InertAudioPlayer(),
      ambientPlayerFactory: () {
        final player = factory();
        players.add(player);
        return player;
      },
    );
  });
  tearDown(() => app.dispose());

  test('unknown catalog sounds never fall back to unrelated rain', () async {
    await app.updateSoundTrackVolume('Rain Cave', .6);
    expect(players, isEmpty);
    expect(app.activeAmbientTracks, isEmpty);
    expect(
      app.ambientTrackError('Rain Cave'),
      contains('No recording is configured'),
    );
    expect(AppState.hasAmbientSource('Rain Cave'), isFalse);
    expect(AppState.hasAmbientSource('Rain on Leaves'), isTrue);
  });

  test(
    'non-finite inputs neither create audio nor change an existing level',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .4);
      await app.updateSoundTrackVolume('Soft Rain', double.nan);
      await app.updateSoundTrackVolume('Soft Rain', double.infinity);
      expect(players, hasLength(1));
      expect(app.getTrackVolume('Soft Rain'), .4);
    },
  );

  test(
    'local loading finishes without waiting for the looping play future',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players.single.sources, ['assets/sounds/soft_rain.mp3']);
      expect(players.single.loop, LoopMode.one);
      expect(players.single.audible, isTrue);
      expect(players.single.plays.single.isCompleted, isFalse);
      expect(app.isAmbientTrackLoading('Soft Rain'), isFalse);
      await app.updateSoundTrackVolume('Soft Rain', 0);
      expect(players.single.audible, isFalse);
    },
  );

  test(
    'local failure can load the named CDN source, not a different sound',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failFirstLoads = 1;
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players.single.sources, [
        'assets/sounds/soft_rain.mp3',
        'https://cdn.jsdelivr.net/gh/remvze/moodist@main/public/sounds/rain/light-rain.mp3',
      ]);
      expect(players.single.audible, isTrue);
      expect(app.ambientTrackError('Soft Rain'), isNull);
    },
  );

  test(
    'failed sources produce a safe retryable error, not active silence',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failLoads = true;
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players.single.sources, hasLength(3));
      expect(players.single.playCalls, 0);
      expect(players.single.disposed, isTrue);
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.isAmbientTrackLoading('Soft Rain'), isFalse);
      expect(app.ambientTrackError('Soft Rain'), contains('could not play'));
      expect(app.ambientTrackError('Soft Rain'), isNot(contains('private')));
      factory = FakeAmbientAudioPlayer.new;
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players, hasLength(2));
      expect(players.last.audible, isTrue);
      expect(app.ambientTrackError('Soft Rain'), isNull);
    },
  );

  test(
    'a playback failure stops only that layer and restores headroom',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .7);
      await app.updateSoundTrackVolume('Ocean Waves', .7);
      players.first.events.addError(
        StateError('private event payload'),
        StackTrace.current,
      );
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Ocean Waves': .7});
      expect(players.first.disposed, isTrue);
      expect(players.last.audible, isTrue);
      expect(players.last.volume, closeTo(.7, .0001));
      expect(app.ambientTrackError('Soft Rain'), contains('could not play'));
    },
  );

  test('a rejected play future cannot remain an active silent layer', () async {
    factory = () => FakeAmbientAudioPlayer()..failPlay = true;
    await app.updateSoundTrackVolume('Soft Rain', .4);
    await flushAmbient();
    expect(app.activeAmbientTracks, isEmpty);
    expect(players.single.disposed, isTrue);
    expect(app.ambientTrackError('Soft Rain'), isNotNull);
  });

  test(
    'preview ducking leaves levels intact and cannot start a paused mix',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .7);
      await app.updateSoundTrackVolume('Ocean Waves', .7);
      final before = Map.of(app.activeAmbientTracks);
      app.setAmbientPreviewDucking(true);
      expect(app.activeAmbientTracks, before);
      expect(
        players.every((player) => (player.volume - .1).abs() < .0001),
        isTrue,
      );
      app.setAmbientPreviewDucking(false);
      expect(
        players.every((player) => (player.volume - .5).abs() < .0001),
        isTrue,
      );
      await app.stopAllAudio();
      final calls = players.map((player) => player.playCalls).toList();
      app.setAmbientPreviewDucking(true);
      app.setAmbientPreviewDucking(false);
      expect(players.map((player) => player.playCalls).toList(), calls);
      expect(
        players.every((player) => !player.audible && player.volume == 0),
        isTrue,
      );
    },
  );

  test(
    'turning off a loading sound blocks late play and does not revive it',
    () async {
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final loading = app.updateSoundTrackVolume('Soft Rain', .4);
      await flushAmbient();
      expect(app.isAmbientTrackLoading('Soft Rain'), isTrue);
      await app.updateSoundTrackVolume('Soft Rain', 0);
      gate.complete(const Duration(seconds: 30));
      await loading;
      expect(players.single.playCalls, 0);
      expect(players.single.disposed, isTrue);
      expect(app.activeAmbientTracks, isEmpty);
    },
  );

  test(
    'a rapid off/on cannot let the old load own or stop the new player',
    () async {
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final oldLoad = app.updateSoundTrackVolume('Soft Rain', .2);
      await flushAmbient();
      await app.updateSoundTrackVolume('Soft Rain', 0);
      factory = FakeAmbientAudioPlayer.new;
      await app.updateSoundTrackVolume('Soft Rain', .8);
      gate.complete(const Duration(seconds: 30));
      await oldLoad;
      expect(players.first.playCalls, 0);
      expect(players.last.audible, isTrue);
      expect(app.activeAmbientTracks, {'Soft Rain': .8});
    },
  );

  test(
    'the sleep timer still fades ducked playback and stops all layers',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .5);
      app.startSleepTimer(1);
      app.setAmbientPreviewDucking(true);
      expect(players.single.volume, closeTo(.1, .0001));
      app.cancelSleepTimer();
      app.setAmbientPreviewDucking(false);
      expect(players.single.volume, closeTo(.5, .0001));
      await app.stopAllAudio();
      expect(players.single.audible, isFalse);
    },
  );
}
