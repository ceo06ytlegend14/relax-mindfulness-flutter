import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// Models a looping play future and delayed/failed source loading without
/// channels or network. A source can still complete after disposal.
class FakeAmbientAudioPlayer extends Fake implements AudioPlayer {
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final sources = <String>[];
  final volumes = <double>[];
  final plays = <Completer<void>>[];
  Completer<Duration?>? loadGate;
  int failFirstLoads = 0;
  bool failLoads = false;
  bool failPlay = false;
  bool disposed = false;
  bool audible = false;
  int playCalls = 0;
  int pauseCalls = 0;
  LoopMode loop = LoopMode.off;
  double volume = 0;

  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  bool get playing => audible;

  Future<Duration?> _load(String source) async {
    sources.add(source);
    final gate = loadGate;
    loadGate = null;
    if (gate != null) return gate.future;
    if (failLoads || failFirstLoads > 0) {
      if (failFirstLoads > 0) failFirstLoads--;
      events.addError(StateError('private source payload'), StackTrace.current);
      throw StateError('private source payload');
    }
    return const Duration(seconds: 30);
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
  Future<void> pause() async {
    pauseCalls++;
    _silence();
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    _silence();
    await events.close();
  }
}
