import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/models/session_soundscapes.dart';

/// Matches just_audio's long-lived play future without platform channels.
class SessionAudioDouble extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final loadedSources = <String>[];
  final seeks = <Duration>[];
  final plays = <Completer<void>>[];
  Completer<Duration?>? nextLoad;
  bool failLoads = false;
  int failFirstLoads = 0;
  bool failPlay = false;
  bool audible = false;
  int playCalls = 0;
  double volume = 0;
  LoopMode loop = LoopMode.off;

  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  bool get playing => audible;
  @override
  Duration? get duration => const Duration(seconds: 120);

  Future<Duration?> _load(String source) async {
    loadedSources.add(source);
    final gate = nextLoad;
    nextLoad = null;
    if (gate != null) return gate.future;
    if (failLoads || failFirstLoads > 0) {
      if (failFirstLoads > 0) failFirstLoads--;
      events.addError(
        StateError('Audio source unavailable'),
        StackTrace.current,
      );
      throw StateError('Audio source unavailable');
    }
    return duration;
  }

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) => _load(assetPath);
  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) => _load(url);
  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> setLoopMode(LoopMode value) async {
    loop = value;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    seeks.add(position ?? Duration.zero);
  }

  @override
  Future<void> play() {
    playCalls++;
    if (failPlay) return Future.error(StateError('Playback denied'));
    audible = true;
    final result = Completer<void>();
    plays.add(result);
    return result.future;
  }

  void _silence() {
    audible = false;
    for (final result in plays) {
      if (!result.isCompleted) result.complete();
    }
  }

  @override
  Future<void> pause() async => _silence();
  @override
  Future<void> stop() async => _silence();
  @override
  Future<void> dispose() async {
    _silence();
    await states.close();
    await events.close();
  }
}

Future<void> flushSessionMicrotasks() async {
  for (var index = 0; index < 20; index++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionAudioDouble audio;
  late AppState app;
  late DateTime now;
  setUp(() {
    now = DateTime.utc(2026, 11, 19, 20);
    audio = SessionAudioDouble();
    app = AppState(guidedPlayer: audio, now: () => now);
  });
  tearDown(() => app.dispose());

  test('no retained session or progress is invented before playback', () {
    expect(app.hasGuidedSession, isFalse);
    expect(app.isGuidedPlayerExpanded, isFalse);
    expect(app.guidedTotalSec, 0);
    expect(app.guidedElapsedSec, 0);
    expect(app.canSeekGuidedSession, isFalse);
  });

  test(
    'a 35-minute session uses its own duration and bundled source',
    () async {
      await app.playGuidedSession('The Starry Night', 35);
      expect(app.currentGuidedTitle, 'The Starry Night');
      expect(app.guidedTotalSec, 2100);
      expect(app.guidedRemainingSec, 2100);
      expect(app.isGuidedPlaying, isTrue);
      expect(app.isGuidedPlayerExpanded, isTrue);
      expect(app.canSeekGuidedSession, isTrue);
      expect(audio.loadedSources, ['assets/sounds/session_starry_night.mp3']);
      expect(audio.loop, LoopMode.one);
      expect(audio.volume, .35);
    },
  );

  test(
    'loading does not spend session time or pretend to be playing',
    () async {
      final gate = Completer<Duration?>();
      audio.nextLoad = gate;
      final starting = app.playGuidedSession('Gentle Relief & Comfort', 15);
      await flushSessionMicrotasks();
      expect(app.isGuidedLoading, isTrue);
      expect(app.isGuidedPlaying, isFalse);
      expect(app.canSeekGuidedSession, isFalse);
      now = now.add(const Duration(seconds: 45));
      expect(app.guidedRemainingSec, 900);
      gate.complete(audio.duration);
      await starting;
      expect(app.isGuidedLoading, isFalse);
      expect(app.guidedRemainingSec, 900);
    },
  );

  test('pause retains the title, timer and expanded player', () async {
    await app.playGuidedSession('Gentle Relief & Comfort', 15);
    now = now.add(const Duration(seconds: 73));
    await app.pauseGuidedSession();
    expect(app.guidedRemainingSec, 827);
    expect(app.guidedElapsedSec, 73);
    expect(app.currentGuidedTitle, 'Gentle Relief & Comfort');
    expect(app.isGuidedPlaying, isFalse);
    expect(app.isGuidedPlayerExpanded, isTrue);
    expect(audio.audible, isFalse);
    now = now.add(const Duration(minutes: 12));
    expect(app.guidedRemainingSec, 827);
  });

  test(
    'resume preserves elapsed time and does not reload or seek to zero',
    () async {
      await app.playGuidedSession('Gentle Relief & Comfort', 15);
      now = now.add(const Duration(seconds: 73));
      await app.pauseGuidedSession();
      now = now.add(const Duration(minutes: 12));
      await app.resumeGuidedSession();
      expect(app.guidedRemainingSec, 827);
      expect(audio.loadedSources, hasLength(1));
      expect(audio.seeks, isEmpty);
      expect(audio.audible, isTrue);
      now = now.add(const Duration(seconds: 5));
      expect(app.guidedRemainingSec, 822);
    },
  );

  test(
    'selecting a retained session resumes rather than resetting it',
    () async {
      await app.playGuidedSession('The Starry Night', 35);
      now = now.add(const Duration(minutes: 2));
      await app.pauseGuidedSession();
      app.minimizeGuidedPlayer();
      await app.playGuidedSession('The Starry Night', 35);
      expect(app.guidedRemainingSec, 1980);
      expect(audio.loadedSources, hasLength(1));
      expect(app.isGuidedPlayerExpanded, isTrue);
    },
  );

  test('minimize and reopen never stop or restart the audio', () async {
    await app.playGuidedSession('Calm Mountain Horizon', 10);
    app.minimizeGuidedPlayer();
    expect(app.isGuidedPlayerExpanded, isFalse);
    expect(audio.audible, isTrue);
    app.showGuidedPlayer();
    expect(app.isGuidedPlayerExpanded, isTrue);
    expect(audio.playCalls, 1);
  });

  test(
    'paused seeking changes the timer and real looped source position',
    () async {
      await app.playGuidedSession('The Starry Night', 35);
      await app.pauseGuidedSession();
      await app.seekGuidedSession(250);
      expect(app.guidedElapsedSec, 250);
      expect(app.guidedRemainingSec, 1850);
      expect(audio.seeks.last, const Duration(seconds: 10));
      expect(app.isGuidedPlaying, isFalse);
      expect(audio.audible, isFalse);
    },
  );

  test('seeking during playback continues from the requested point', () async {
    await app.playGuidedSession('Gentle Relief & Comfort', 15);
    await app.seekGuidedSession(100);
    expect(app.guidedRemainingSec, 800);
    expect(audio.seeks.last, const Duration(seconds: 100));
    expect(app.isGuidedPlaying, isTrue);
    expect(audio.audible, isTrue);
  });

  test(
    'seek bounds cannot create negative time or an instant completion',
    () async {
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      await app.seekGuidedSession(-30);
      expect(app.guidedElapsedSec, 0);
      await app.seekGuidedSession(99999);
      expect(app.guidedRemainingSec, 1);
      expect(app.hasGuidedSession, isTrue);
      expect(app.showMoodDialog, isFalse);
    },
  );

  test(
    'extend and restart retain the actual duration, even while paused',
    () async {
      await app.playGuidedSession('The Starry Night', 35);
      now = now.add(const Duration(minutes: 2));
      await app.pauseGuidedSession();
      app.extendGuidedSession(10);
      expect(app.guidedTotalSec, 2700);
      expect(app.guidedRemainingSec, 2580);
      await app.restartGuidedSession();
      expect(app.guidedTotalSec, 2700);
      expect(app.guidedRemainingSec, 2700);
      expect(audio.seeks.last, Duration.zero);
      expect(app.isGuidedPlaying, isFalse);
    },
  );

  test('loop control changes just_audio and survives the next load', () async {
    await app.playGuidedSession('Calm Mountain Horizon', 10);
    await app.toggleGuidedLoop();
    expect(app.isGuidedLooping, isFalse);
    expect(audio.loop, LoopMode.off);
    await app.playGuidedSession('The Starry Night', 35);
    expect(audio.loop, LoopMode.off);
  });

  test(
    'early completion records listened minutes, not a fabricated ten',
    () async {
      await app.playGuidedSession('The Starry Night', 35);
      now = now.add(const Duration(seconds: 70));
      await app.stopGuidedSession(completed: true);
      expect(app.showMoodDialog, isTrue);
      app.dismissMood();
      expect(app.sessions.single.title, 'The Starry Night');
      expect(app.sessions.single.durationMinutes, 1);
    },
  );

  test('finishing immediately does not invent a wellbeing session', () async {
    await app.playGuidedSession('The Starry Night', 35);
    await app.stopGuidedSession(completed: true);
    expect(app.showMoodDialog, isFalse);
    expect(app.sessions, isEmpty);
  });

  test(
    'paused time and skipped progress are not recorded as listening',
    () async {
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      now = now.add(const Duration(seconds: 20));
      await app.pauseGuidedSession();
      now = now.add(const Duration(hours: 1));
      await app.seekGuidedSession(599);
      await app.stopGuidedSession(completed: true);
      expect(app.sessions, isEmpty);
      expect(app.showMoodDialog, isFalse);
    },
  );

  testWidgets('a late background timer ends at the real deadline once', (
    tester,
  ) async {
    await app.playGuidedSession('The Starry Night', 35);
    now = now.add(const Duration(minutes: 40));
    await tester.pump(const Duration(seconds: 1));
    expect(app.hasGuidedSession, isFalse);
    expect(audio.audible, isFalse);
    app.dismissMood();
    expect(app.sessions.single.durationMinutes, 35);
    await tester.pump(const Duration(seconds: 2));
    expect(app.sessions, hasLength(1));
  });

  testWidgets('background guided playback has no per-second UI heartbeat', (
    tester,
  ) async {
    await app.playGuidedSession('Gentle Relief & Comfort', 1);
    app.setBackgroundMode(true);
    var updates = 0;
    app.addListener(() => updates++);
    now = now.add(const Duration(seconds: 50));
    await tester.pump(const Duration(seconds: 50));
    expect(updates, 0);
    expect(app.guidedRemainingSec, 10);
    expect(audio.audible, isTrue);
    expect(audio.playCalls, 1);
    expect(audio.loadedSources, hasLength(1));
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await flushSessionMicrotasks();
    expect(app.hasGuidedSession, isFalse);
    expect(audio.audible, isFalse);
    // Completed listening is pending until the existing mood check-in is
    // submitted/skipped. Background scheduling must not bypass that contract.
    expect(app.showMoodDialog, isTrue);
    expect(app.sessions, isEmpty);
    app.dismissMood();
    expect(app.sessions.single.durationMinutes, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(app.sessions, hasLength(1));
  });

  test(
    'foreground resume reconciles an overdue guided deadline once',
    () async {
      await app.playGuidedSession('The Starry Night', 35);
      app.setBackgroundMode(true);
      now = now.add(const Duration(minutes: 40));
      app.setBackgroundMode(false);
      await flushSessionMicrotasks();
      expect(app.hasGuidedSession, isFalse);
      expect(audio.audible, isFalse);
      expect(app.showMoodDialog, isTrue);
      expect(app.sessions, isEmpty);
      app.dismissMood();
      expect(app.sessions.single.durationMinutes, 35);
      app.setBackgroundMode(true);
      app.setBackgroundMode(false);
      await flushSessionMicrotasks();
      expect(app.sessions, hasLength(1));
    },
  );

  testWidgets('extending a background session replaces its deadline wake', (
    tester,
  ) async {
    await app.playGuidedSession('Gentle Relief & Comfort', 1);
    app.setBackgroundMode(true);
    app.extendGuidedSession(1);
    now = now.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 61));
    expect(app.guidedRemainingSec, 59);
    expect(audio.audible, isTrue);
    expect(audio.playCalls, 1);
    expect(app.sessions, isEmpty);
    now = now.add(const Duration(seconds: 59));
    await tester.pump(const Duration(seconds: 59));
    await flushSessionMicrotasks();
    expect(app.hasGuidedSession, isFalse);
    expect(app.showMoodDialog, isTrue);
    expect(app.sessions, isEmpty);
    app.dismissMood();
    expect(app.sessions.single.durationMinutes, 2);
  });

  testWidgets('background pause cancels shutdown until an explicit resume', (
    tester,
  ) async {
    await app.playGuidedSession('Gentle Relief & Comfort', 1);
    app.setBackgroundMode(true);
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await app.pauseGuidedSession();
    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(app.guidedRemainingSec, 30);
    expect(app.hasGuidedSession, isTrue);
    expect(app.sessions, isEmpty);
    await app.resumeGuidedSession();
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await flushSessionMicrotasks();
    expect(app.hasGuidedSession, isFalse);
    expect(audio.audible, isFalse);
    expect(app.showMoodDialog, isTrue);
    expect(app.sessions, isEmpty);
    app.dismissMood();
    expect(app.sessions.single.durationMinutes, 1);
    expect(audio.loadedSources, hasLength(1));
  });

  test(
    'unavailable sources leave a paused, retryable session with no timer loss',
    () async {
      audio.failLoads = true;
      await app.playGuidedSession('Gentle Relief & Comfort', 15);
      expect(audio.loadedSources, ['assets/sounds/session_gentle_relief.mp3']);
      expect(app.isGuidedPlaying, isFalse);
      expect(app.isGuidedLoading, isFalse);
      expect(app.guidedPlaybackError, isNotNull);
      expect(app.guidedRemainingSec, 900);
      expect(app.isGuidedPlayerExpanded, isTrue);
      audio.failLoads = false;
      await app.resumeGuidedSession();
      expect(app.isGuidedPlaying, isTrue);
      expect(app.guidedPlaybackError, isNull);
      expect(audio.loadedSources, [
        'assets/sounds/session_gentle_relief.mp3',
        'assets/sounds/session_gentle_relief.mp3',
      ]);
    },
  );

  test(
    'play rejection cannot leave a running countdown or live indicator',
    () async {
      audio.failPlay = true;
      await app.playGuidedSession('Gentle Relief & Comfort', 15);
      await flushSessionMicrotasks();
      expect(app.isGuidedPlaying, isFalse);
      expect(app.guidedPlaybackError, isNotNull);
      now = now.add(const Duration(minutes: 2));
      expect(app.guidedRemainingSec, 900);
    },
  );

  test(
    'stop during a pending load cannot revive the session afterward',
    () async {
      final gate = Completer<Duration?>();
      audio.nextLoad = gate;
      final starting = app.playGuidedSession('Gentle Relief & Comfort', 15);
      await flushSessionMicrotasks();
      await app.stopGuidedSession();
      gate.complete(audio.duration);
      await starting;
      expect(app.hasGuidedSession, isFalse);
      expect(app.isGuidedPlaying, isFalse);
      expect(audio.playCalls, 0);
      expect(audio.audible, isFalse);
    },
  );

  test(
    'a stale load cannot replace or autoplay over a newer selection',
    () async {
      final gate = Completer<Duration?>();
      audio.nextLoad = gate;
      final first = app.playGuidedSession('Calm Mountain Horizon', 10);
      await flushSessionMicrotasks();
      await app.playGuidedSession('The Starry Night', 35);
      gate.complete(audio.duration);
      await first;
      expect(app.currentGuidedTitle, 'The Starry Night');
      expect(app.guidedTotalSec, 2100);
      expect(audio.playCalls, 1);
    },
  );

  test('stop all clears a retained paused session too', () async {
    await app.playGuidedSession('Calm Mountain Horizon', 10);
    await app.pauseGuidedSession();
    app.minimizeGuidedPlayer();
    await app.stopAllAudio();
    expect(app.hasGuidedSession, isFalse);
    expect(app.guidedTotalSec, 0);
    expect(app.isGuidedPlayerExpanded, isFalse);
  });

  test('nonpositive durations cannot create a session', () async {
    await app.playGuidedSession('No session', 0);
    await app.playGuidedSession('No session', -10);
    expect(app.hasGuidedSession, isFalse);
    expect(audio.loadedSources, isEmpty);
  });

  test('non-looping source completion ends actual playback and time', () async {
    await app.playGuidedSession('The Starry Night', 35);
    await app.toggleGuidedLoop();
    now = now.add(const Duration(minutes: 2));
    audio.states.add(PlayerState(true, ProcessingState.completed));
    await flushSessionMicrotasks();
    expect(app.hasGuidedSession, isFalse);
    app.dismissMood();
    expect(app.sessions.single.durationMinutes, 2);
  });

  test(
    'source errors retain the session but stop its live playback state',
    () async {
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      now = now.add(const Duration(seconds: 20));
      audio.events.addError(
        StateError('Audio device disconnected'),
        StackTrace.current,
      );
      await flushSessionMicrotasks();
      expect(app.hasGuidedSession, isTrue);
      expect(app.isGuidedPlaying, isFalse);
      expect(app.guidedRemainingSec, 580);
      expect(audio.audible, isFalse);
    },
  );
  test(
    'platform pause freezes the timeline without discarding the session',
    () async {
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      now = now.add(const Duration(seconds: 25));
      audio.audible = false;
      audio.states.add(PlayerState(false, ProcessingState.ready));
      expect(app.isGuidedPlaying, isFalse);
      expect(app.guidedRemainingSec, 575);
      now = now.add(const Duration(minutes: 5));
      expect(app.guidedRemainingSec, 575);
    },
  );

  test(
    'platform resume restarts the retained timeline, not its full duration',
    () async {
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      now = now.add(const Duration(seconds: 25));
      audio.audible = false;
      audio.states.add(PlayerState(false, ProcessingState.ready));
      now = now.add(const Duration(minutes: 5));
      audio.audible = true;
      audio.states.add(PlayerState(true, ProcessingState.ready));
      expect(app.isGuidedPlaying, isTrue);
      expect(app.guidedRemainingSec, 575);
      now = now.add(const Duration(seconds: 5));
      expect(app.guidedRemainingSec, 570);
    },
  );
  test(
    'a missing arrangement never falls back to a shared sample or stream',
    () async {
      audio.failFirstLoads = 1;
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      expect(audio.loadedSources, ['assets/sounds/session_calm_mountain.mp3']);
      expect(app.isGuidedPlaying, isFalse);
      expect(app.guidedPlaybackError, isNotNull);
      expect(app.guidedRemainingSec, 600);
      await app.resumeGuidedSession();
      expect(audio.loadedSources, [
        'assets/sounds/session_calm_mountain.mp3',
        'assets/sounds/session_calm_mountain.mp3',
      ]);
      expect(app.isGuidedPlaying, isTrue);
    },
  );

  test(
    'every titled card opens its own arrangement, not just a new timer',
    () async {
      final cards = [dailyMeditation, ...meditationSessions];
      final titles = [
        for (final card in cards) card.title,
        for (final card in sleepStories) card.title,
      ];
      for (final title in titles) {
        await app.playGuidedSession(title, 10);
        expect(app.isGuidedPlaying, isTrue);
        expect(
          audio.loadedSources.last,
          sessionSoundscapeForTitle(title)!.assetPath,
        );
      }
      expect(audio.loadedSources.toSet(), hasLength(23));
      expect(audio.playCalls, 23);
    },
  );

  test(
    'an unknown title reports missing content without trying any audio',
    () async {
      await app.playGuidedSession('An unconfigured practice', 15);
      expect(app.currentGuidedTitle, 'An unconfigured practice');
      expect(app.guidedPlaybackError, isNotNull);
      expect(app.guidedRemainingSec, 900);
      expect(app.isGuidedPlaying, isFalse);
      expect(app.canSeekGuidedSession, isFalse);
      expect(audio.loadedSources, isEmpty);
      expect(audio.playCalls, 0);
    },
  );

  test(
    'retry after a playback error seeks the same arrangement to retained time',
    () async {
      await app.playGuidedSession('Calm Mountain Horizon', 10);
      now = now.add(const Duration(seconds: 25));
      audio.events.addError(StateError('Disconnected'), StackTrace.current);
      await flushSessionMicrotasks();
      await app.resumeGuidedSession();
      expect(app.guidedRemainingSec, 575);
      expect(audio.seeks.last, const Duration(seconds: 25));
      expect(audio.loadedSources, [
        'assets/sounds/session_calm_mountain.mp3',
        'assets/sounds/session_calm_mountain.mp3',
      ]);
    },
  );
}
