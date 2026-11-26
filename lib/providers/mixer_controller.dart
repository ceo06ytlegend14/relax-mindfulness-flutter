import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
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
  Map<String, double> _lastRequested = {};
  String _category = 'all';
  bool _availableOnly = true;
  String? _preset;
  bool _edited = false;
  bool _updating = false;
  bool _disposed = false;

  String get category => _category;
  bool get availableOnly => _availableOnly;
  bool isVisibleTrack(MixerTrack track) =>
      !_availableOnly || AppState.localSoundAssets.containsKey(track.name);
  int categoryCount(String id) => allMixerTracks
      .where(
        (track) =>
            (id == 'all' ||
                mixerCategories
                    .firstWhere((category) => category.id == id)
                    .tracks
                    .contains(track)) &&
            isVisibleTrack(track),
      )
      .length;
  bool isVisiblePreset(Map<String, double> levels) =>
      !_availableOnly ||
      levels.keys.every(AppState.localSoundAssets.containsKey);
  void setAvailableOnly(bool value) {
    if (_availableOnly == value) return;
    _availableOnly = value;
    if (_category != 'all' &&
        _category != 'favorites' &&
        categoryCount(_category) == 0) {
      _category = 'all';
    }
    notifyListeners();
  }

  String? get preset => _preset;
  bool get isPlaying => _app.activeAmbientTracks.isNotEmpty;
  bool get hasPlaybackRequest => _app.hasAmbientPlaybackRequest;
  bool get isPreparing => _app.isAmbientPlaybackPending;
  bool get canPause => isPlaying || isPreparing;
  bool get hasPlaybackError => _levels.entries.any(
    (entry) => entry.value > 0 && _app.ambientTrackError(entry.key) != null,
  );

  /// Counts only ready/playing players, never selected or pending layers.
  String get playbackStatusLabel {
    final requested = _app.requestedAmbientTracks;
    final playing = _app.activeAmbientTracks.length;
    var loading = 0;
    var buffering = 0;
    var paused = 0;
    for (final name in requested.keys) {
      switch (_app.ambientTrackStatus(name)) {
        case AmbientPlaybackStatus.loading:
          loading++;
        case AmbientPlaybackStatus.buffering:
          buffering++;
        case AmbientPlaybackStatus.paused:
          paused++;
        default:
          break;
      }
    }
    final failed = _levels.entries
        .where(
          (entry) =>
              entry.value > 0 && _app.ambientTrackError(entry.key) != null,
        )
        .length;
    final details = [
      if (loading > 0) '$loading loading',
      if (buffering > 0) '$buffering buffering',
      if (paused > 0) '$paused paused',
      if (failed > 0) '$failed unavailable',
    ];
    if (playing > 0) {
      return [
        'Playing · $playing ${playing == 1 ? 'layer' : 'layers'}',
        ...details,
      ].join(' · ');
    }
    if (loading > 0) return 'Loading soundscape…';
    if (buffering > 0) return 'Buffering soundscape…';
    if (requested.isNotEmpty) return 'Playback paused · tap play to resume';
    if (failed > 0) return 'Audio unavailable · tap play to retry';
    if (_app.hasAmbientSession) return 'Paused · Your sounds are kept';
    return 'Ready when you are · Not playing';
  }

  String get transportLabel => isPreparing
      ? 'Cancel pending soundscape'
      : isPlaying
      ? 'Pause soundscape'
      : hasPlaybackError
      ? 'Retry soundscape'
      : hasPlaybackRequest || _app.hasAmbientSession
      ? 'Resume soundscape'
      : 'Play soundscape';

  int get selectedCount => _levels.values.where((v) => v > 0).length;
  Map<String, double> get levels => Map.unmodifiable(_levels);
  double volume(String name) => _levels[name] ?? 0;

  void _restoreSelection() {
    final cached = _app.cachedVolumes;
    if (cached.isNotEmpty) _levels = _validated(cached);
    final active = _app.requestedAmbientTracks;
    if (active.isNotEmpty) _levels = _validated(active);
    _lastRequested = Map.of(active);
  }

  Map<String, double> _validated(Map<String, double> levels) => {
    for (final entry in levels.entries)
      if (entry.value.isFinite)
        entry.key: entry.value.clamp(0.0, 1.0).toDouble(),
  };

  void _onPlaybackChanged() {
    if (_updating || _disposed) return;
    final requested = _app.requestedAmbientTracks;
    // AppState initializes preferences after the first frame. A transient
    // ready/buffering event must not replace a selected mix with a subset.
    if (!_edited && requested.isEmpty && _lastRequested.isEmpty) {
      final cached = _app.cachedVolumes;
      if (cached.isNotEmpty) _levels = _validated(cached);
    }
    if (requested.isNotEmpty && !mapEquals(requested, _lastRequested)) {
      final withoutFailed = Map<String, double>.of(_lastRequested)
        ..removeWhere((name, _) => _app.ambientTrackError(name) != null);
      if (!mapEquals(requested, withoutFailed)) {
        _levels = _validated(requested);
        _preset = null;
      }
      // A failed layer keeps its selected level/name for an explicit retry.
    }
    _lastRequested = Map.of(requested);
    notifyListeners();
  }

  void selectCategory(String category) {
    if (category != 'all' &&
        category != 'favorites' &&
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

  void _playSelection({bool retryFailed = true, bool resumePaused = true}) {
    _updating = true;
    try {
      final names = {..._app.requestedAmbientTracks.keys, ..._levels.keys};
      for (final name in names) {
        final desired = volume(name);
        // Editing a level is not an explicit retry of this or another failed
        // layer. Keep its selected percentage and error for Play/Retry.
        if (desired > 0 &&
            !retryFailed &&
            _app.ambientTrackError(name) != null) {
          continue;
        }
        if (desired > 0 || _app.getTrackVolume(name) > 0) {
          // A looping AudioPlayer.play() future ends on pause, not on start.
          // Do not await individual looping tracks or serialize the mix on it.
          _launch(
            _app.updateSoundTrackVolume(
              name,
              desired,
              resumePaused: resumePaused,
              // Level edits never navigate. Master Play/applyMix explicitly
              // expand below; a toggle/slider keeps its inline mini-player.
              expandPlayer: false,
            ),
          );
        }
      }
      _lastRequested = Map.of(_app.requestedAmbientTracks);
    } finally {
      _updating = false;
    }
  }

  void _remember() {
    _edited = true;
    _app.saveCachedVolumes(Map.of(_levels));
  }

  void togglePlayback({bool expandPlayer = true}) {
    _remember();
    if (canPause) {
      // Pending loads must remain cancellable even before anything is playing.
      _launch(_app.pauseAllAmbientSoundTracks());
    } else {
      if (selectedCount == 0) _levels = {'Soft Rain': 0.3};
      _remember();
      _playSelection();
      if (expandPlayer) _app.showAmbientPlayer();
    }
    notifyListeners();
  }

  void setVolume(String name, double value, {bool preservePaused = false}) {
    if (!value.isFinite) return;
    _levels[name] = value.clamp(0.0, 1.0).toDouble();
    _preset = null;
    _remember();
    if (!preservePaused || hasPlaybackRequest) {
      _playSelection(
        retryFailed: false,
        // Platform interruptions retain requested levels. A gain gesture must
        // not restart their paused players; explicit Play owns that decision.
        resumePaused: !hasPlaybackRequest,
      );
    }
    if (selectedCount == 0) _launch(_app.stopAllAudio());
    notifyListeners();
  }

  void toggleTrack(String name) => setVolume(name, volume(name) > 0 ? 0 : 0.3);

  /// Retry only this failed layer at its selected level. Healthy loops and
  /// other failed selections must not be restarted, removed or reset to 30%.
  bool retryTrack(String name) {
    if (_disposed ||
        volume(name) <= 0 ||
        _app.ambientTrackError(name) == null ||
        !AppState.hasAmbientSource(name)) {
      return false;
    }
    _remember();
    _updating = true;
    try {
      _launch(
        _app.updateSoundTrackVolume(name, volume(name), expandPlayer: false),
      );
      _lastRequested = Map.of(_app.requestedAmbientTracks);
    } finally {
      _updating = false;
    }
    notifyListeners();
    return true;
  }

  void applyMix(Map<String, double> levels, {String? name}) {
    _levels = _validated(levels);
    _preset = name;
    _remember();
    _playSelection();
    if (selectedCount > 0)
      _app.showAmbientPlayer();
    else
      _launch(_app.stopAllAudio());
    notifyListeners();
  }

  /// A legacy name can already use this exact bundled clip. Never add that
  /// clip again just because another card has a different display name.
  String? replacementConflict(String from, String to) {
    final asset = bundledSoundAssets[to];
    for (final entry in _levels.entries) {
      if (entry.key == from || entry.value <= 0) continue;
      if (entry.key == to ||
          (asset != null && bundledSoundAssets[entry.key] == asset)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Swap one layer, not its underlying recording. Existing names/backup/share
  /// formats remain stable, and a paused selection must stay paused.
  bool replaceTrack(String from, String to) {
    if (_disposed ||
        from == to ||
        replacementConflict(from, to) != null ||
        !allMixerTracks.any((track) => track.name == from) ||
        !bundledRecordings.any((recording) => recording.name == to)) {
      return false;
    }
    final wasRequested = hasPlaybackRequest;
    final level = volume(from) > 0 ? volume(from) : 0.3;
    _levels = Map.of(_levels)
      ..remove(from)
      ..[to] = level;
    _category = mixerCategories
        .firstWhere(
          (category) => category.tracks.any((track) => track.name == to),
        )
        .id;
    _preset = null;
    _remember();
    if (wasRequested) _playSelection();
    notifyListeners();
    return true;
  }

  void shuffle() {
    final tracks = bundledRecordings.toList()..shuffle(_random);
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
