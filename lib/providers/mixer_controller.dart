import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

/// Shared presentation state: Home and Sounds never keep competing local mixes.
/// Restoring a mix selects its levels, but deliberately does not autoplay it.
class MixerController extends ChangeNotifier {
  MixerController(this._app, {Random? random}) : _random = random ?? Random() {
    _restoreSelection();
    _app.addListener(_onPlaybackChanged);
  }

  final AppState _app;
  final Random _random;
  Map<String, double> _levels = {'Soft Rain': 0.3};
  Map<String, double> _lastActive = {};
  String _category = 'rain';
  String? _preset;
  bool _edited = false;
  bool _updating = false;
  bool _disposed = false;

  String get category => _category;
  String? get preset => _preset;
  bool get isPlaying => _app.activeAmbientTracks.isNotEmpty;
  int get selectedCount => _levels.values.where((v) => v > 0).length;
  Map<String, double> get levels => Map.unmodifiable(_levels);
  double volume(String name) => _levels[name] ?? 0;

  void _restoreSelection() {
    final cached = _app.cachedVolumes;
    if (cached.isNotEmpty) _levels = _validated(cached);
    final active = _app.activeAmbientTracks;
    if (active.isNotEmpty) _levels = _validated(active);
    _lastActive = Map.of(active);
  }

  Map<String, double> _validated(Map<String, double> levels) => {
    for (final entry in levels.entries)
      if (entry.value.isFinite)
        entry.key: entry.value.clamp(0.0, 1.0).toDouble(),
  };

  void _onPlaybackChanged() {
    if (_updating || _disposed) return;
    // AppState initializes preferences after the first frame.
    if (!_edited) _restoreSelection();
    final active = _app.activeAmbientTracks;
    if (active.isNotEmpty && !mapEquals(active, _lastActive)) {
      _levels = _validated(active);
      _preset = null;
    }
    _lastActive = Map.of(active);
    notifyListeners();
  }

  void selectCategory(String category) {
    if (category != 'favorites' &&
        !mixerCategories.any((item) => item.id == category)) {
      return;
    }
    _category = category;
    notifyListeners();
  }

  void _launch(Future<void> operation) {
    unawaited(
      operation.catchError((Object error, StackTrace stack) {
        debugPrint('Mixer playback operation failed: $error');
      }),
    );
  }

  void _playSelection() {
    _updating = true;
    try {
      final names = {..._app.activeAmbientTracks.keys, ..._levels.keys};
      for (final name in names) {
        final desired = volume(name);
        if (desired > 0 || _app.getTrackVolume(name) > 0) {
          // A looping AudioPlayer.play() future ends on pause, not on start.
          // Do not await individual looping tracks or serialize the mix on it.
          _launch(_app.updateSoundTrackVolume(name, desired));
        }
      }
      _lastActive = Map.of(_app.activeAmbientTracks);
    } finally {
      _updating = false;
    }
  }

  void _remember() {
    _edited = true;
    _app.saveCachedVolumes(Map.of(_levels));
  }

  void togglePlayback() {
    _remember();
    if (isPlaying) {
      _launch(_app.stopAllAudio());
    } else {
      if (selectedCount == 0) _levels = {'Soft Rain': 0.3};
      _remember();
      _playSelection();
    }
    notifyListeners();
  }

  void setVolume(String name, double value) {
    if (!value.isFinite) return;
    _levels[name] = value.clamp(0.0, 1.0).toDouble();
    _preset = null;
    _remember();
    _playSelection();
    notifyListeners();
  }

  void toggleTrack(String name) => setVolume(name, volume(name) > 0 ? 0 : 0.3);

  void applyMix(Map<String, double> levels, {String? name}) {
    _levels = _validated(levels);
    _preset = name;
    _remember();
    _playSelection();
    notifyListeners();
  }

  void shuffle() {
    final tracks = allMixerTracks.toList()..shuffle(_random);
    applyMix({
      for (final track in tracks.take(3))
        track.name: (3 + _random.nextInt(4)) / 10,
    });
  }

  bool saveMix(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || selectedCount == 0) return false;
    _app.savePreset(trimmed, Map.of(_levels));
    return true;
  }

  Uri shareUri({Uri? base}) {
    final location = base ?? Uri.https('sanctuary.app', '/allinone/');
    final mix = _levels.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}:${(entry.value * 100).round()}')
        .join(',');
    return location.replace(
      queryParameters: {...location.queryParameters, 'mix': mix},
      fragment: '',
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _app.removeListener(_onPlaybackChanged);
    super.dispose();
  }
}
