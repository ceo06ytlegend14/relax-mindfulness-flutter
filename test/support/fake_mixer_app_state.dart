import 'package:flutter/foundation.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

/// No platform channels, network or looping audio futures in presentation tests.
class FakeMixerAppState extends ChangeNotifier implements AppState {
  final Map<String, double> active = {};
  final Map<String, String> ambientErrors = {};
  final Set<String> ambientLoading = {};
  bool previewDucked = false;

  @override
  String? ambientTrackError(String name) => ambientErrors[name];
  @override
  bool isAmbientTrackLoading(String name) => ambientLoading.contains(name);
  @override
  void setAmbientPreviewDucking(bool previewing) {
    previewDucked = previewing;
  }

  Map<String, double> cached = {};
  final Set<String> starred = {'Soft Rain', 'Ocean Waves', 'Campfire'};
  final List<SoundPreset> saved = [];
  final Map<String, String> renamed = {};
  final Set<String> libraryFavorites = {};
  final List<(String, int)> guidedRequests = [];
  String? guidedTitle;
  int guidedSeconds = 0;
  int guidedTotal = 0;
  bool guidedPlaying = false;
  bool guidedLoading = false;
  bool guidedExpanded = false;
  bool guidedLoop = true;
  String? guidedError;
  final List<bool> guidedCompletions = [];
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
  AppWallpaper get wallpaper => AppWallpaper.pureObsidian;
  @override
  bool get showMoodDialog => false;
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
      guidedPlaying = false;
      guidedLoading = false;
      active[name] = volume;
    } else {
      active.remove(name);
    }
    notifyListeners();
  }

  @override
  Future<void> stopAllAudio() async {
    guidedPlaying = false;
    guidedLoading = false;
    guidedExpanded = false;
    guidedTitle = null;
    guidedSeconds = 0;
    guidedTotal = 0;
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
  bool get isGuidedLoading => guidedLoading;
  @override
  bool get hasGuidedSession => guidedTitle != null;
  @override
  bool get isGuidedPlayerExpanded => hasGuidedSession && guidedExpanded;
  @override
  bool get canSeekGuidedSession => hasGuidedSession && !guidedLoading;
  @override
  String? get guidedPlaybackError => guidedError;
  @override
  bool get isGuidedLooping => guidedLoop;
  @override
  String? get currentGuidedTitle => guidedTitle;
  @override
  int get guidedRemainingSec => guidedSeconds;
  @override
  int get guidedTotalSec => guidedTotal;
  @override
  int get guidedElapsedSec => guidedTotal - guidedSeconds;
  @override
  Future<void> playGuidedSession(String title, int durationMins) async {
    active.clear();
    if (guidedTitle != title || guidedSeconds <= 0) {
      guidedTitle = title;
      guidedTotal = durationMins * 60;
      guidedSeconds = guidedTotal;
      guidedRequests.add((title, durationMins));
    }
    guidedPlaying = true;
    guidedExpanded = true;
    notifyListeners();
  }

  @override
  Future<void> resumeGuidedSession() async {
    if (!hasGuidedSession) return;
    active.clear();
    guidedPlaying = true;
    guidedError = null;
    notifyListeners();
  }

  @override
  void showGuidedPlayer() {
    guidedExpanded = true;
    notifyListeners();
  }

  @override
  void minimizeGuidedPlayer() {
    guidedExpanded = false;
    notifyListeners();
  }

  @override
  Future<void> pauseGuidedSession() async {
    guidedPlaying = false;
    notifyListeners();
  }

  @override
  void extendGuidedSession(int minutes) {
    guidedSeconds += minutes * 60;
    guidedTotal += minutes * 60;
    notifyListeners();
  }

  @override
  Future<void> toggleGuidedLoop() async {
    guidedLoop = !guidedLoop;
    notifyListeners();
  }

  @override
  Future<void> seekGuidedSession(int elapsedSeconds) async {
    guidedSeconds =
        guidedTotal - elapsedSeconds.clamp(0, guidedTotal - 1).toInt();
    notifyListeners();
  }

  @override
  Future<void> restartGuidedSession() => seekGuidedSession(0);
  @override
  Future<void> stopGuidedSession({bool completed = false}) async {
    guidedCompletions.add(completed);
    guidedPlaying = false;
    guidedExpanded = false;
    guidedTitle = null;
    guidedSeconds = 0;
    guidedTotal = 0;
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
