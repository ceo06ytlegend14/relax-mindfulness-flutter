import 'dart:async';

import 'package:relax_mindfulness/services/sound_preview_controller.dart';

class FakeSoundPreviewPlayer implements SoundPreviewPlayer {
  final loads = <String>[];
  final playResult = Completer<void>();
  Completer<void>? loadGate;
  bool failLoad = false;
  bool failPlay = false;
  bool disposed = false;
  bool playing = false;
  int playCalls = 0;
  double volume = 0;

  @override
  Future<void> loadAsset(String path) async {
    loads.add(path);
    if (failLoad) throw StateError('private audio payload');
    await loadGate?.future;
  }

  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> play() {
    playCalls++;
    if (failPlay) return Future.error(StateError('private platform payload'));
    playing = true;
    return playResult.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
    if (!playResult.isCompleted) playResult.complete();
  }
}
