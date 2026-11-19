import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/inert_audio_player.dart';
import 'support/user_backup_fixture.dart' show validBackup;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late AppState app;
  final now = DateTime.utc(2026, 11, 19, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    app = AppState(
      guidedPlayer: InertAudioPlayer(),
      now: () => now,
      preferences: preferences,
    );
    app.toggleFavorite('existing-favorite');
    app.savePreset('Existing mix', {'Soft Rain': 0.4});
    app.recordSession(
      'Existing session',
      'Meditation',
      5,
      showMoodCheckIn: false,
    );
  });
  tearDown(() => app.dispose());

  Map<String, Object?> stored() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };

  test(
    'a malformed last record changes neither memory nor preferences',
    () async {
      final before = app.exportUserDataToJson();
      final persisted = stored();
      var notifications = 0;
      app.addListener(() => notifications++);
      final input = validBackup();
      (input['sessions'] as List).add({
        'id': 'bad-last-record',
        'mood': 'invalid',
      });
      expect(app.importUserDataFromJson(jsonEncode(input)), isFalse);
      await Future<void>.value();
      expect(app.exportUserDataToJson(), before);
      expect(stored(), persisted);
      expect(notifications, 0);
    },
  );

  test('review is side-effect free', () {
    final before = app.exportUserDataToJson();
    final persisted = stored();
    final review = app.validateUserBackupFromJson(jsonEncode(validBackup()));
    expect(review.values['favorites'], contains('story-starry-night'));
    expect(app.exportUserDataToJson(), before);
    expect(stored(), persisted);
  });

  test(
    'valid restore replaces supplied categories and persists reminder fields',
    () {
      expect(app.importUserDataFromJson(jsonEncode(validBackup())), isTrue);
      expect(app.favorites, ['meditation-gentle-relief', 'story-starry-night']);
      expect(app.favoriteSounds, {'Ocean Waves'});
      expect(app.presets.single.name, 'Evening ocean');
      expect(app.sessions.single.title, 'A quiet moment');
      expect(app.streak, 2);
      expect(app.longestStreak, 4);
      expect(app.themeMode, SanctuaryThemeMode.forestDusk);
      expect(app.reminderHour, 21);
      expect(app.reminderMinute, 30);
      expect(preferences.getBool('reminder_enabled'), true);
      expect(preferences.getInt('reminder_hour'), 21);
      expect(preferences.getInt('reminder_minute'), 30);
      expect(app.hasGuidedSession, isFalse);
      expect(app.isAnyAudioPlaying, isFalse);
    },
  );

  test(
    'a restored profile survives preference hydration without autoplay',
    () async {
      app.importUserDataFromJson(jsonEncode(validBackup()));
      final restarted = AppState(
        guidedPlayer: InertAudioPlayer(),
        now: () => now,
        preferences: preferences,
      );
      addTearDown(restarted.dispose);
      await restarted.init();
      expect(restarted.favorites, app.favorites);
      expect(restarted.presets.single.toJson(), app.presets.single.toJson());
      expect(restarted.sessions.single.toJson(), app.sessions.single.toJson());
      expect(restarted.reminderHour, 21);
      expect(restarted.isAnyAudioPlaying, isFalse);
    },
  );

  test('partial legacy restore preserves all omitted categories', () {
    final before =
        jsonDecode(app.exportUserDataToJson()) as Map<String, dynamic>;
    final persisted = stored();
    expect(app.importUserDataFromJson('{"theme_mode":"forestDusk"}'), isTrue);
    final after =
        jsonDecode(app.exportUserDataToJson()) as Map<String, dynamic>;
    expect(after..remove('theme_mode'), before..remove('theme_mode'));
    expect(stored(), {...persisted, 'theme_mode': 'forestDusk'});
  });

  test(
    'an inconsistent partial streak is rejected against the current profile',
    () {
      final before = app.exportUserDataToJson();
      expect(app.importUserDataFromJson('{"streak":999}'), isFalse);
      expect(app.exportUserDataToJson(), before);
    },
  );

  test(
    'imports cannot grant a subscription or overwrite billing preferences',
    () {
      preferences.setBool('is_premium', false);
      final input = validBackup()
        ..addAll({'is_premium': true, 'trial_active': true});
      expect(app.importUserDataFromJson(jsonEncode(input)), isTrue);
      expect(app.isPremium, isFalse);
      expect(app.trialActive, isFalse);
      expect(preferences.getBool('is_premium'), isFalse);
      expect(preferences.containsKey('trial_active'), isFalse);
    },
  );

  test('a profile exported by the app can be validated and restored', () {
    final source = app.exportUserDataToJson();
    expect(app.importUserDataFromJson(source), isTrue);
    expect(app.exportUserDataToJson(), source);
  });

  test(
    'restored history is chronological so latest-session exports stay honest',
    () {
      final input = validBackup();
      final older = Map<String, dynamic>.from(
        (input['sessions'] as List).single,
      );
      final newer = Map<String, dynamic>.from(older)
        ..['id'] = 'newer-session'
        ..['ts'] = (older['ts'] as int) + 60000;
      input['sessions'] = [older, newer];
      expect(app.importUserDataFromJson(jsonEncode(input)), isTrue);
      expect(app.sessions.first.id, 'newer-session');
      expect(app.sessions.last.id, 'session-1');
    },
  );

  test('an explicit empty category clears only that category', () {
    expect(app.importUserDataFromJson('{"favorites":[]}'), isTrue);
    expect(app.favorites, isEmpty);
    expect(app.presets.single.name, 'Existing mix');
    expect(app.sessions.single.title, 'Existing session');
  });

  test(
    'restore before storage is ready cannot be overwritten by late init',
    () {
      final early = AppState(guidedPlayer: InertAudioPlayer());
      addTearDown(early.dispose);
      expect(early.isUserDataReady, isFalse);
      expect(early.importUserDataFromJson(jsonEncode(validBackup())), isFalse);
      expect(early.favorites, isEmpty);
      expect(early.sessions, isEmpty);
    },
  );
  test(
    'a replacement round-trips as ordinary saved sound names and levels',
    () {
      final mixer = MixerController(app);
      addTearDown(mixer.dispose);
      expect(mixer.replaceTrack('Soft Rain', 'Ocean Waves'), isTrue);
      expect(mixer.saveMix('Replacement shoreline'), isTrue);
      final backup = app.exportUserDataToJson();
      final restored = AppState(
        guidedPlayer: InertAudioPlayer(),
        preferences: preferences,
      );
      addTearDown(restored.dispose);
      expect(restored.importUserDataFromJson(backup), isTrue);
      expect(restored.presets.first.name, 'Replacement shoreline');
      expect(restored.presets.first.volumes, {'Ocean Waves': .3});
      expect(restored.activeAmbientTracks, isEmpty);
      final validated = restored.validateUserBackupFromJson(backup);
      expect((validated.values['presets'] as List).first, {
        'name': 'Replacement shoreline',
        'volumes': {'Ocean Waves': .3},
      });
    },
  );
}
