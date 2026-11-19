import 'package:flutter/foundation.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

/// No platform channels, network or looping audio futures in presentation tests.
class FakeMixerAppState extends ChangeNotifier implements AppState {
  final Map<String, double> active = {};
  Map<String, double> cached = {};
  final Set<String> starred = {'Soft Rain', 'Ocean Waves', 'Campfire'};
  final List<SoundPreset> saved = [];
  final Map<String, String> renamed = {};
  final Set<String> libraryFavorites = {};
  final List<(String, int)> guidedRequests = [];
  String? guidedTitle;
  int guidedSeconds = 0;
  bool guidedPlaying = false;
  int? timerSeconds;
  int? timerTotal;
  AppTab selectedTab = AppTab.home;

  @override
  Map<String, double> get cachedVolumes => Map.of(cached);
  @override
  Map<String, double> get activeAmbientTracks => Map.of(active);
  @override
  bool get isAnyAudioPlaying =>
      guidedPlaying || active.values.any((value) => value > 0);
  @override
  bool get isBackgroundMode => false;
  @override
  Set<String> get favoriteSounds => Set.unmodifiable(starred);
  @override
  List<SoundPreset> get presets => List.unmodifiable(saved);
  @override
  double getTrackVolume(String name) => active[name] ?? 0;
  @override
  bool isFavorite(String name) => starred.contains(name);
  @override
  String getPresetDisplayName(String originalName) =>
      renamed[originalName] ?? originalName;

  @override
  void renameCuratedPreset(String originalName, String newName) {
    renamed[originalName] = newName;
    notifyListeners();
  }

  @override
  Future<void> updateSoundTrackVolume(String name, double volume) async {
    if (volume > 0) {
      active[name] = volume;
    } else {
      active.remove(name);
    }
    notifyListeners();
  }

  @override
  Future<void> stopAllAudio() async {
    guidedPlaying = false;
    guidedTitle = null;
    active.clear();
    notifyListeners();
  }

  @override
  void saveCachedVolumes(Map<String, double> volumes) =>
      cached = Map.of(volumes);

  @override
  void toggleFavoriteSound(String name) {
    if (!starred.remove(name)) starred.add(name);
    notifyListeners();
  }

  @override
  void savePreset(String name, Map<String, double> volumes) {
    saved.add(SoundPreset(name: name, volumes: volumes));
    notifyListeners();
  }

  @override
  List<String> get favorites => List.unmodifiable(libraryFavorites);
  @override
  bool isFavoriteSoundId(String id) => libraryFavorites.contains(id);
  @override
  void toggleFavorite(String id) {
    if (!libraryFavorites.remove(id)) libraryFavorites.add(id);
    notifyListeners();
  }

  @override
  bool get isGuidedPlaying => guidedPlaying;
  @override
  String? get currentGuidedTitle => guidedTitle;
  @override
  int get guidedRemainingSec => guidedSeconds;
  @override
  Future<void> playGuidedSession(String title, int durationMins) async {
    active.clear();
    guidedTitle = title;
    guidedSeconds = durationMins * 60;
    guidedPlaying = true;
    guidedRequests.add((title, durationMins));
    notifyListeners();
  }

  @override
  Future<void> pauseGuidedSession() async {
    guidedPlaying = false;
    notifyListeners();
  }

  @override
  int? get sleepTimerRemainingSec => timerSeconds;
  @override
  int? get sleepTimerTotalSec => timerTotal;
  @override
  bool get isSleepTimerRunning => (timerSeconds ?? 0) > 0;
  @override
  void startSleepTimer(int minutes) {
    timerSeconds = minutes * 60;
    timerTotal = timerSeconds;
    notifyListeners();
  }

  @override
  void cancelSleepTimer() {
    timerSeconds = null;
    timerTotal = null;
    notifyListeners();
  }

  @override
  AppTab get tab => selectedTab;
  @override
  void setTab(AppTab tab) {
    selectedTab = tab;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
