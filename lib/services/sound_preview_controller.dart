import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';

abstract interface class SoundPreviewPlayer {
  Future<void> loadAsset(String path);
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> dispose();
}

class _JustAudioPreviewPlayer implements SoundPreviewPlayer {
  final AudioPlayer _player = AudioPlayer();
  @override
  Future<void> loadAsset(String path) async {
    await _player.setAsset(path);
    await _player.setLoopMode(LoopMode.off);
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> dispose() => _player.dispose();
}

/// A short, explicitly requested, local-only preview. It never edits the mix.
/// Each request owns a player, so late loads cannot restart an old preview.
class SoundPreviewController extends ChangeNotifier {
  SoundPreviewController({
    SoundPreviewPlayer Function()? playerFactory,
    void Function(bool previewing)? onPreviewActivity,
    this.previewDuration = const Duration(seconds: 8),
    this.loadTimeout = const Duration(seconds: 10),
  }) : _factory = playerFactory ?? _JustAudioPreviewPlayer.new,
       _onActivity = onPreviewActivity;

  final SoundPreviewPlayer Function() _factory;
  final void Function(bool)? _onActivity;
  final Duration previewDuration;
  final Duration loadTimeout;
  SoundPreviewPlayer? _player;
  Timer? _previewTimer;
  Timer? _loadTimer;
  int _request = 0;
  bool _disposed = false;
  bool _loading = false;
  bool _playing = false;
  String? _name;
  String? _error;

  String? get name => _name;
  String? get error => _error;
  bool get isLoading => _loading;
  bool get isPlaying => _playing;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int request) => !_disposed && request == _request;

  Future<void> _release(SoundPreviewPlayer? player) async {
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {
      // Disposal is best-effort; never expose platform payloads.
    }
  }

  Future<void> toggle(BundledRecording recording) async {
    if (_disposed || !bundledRecordings.contains(recording)) return;
    if (_name == recording.name && (_playing || _loading)) {
      await stop();
      return;
    }
    final request = ++_request;
    _previewTimer?.cancel();
    _loadTimer?.cancel();
    final previous = _player;
    _player = null;
    _onActivity?.call(false);
    _name = recording.name;
    _loading = true;
    _playing = false;
    _error = null;
    _notify();
    await _release(previous);
    if (!_current(request)) return;
    late final SoundPreviewPlayer player;
    try {
      player = _factory();
      _player = player;
      _loadTimer = Timer(loadTimeout, () => unawaited(_fail(request)));
      await player.setVolume(0.08);
      if (!_current(request)) return;
      await player.loadAsset(recording.assetPath);
      if (!_current(request)) return;
      _loadTimer?.cancel();
      _loading = false;
      _playing = true;
      _onActivity?.call(true);
      _notify();
      _previewTimer = Timer(previewDuration, () => unawaited(stop()));
      // just_audio's play future completes at stop/end, not at playback start.
      unawaited(
        player.play().then(
          (_) {
            if (_current(request)) unawaited(stop());
          },
          onError: (Object error, StackTrace stack) {
            if (_current(request)) unawaited(_fail(request));
          },
        ),
      );
    } catch (_) {
      if (_current(request)) await _fail(request);
    }
  }

  Future<void> _fail(int request) async {
    if (!_current(request)) return;
    ++_request;
    _previewTimer?.cancel();
    _loadTimer?.cancel();
    final player = _player;
    _player = null;
    _loading = false;
    _playing = false;
    _error = 'Preview could not play. Your mix was not changed.';
    _onActivity?.call(false);
    _notify();
    await _release(player);
  }

  Future<void> stop() async {
    if (_disposed) return;
    ++_request;
    _previewTimer?.cancel();
    _loadTimer?.cancel();
    final player = _player;
    _player = null;
    _loading = false;
    _playing = false;
    _name = null;
    _error = null;
    _onActivity?.call(false);
    _notify();
    await _release(player);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    _previewTimer?.cancel();
    _loadTimer?.cancel();
    _onActivity?.call(false);
    final player = _player;
    _player = null;
    unawaited(_release(player));
    super.dispose();
  }
}
