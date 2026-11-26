import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// Models looping play futures separately from native readiness. Loads, start
/// confirmation and pauses can be delayed; old sources can finish after dispose.
class FakeAmbientAudioPlayer extends Fake implements AudioPlayer {
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final sources = <String>[];
  final volumes = <double>[];
  final plays = <Completer<void>>[];
  Completer<Duration?>? loadGate;
  Completer<void>? pauseGate;
  int failFirstLoads = 0;
  bool failLoads = false;
  bool failPlay = false;
  bool holdPlay = false;
  bool playStartsBuffering = false;
  bool disposed = false;
  bool _playing = false;
  ProcessingState _processingState = ProcessingState.idle;
  int playCalls = 0;
  int pauseCalls = 0;
  LoopMode loop = LoopMode.off;
  @override
  double volume = 0;

  bool get audible =>
      !disposed && _playing && _processingState == ProcessingState.ready;

  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  bool get playing => _playing;
  @override
  ProcessingState get processingState => _processingState;

  void emitState({
    required bool playing,
    required ProcessingState processingState,
  }) {
    _playing = playing;
    _processingState = processingState;
    if (!disposed) states.add(PlayerState(playing, processingState));
    if (!playing) _completePlays();
  }

  /// A queued event cannot change the player's current live properties.
  void emitQueuedState(PlayerState state) {
    if (!disposed) states.add(state);
  }

  Future<Duration?> _load(String source) async {
    sources.add(source);
    emitState(playing: false, processingState: ProcessingState.loading);
    final gate = loadGate;
    loadGate = null;
    Duration? duration;
    if (gate != null) {
      duration = await gate.future;
    } else {
      if (failLoads || failFirstLoads > 0) {
        if (failFirstLoads > 0) failFirstLoads--;
        events.addError(
          StateError('private source payload'),
          StackTrace.current,
        );
        throw StateError('private source payload');
      }
      duration = const Duration(seconds: 30);
    }
    emitState(playing: false, processingState: ProcessingState.ready);
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
    volumes.add(value);
  }

  @override
  Future<void> setLoopMode(LoopMode value) async {
    loop = value;
  }

  @override
  Future<void> play() {
    playCalls++;
    if (failPlay) return Future.error(StateError('private playback payload'));
    final result = Completer<void>();
    plays.add(result);
    if (!holdPlay) {
      emitState(
        playing: true,
        processingState: playStartsBuffering
            ? ProcessingState.buffering
            : _processingState,
      );
    }
    return result.future;
  }

  void _completePlays() {
    for (final result in plays) {
      if (!result.isCompleted) result.complete();
    }
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    final gate = pauseGate;
    pauseGate = null;
    if (gate != null) await gate.future;
    emitState(playing: false, processingState: _processingState);
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    _playing = false;
    _completePlays();
    await states.close();
    await events.close();
  }
}
