import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';

import 'support/fake_ambient_audio_player.dart';
import 'support/inert_audio_player.dart';

Future<void> flushAmbient() async {
  for (var i = 0; i < 24; i++) {
    await Future<void>.value();
  }
}

Future<void> flushAmbientWidget(WidgetTester tester) async {
  // Stream cancellation/closure can finish on the real event queue. Drain both
  // zones without advancing the fake sleep/readiness clock or relaxing asserts.
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
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

  test(
    'ambient presentation never owns, reloads or seeks a healthy native loop',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .4);
      final player = players.single;
      expect(app.isAmbientPlayerExpanded, isTrue);
      expect(player.playCalls, 1);
      app.minimizeAmbientPlayer();
      app.showAmbientPlayer();
      app.minimizeAmbientPlayer();
      expect(app.hasAmbientSession, isTrue);
      expect(player.playCalls, 1);
      expect(player.sources, ['assets/sounds/loop_soft_rain.mp3']);
      await app.updateSoundTrackVolume('Soft Rain', .39);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(player.playCalls, 1);
      expect(player.sources, hasLength(1));
      await app.pauseAllAmbientSoundTracks();
      expect(app.hasAmbientSession, isTrue);
      expect(app.activeAmbientTracks, isEmpty);
      await app.updateSoundTrackVolume('Soft Rain', .39);
      expect(identical(players.single, player), isTrue);
      expect(player.playCalls, 2);
      expect(player.sources, hasLength(1));
      expect(app.isAmbientPlayerExpanded, isFalse);
      await app.stopAllAudio();
      expect(app.hasAmbientSession, isFalse);
      expect(app.isAmbientPlayerExpanded, isFalse);
    },
  );

  test(
    'real mixer switches create a collapsed native session without restarting healthy sources',
    () async {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      mixer.toggleTrack('Fireplace');
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Soft Rain': .3, 'Fireplace': .3});
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(players, hasLength(2));
      expect(
        players.every(
          (player) => player.playCalls == 1 && player.sources.length == 1,
        ),
        isTrue,
      );
      final rain = players.firstWhere(
        (player) => player.sources.single == 'assets/sounds/loop_soft_rain.mp3',
      );
      app.showAmbientPlayer();
      expect(app.isAmbientPlayerExpanded, isTrue);
      expect(
        players.every(
          (player) => player.playCalls == 1 && player.sources.length == 1,
        ),
        isTrue,
      );
      app.minimizeAmbientPlayer();
      mixer.toggleTrack('Fireplace');
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Soft Rain': .3});
      expect(rain.playCalls, 1);
      expect(rain.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(app.isAmbientPlayerExpanded, isFalse);
      mixer.toggleTrack('Soft Rain');
      await flushAmbient();
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.hasAmbientSession, isFalse);
      mixer.toggleTrack('Fireplace');
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Fireplace': .3});
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
    },
  );

  test(
    'an inline native failure and same-source retry never force the full player open',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failLoads = true;
      await app.updateSoundTrackVolume('Soft Rain', .4, expandPlayer: false);
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(app.ambientTrackError('Soft Rain'), isNotNull);
      expect(players.single.sources, ['assets/sounds/loop_soft_rain.mp3']);
      factory = FakeAmbientAudioPlayer.new;
      await app.updateSoundTrackVolume('Soft Rain', .4, expandPlayer: false);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(app.activeAmbientTracks, {'Soft Rain': .4});
      expect(players.last.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(players.last.playCalls, 1);
    },
  );

  test(
    'canceling the first inline native load fences late presentation as well as playback',
    () async {
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final pending = app.updateSoundTrackVolume(
        'Fireplace',
        .3,
        expandPlayer: false,
      );
      await flushAmbient();
      expect(app.hasAmbientSession, isTrue);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(app.isAmbientPlaybackPending, isTrue);
      final player = players.single;
      await app.stopAllAudio();
      gate.complete(const Duration(seconds: 30));
      await pending;
      await flushAmbient();
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.hasAmbientSession, isFalse);
      expect(app.isAmbientPlayerExpanded, isFalse);
      expect(player.playCalls, 0);
      expect(player.disposed, isTrue);
    },
  );

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

  test('new local-only sounds work in shared mix links', () async {
    app.parseAndApplyMixFromUri(
      Uri.parse(
        'https://example.test/?mix=Woodland%20Morning:40,Boat%20Deck:20,Blue%20Noise:10',
      ),
    );
    await flushAmbient();
    expect(app.activeAmbientTracks, {
      'Woodland Morning': .4,
      'Boat Deck': .2,
      'Blue Noise': .1,
    });
    expect(players.map((player) => player.sources.single), [
      'assets/sounds/woodland_morning.mp3',
      'assets/sounds/boat_deck.mp3',
      'assets/sounds/noise_blue.mp3',
    ]);
  });

  test(
    'new pack load failures do not substitute an unrelated remote recording',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failLoads = true;
      await app.updateSoundTrackVolume('Mountain Stream', .4);
      expect(players.single.sources, ['assets/sounds/woodland_stream.mp3']);
      expect(app.activeAmbientTracks, isEmpty);
      expect(
        app.ambientTrackError('Mountain Stream'),
        contains('could not play'),
      );
    },
  );

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
      expect(players.single.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(players.single.loop, LoopMode.one);
      expect(players.single.audible, isTrue);
      expect(players.single.plays.single.isCompleted, isFalse);
      expect(app.isAmbientTrackLoading('Soft Rain'), isFalse);
      await app.updateSoundTrackVolume('Soft Rain', 0);
      expect(players.single.audible, isFalse);
    },
  );

  test(
    'bundled failure is retryable without switching to an unreviewed network file',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failFirstLoads = 1;
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players.single.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(players.single.disposed, isTrue);
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.ambientTrackError('Soft Rain'), isNotNull);
      factory = FakeAmbientAudioPlayer.new;
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players.last.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(players.last.audible, isTrue);
      expect(app.getTrackVolume('Soft Rain'), .4);
      expect(app.ambientTrackError('Soft Rain'), isNull);
    },
  );

  test(
    'every bundled identity and alias fails locally without a network attempt',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failLoads = true;
      for (final entry in AppState.localSoundAssets.entries) {
        await app.updateSoundTrackVolume(entry.key, .37);
        expect(players.last.sources, [entry.value], reason: entry.key);
        expect(players.last.playCalls, 0);
        expect(players.last.disposed, isTrue);
        expect(app.ambientTrackError(entry.key), isNotNull);
      }
      expect(app.activeAmbientTracks, isEmpty);
    },
  );

  test(
    'explicit stream-only selections retain the same configured CDN/raw transport',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failFirstLoads = 1;
      await app.updateSoundTrackVolume('Thunderstorm', .37);
      expect(players.single.sources, [
        'https://cdn.jsdelivr.net/gh/remvze/moodist@main/public/sounds/rain/thunder.mp3',
        AppState.soundStreamUrls['Thunderstorm'],
      ]);
      expect(players.single.audible, isTrue);
      expect(app.getTrackVolume('Thunderstorm'), .37);
    },
  );

  test(
    'failed sources produce a safe retryable error, not active silence',
    () async {
      factory = () => FakeAmbientAudioPlayer()..failLoads = true;
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players.single.sources, ['assets/sounds/loop_soft_rain.mp3']);
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
  testWidgets(
    'a silent sleep deadline cannot create listening history',
    (tester) async {
      app.startSleepTimer(1);
      await tester.pump(const Duration(seconds: 61));
      await flushAmbient();
      expect(app.isSleepTimerRunning, isFalse);
      expect(app.sleepTimerRemainingSec, isNull);
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.sessions, isEmpty);
      expect(app.showMoodDialog, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'failed audio plus a timer is not a completed sleep session',
    (tester) async {
      factory = () => FakeAmbientAudioPlayer()..failLoads = true;
      // Finish asynchronous failed-source cleanup before advancing the fake clock.
      // The timer assertions below still run against deterministic virtual time.
      printOnFailure('Failed-source fixture: starting asynchronous cleanup.');
      await tester.runAsync(
        () => app.updateSoundTrackVolume('Mountain Stream', .4),
      );
      printOnFailure('Failed-source fixture: cleanup returned.');
      expect(app.ambientTrackError('Mountain Stream'), isNotNull);
      app.startSleepTimer(1);
      await tester.pump(const Duration(seconds: 61));
      await flushAmbient();
      expect(app.isSleepTimerRunning, isFalse);
      expect(app.sessions, isEmpty);
      expect(app.showMoodDialog, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'sleep expiry stops a mix without inventing listened minutes',
    (tester) async {
      await app.updateSoundTrackVolume('Soft Rain', .5);
      app.startSleepTimer(1);
      await tester.pump(const Duration(seconds: 20));
      await app.stopAllAudio();
      await tester.pump(const Duration(seconds: 41));
      await flushAmbient();
      expect(players.single.audible, isFalse);
      expect(players.single.volume, 0);
      expect(app.isSleepTimerRunning, isFalse);
      expect(app.sessions, isEmpty);
      expect(app.showMoodDialog, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'sleep expiry fences an ambient load that finishes later',
    (tester) async {
      // Begin loading in the timer's last six seconds. Loading at time zero
      // would hit the independent 12-second source timeout before sleep expiry.
      app.startSleepTimer(1);
      await tester.pump(const Duration(seconds: 55));
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final loading = app.updateSoundTrackVolume('Soft Rain', .5);
      await flushAmbient();
      expect(app.isAmbientTrackLoading('Soft Rain'), isTrue);
      await tester.pump(const Duration(seconds: 6));
      await flushAmbientWidget(tester);
      expect(app.sleepTimerRemainingSec, isNull);
      expect(app.hasAmbientPlaybackRequest, isFalse);
      expect(players.single.disposed, isTrue);
      gate.complete(const Duration(seconds: 30));
      await tester.pump();
      await loading;
      expect(players.single.playCalls, 0);
      expect(players.single.disposed, isTrue);
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.sessions, isEmpty);
      expect(app.showMoodDialog, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'cold-player eviction releases the player and its event subscription',
    () async {
      final names = AppState.soundStreamUrls.keys.take(13).toList();
      for (final name in names) {
        await app.updateSoundTrackVolume(name, .2);
      }
      expect(players, hasLength(13));
      expect(players.first.events.hasListener, isTrue);
      expect(players.first.states.hasListener, isTrue);
      await app.updateSoundTrackVolume(names.first, 0);
      await flushAmbient();
      expect(players.first.disposed, isTrue);
      expect(players.first.events.hasListener, isFalse);
      expect(players.first.states.hasListener, isFalse);
      expect(players.skip(1).every((player) => player.audible), isTrue);
    },
  );

  test(
    'player creation failure is visible without claiming active playback',
    () async {
      factory = () => throw StateError('private initialization payload');
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(players, isEmpty);
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.ambientTrackError('Soft Rain'), contains('could not play'));
      expect(app.ambientTrackError('Soft Rain'), isNot(contains('private')));
    },
  );

  test(
    'a requested loading level is not a playing layer or global label',
    () async {
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final loading = app.updateSoundTrackVolume('Soft Rain', .45);
      await flushAmbient();
      expect(app.requestedAmbientTracks, {'Soft Rain': .45});
      expect(app.hasAmbientPlaybackRequest, isTrue);
      expect(app.isAmbientPlaybackPending, isTrue);
      expect(
        app.ambientTrackStatus('Soft Rain'),
        AmbientPlaybackStatus.loading,
      );
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.isAnyAudioPlaying, isFalse);
      expect(app.isPlayingAny, isFalse);
      expect(app.activePlayingLabel, 'No Audio Playing');
      gate.complete(const Duration(seconds: 30));
      await loading;
      expect(
        app.ambientTrackStatus('Soft Rain'),
        AmbientPlaybackStatus.playing,
      );
      expect(app.activeAmbientTracks, {'Soft Rain': .45});
      expect(app.isAnyAudioPlaying, isTrue);
      expect(app.isAmbientPlaybackPending, isFalse);
      expect(app.activePlayingLabel, 'Soft Rain');
    },
  );

  test('a loaded source waits for a native start confirmation', () async {
    factory = () => FakeAmbientAudioPlayer()..holdPlay = true;
    await app.updateSoundTrackVolume('Soft Rain', .4);
    expect(players.single.processingState, ProcessingState.ready);
    expect(players.single.playCalls, 1);
    expect(app.ambientTrackStatus('Soft Rain'), AmbientPlaybackStatus.loading);
    expect(app.activeAmbientTracks, isEmpty);
    expect(app.isAnyAudioPlaying, isFalse);
    players.single.emitQueuedState(PlayerState(true, ProcessingState.ready));
    expect(app.activeAmbientTracks, isEmpty);
    players.single.emitState(
      playing: true,
      processingState: ProcessingState.ready,
    );
    expect(app.activeAmbientTracks, {'Soft Rain': .4});
    expect(app.isAmbientPlaybackPending, isFalse);
    expect(players.single.plays.single.isCompleted, isFalse);
  });

  test('buffering intent is unlit until ready and can buffer again', () async {
    factory = () => FakeAmbientAudioPlayer()..playStartsBuffering = true;
    await app.updateSoundTrackVolume('Soft Rain', .4);
    expect(players.single.playing, isTrue);
    expect(
      app.ambientTrackStatus('Soft Rain'),
      AmbientPlaybackStatus.buffering,
    );
    expect(app.isAmbientPlaybackPending, isTrue);
    expect(app.isAnyAudioPlaying, isFalse);
    players.single.emitState(
      playing: true,
      processingState: ProcessingState.ready,
    );
    expect(app.activeAmbientTracks, {'Soft Rain': .4});
    players.single.emitState(
      playing: true,
      processingState: ProcessingState.buffering,
    );
    expect(app.activeAmbientTracks, isEmpty);
    expect(app.isAnyAudioPlaying, isFalse);
    expect(app.requestedAmbientTracks, {'Soft Rain': .4});
    players.single.emitState(
      playing: true,
      processingState: ProcessingState.ready,
    );
    expect(app.activeAmbientTracks, {'Soft Rain': .4});
    expect(players.single.playCalls, 1);
  });

  test(
    'platform pause is not loading and resumes without reloading levels',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .62);
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      players.single.emitState(
        playing: false,
        processingState: ProcessingState.ready,
      );
      await flushAmbient();
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.ambientTrackStatus('Soft Rain'), AmbientPlaybackStatus.paused);
      expect(app.isAmbientPlaybackPending, isFalse);
      expect(mixer.isPlaying, isFalse);
      expect(mixer.hasPlaybackRequest, isTrue);
      expect(mixer.levels, {'Soft Rain': .62});
      expect(mixer.transportLabel, 'Resume soundscape');
      // A stale queued ready/playing event cannot undo the current interruption.
      players.single.emitQueuedState(PlayerState(true, ProcessingState.ready));
      expect(app.isAnyAudioPlaying, isFalse);
      mixer.togglePlayback();
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Soft Rain': .62});
      expect(players.single.sources, hasLength(1));
      expect(players.single.playCalls, 2);
    },
  );

  test(
    'requested gain edits preserve native pauses and the loaded sources',
    () async {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      mixer.applyMix({'Soft Rain': .6, 'Ocean Waves': .2});
      await flushAmbient();
      for (final player in players) {
        player.emitState(
          playing: false,
          processingState: ProcessingState.ready,
        );
      }
      await flushAmbient();
      mixer.setVolume('Soft Rain', .54, preservePaused: true);
      await flushAmbient();
      expect(app.requestedAmbientTracks, {'Soft Rain': .54, 'Ocean Waves': .2});
      expect(app.activeAmbientTracks, isEmpty);
      expect(players, hasLength(2));
      expect(players.every((player) => player.playCalls == 1), isTrue);
      expect(players.every((player) => player.sources.length == 1), isTrue);
      expect(mixer.transportLabel, 'Resume soundscape');
      mixer.togglePlayback(expandPlayer: false);
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Soft Rain': .54, 'Ocean Waves': .2});
      expect(players.every((player) => player.playCalls == 2), isTrue);
      expect(players.every((player) => player.sources.length == 1), isTrue);
    },
  );

  test(
    'gain edits retain multiple failures; one explicit Retry owns one asset',
    () async {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      mixer.applyMix({'Soft Rain': .6, 'Ocean Waves': .2, 'Forest Birds': .15});
      await flushAmbient();
      final healthy = players[1];
      for (final player in [players.first, players.last]) {
        player.events.addError(
          StateError('fixture failure'),
          StackTrace.current,
        );
      }
      await flushAmbient();
      mixer.setVolume('Ocean Waves', .24, preservePaused: true);
      mixer.setVolume('Soft Rain', .53, preservePaused: true);
      await flushAmbient();
      expect(
        players,
        hasLength(3),
        reason: 'A gain edit creates no retry player',
      );
      expect(app.activeAmbientTracks, {'Ocean Waves': .24});
      expect(app.ambientTrackError('Soft Rain'), isNotNull);
      expect(app.ambientTrackError('Forest Birds'), isNotNull);
      expect(mixer.levels, {
        'Soft Rain': .53,
        'Ocean Waves': .24,
        'Forest Birds': .15,
      });
      expect(healthy.playCalls, 1);
      expect(healthy.sources, ['assets/sounds/loop_ocean_waves.mp3']);
      expect(mixer.retryTrack('Soft Rain'), isTrue);
      await flushAmbient();
      expect(players, hasLength(4));
      expect(players.last.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(app.activeAmbientTracks, {'Ocean Waves': .24, 'Soft Rain': .53});
      expect(app.ambientTrackError('Forest Birds'), isNotNull);
      expect(healthy.playCalls, 1);
    },
  );

  test(
    'gain-only edits do not cancel or duplicate an original pending load',
    () async {
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final loading = app.updateSoundTrackVolume('Soft Rain', .4);
      await flushAmbient();
      await app.updateSoundTrackVolume('Soft Rain', .53, resumePaused: false);
      expect(players, hasLength(1));
      expect(players.single.playCalls, 0);
      expect(app.isAmbientTrackLoading('Soft Rain'), isTrue);
      expect(app.requestedAmbientTracks, {'Soft Rain': .53});
      gate.complete(const Duration(seconds: 30));
      await loading;
      expect(app.activeAmbientTracks, {'Soft Rain': .53});
      expect(players.single.playCalls, 1);
      expect(players.single.sources, ['assets/sounds/loop_soft_rain.mp3']);
      expect(players.single.volume, closeTo(.53, .0001));
    },
  );

  test(
    'partial loading and buffering count only the healthy ready layer',
    () async {
      await app.updateSoundTrackVolume('Ocean Waves', .7);
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      final loading = app.updateSoundTrackVolume('Soft Rain', .7);
      await flushAmbient();
      expect(app.requestedAmbientTracks, {'Ocean Waves': .7, 'Soft Rain': .7});
      expect(app.activeAmbientTracks, {'Ocean Waves': .7});
      expect(app.activePlayingLabel, 'Ocean Waves');
      expect(players.first.volume, closeTo(.5, .0001));
      gate.complete(const Duration(seconds: 30));
      await loading;
      players.last.emitState(
        playing: true,
        processingState: ProcessingState.buffering,
      );
      expect(app.activeAmbientTracks, {'Ocean Waves': .7});
      expect(players.first.playCalls, 1);
      expect(app.getTrackVolume('Soft Rain'), .7);
    },
  );

  test(
    'master cancellation revokes a pending owner before immediate replay',
    () async {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      mixer.applyMix({'Soft Rain': .44}, name: 'Quiet Rain');
      await flushAmbient();
      expect(mixer.isPlaying, isFalse);
      expect(mixer.isPreparing, isTrue);
      mixer.togglePlayback();
      expect(app.hasAmbientPlaybackRequest, isFalse);
      expect(players.first.volume, 0);
      expect(mixer.levels, {'Soft Rain': .44});
      factory = FakeAmbientAudioPlayer.new;
      mixer.togglePlayback();
      await flushAmbient();
      gate.complete(const Duration(seconds: 30));
      await flushAmbient();
      expect(players, hasLength(2));
      expect(players.first.disposed, isTrue);
      expect(players.first.playCalls, 0);
      expect(app.activeAmbientTracks, {'Soft Rain': .44});
      expect(players.last.pauseCalls, 0);
      expect(mixer.preset, 'Quiet Rain');
    },
  );

  test(
    'cancelled start events cannot claim or stop a replacement player',
    () async {
      factory = () => FakeAmbientAudioPlayer()..holdPlay = true;
      await app.updateSoundTrackVolume('Soft Rain', .2);
      final old = players.single;
      await app.updateSoundTrackVolume('Soft Rain', 0);
      factory = FakeAmbientAudioPlayer.new;
      await app.updateSoundTrackVolume('Soft Rain', .8);
      old.emitState(playing: true, processingState: ProcessingState.ready);
      await flushAmbient();
      expect(old.disposed, isTrue);
      expect(old.states.hasListener, isFalse);
      expect(old.events.hasListener, isFalse);
      expect(app.activeAmbientTracks, {'Soft Rain': .8});
      expect(players.last.playCalls, 1);
      expect(players.last.pauseCalls, 0);
    },
  );

  testWidgets('an unconfirmed start times out only its own layer', (
    tester,
  ) async {
    await app.updateSoundTrackVolume('Ocean Waves', .7);
    factory = () => FakeAmbientAudioPlayer()..holdPlay = true;
    await app.updateSoundTrackVolume('Soft Rain', .7);
    await tester.pump(const Duration(seconds: 13));
    await flushAmbientWidget(tester);
    expect(app.ambientTrackError('Soft Rain'), contains('could not play'));
    expect(players.last.disposed, isTrue);
    expect(app.activeAmbientTracks, {'Ocean Waves': .7});
    expect(app.isAmbientPlaybackPending, isFalse);
    expect(players.first.volume, closeTo(.7, .0001));
    expect(players.first.playCalls, 1);
    players.last.emitState(
      playing: true,
      processingState: ProcessingState.ready,
    );
    expect(app.activeAmbientTracks, {'Ocean Waves': .7});
  });

  test(
    'a state-stream error releases both subscriptions, not healthy media',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .4);
      await app.updateSoundTrackVolume('Ocean Waves', .3);
      players.first.states.addError(
        StateError('private state payload'),
        StackTrace.current,
      );
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Ocean Waves': .3});
      expect(players.first.disposed, isTrue);
      expect(players.first.states.hasListener, isFalse);
      expect(players.first.events.hasListener, isFalse);
      expect(app.ambientTrackError('Soft Rain'), isNot(contains('private')));
      expect(players.last.playCalls, 1);
    },
  );

  test(
    'partial failure retains selected levels and retries without restarting the healthy loop',
    () async {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      mixer.applyMix({'Soft Rain': .63, 'Ocean Waves': .21}, name: 'Evening');
      await flushAmbient();
      players.first.events.addError(
        StateError('private payload'),
        StackTrace.current,
      );
      await flushAmbient();
      expect(mixer.levels, {'Soft Rain': .63, 'Ocean Waves': .21});
      expect(mixer.preset, 'Evening');
      expect(mixer.playbackStatusLabel, 'Playing · 1 layer · 1 unavailable');
      final healthy = players[1];
      expect(mixer.retryTrack('Soft Rain'), isTrue);
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Soft Rain': .63, 'Ocean Waves': .21});
      expect(healthy.playCalls, 1);
      expect(healthy.sources, hasLength(1));
      expect(mixer.hasPlaybackError, isFalse);
    },
  );

  test(
    'replacement during loading preserves running intent and revokes the old source',
    () async {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      final gate = Completer<Duration?>();
      factory = () => FakeAmbientAudioPlayer()..loadGate = gate;
      mixer.applyMix({'Soft Rain': .56});
      await flushAmbient();
      factory = FakeAmbientAudioPlayer.new;
      expect(mixer.replaceTrack('Soft Rain', 'Ocean Waves'), isTrue);
      await flushAmbient();
      gate.complete(const Duration(seconds: 30));
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Ocean Waves': .56});
      expect(mixer.levels, {'Ocean Waves': .56});
      expect(players.first.disposed, isTrue);
      expect(players.first.playCalls, 0);
      expect(players.last.playCalls, 1);
    },
  );

  test(
    'a late pause from global stop cannot silence a newer ready request',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .25);
      final gate = Completer<void>();
      players.single.pauseGate = gate;
      final stopping = app.stopAllAudio();
      await flushAmbient();
      expect(app.activeAmbientTracks, isEmpty);
      await app.updateSoundTrackVolume('Soft Rain', .75);
      gate.complete();
      await stopping;
      await flushAmbient();
      expect(app.activeAmbientTracks, {'Soft Rain': .75});
      expect(players.single.audible, isTrue);
      expect(players.single.volume, closeTo(.75, .0001));
      expect(players.single.sources, hasLength(1));
    },
  );

  test(
    'an unsolicited platform resume cannot revive a stopped request',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .4);
      await app.stopAllAudio();
      players.single.emitState(
        playing: true,
        processingState: ProcessingState.ready,
      );
      await flushAmbient();
      expect(app.hasAmbientPlaybackRequest, isFalse);
      expect(app.isAnyAudioPlaying, isFalse);
      expect(players.single.audible, isFalse);
      expect(players.single.volume, 0);
    },
  );

  test(
    'an unexpected loop end becomes retryable and ignores stale completed events',
    () async {
      await app.updateSoundTrackVolume('Soft Rain', .4);
      players.single.emitQueuedState(
        PlayerState(true, ProcessingState.completed),
      );
      expect(app.activeAmbientTracks, {'Soft Rain': .4});
      players.single.emitState(
        playing: true,
        processingState: ProcessingState.completed,
      );
      await flushAmbient();
      expect(app.activeAmbientTracks, isEmpty);
      expect(app.ambientTrackError('Soft Rain'), contains('could not play'));
      expect(players.first.disposed, isTrue);
      await app.updateSoundTrackVolume('Soft Rain', .4);
      expect(app.activeAmbientTracks, {'Soft Rain': .4});
      expect(players.last.playCalls, 1);
    },
  );
}
