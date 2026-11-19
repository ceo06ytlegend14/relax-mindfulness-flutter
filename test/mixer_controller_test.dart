import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';

import 'support/fake_mixer_app_state.dart';

void main() {
  late FakeMixerAppState app;
  late MixerController mixer;

  setUp(() {
    app = FakeMixerAppState();
    mixer = MixerController(app, random: Random(17));
  });

  tearDown(() {
    mixer.dispose();
    app.dispose();
  });

  test('default selection matches the reference without autoplay', () {
    expect(mixer.volume('Soft Rain'), 0.3);
    expect(mixer.selectedCount, 1);
    expect(mixer.isPlaying, isFalse);
    expect(app.active, isEmpty);
  });

  test(
    'preferences arriving after the first frame hydrate a paused selection',
    () {
      app.cached = {'Ocean Waves': 0.6};
      app.notifyListeners();
      expect(mixer.volume('Ocean Waves'), 0.6);
      expect(mixer.volume('Soft Rain'), 0);
      expect(mixer.isPlaying, isFalse);
    },
  );

  test('master pause and resume preserve levels', () {
    mixer.setVolume('Soft Rain', 0.45);
    expect(mixer.isPlaying, isTrue);
    mixer.togglePlayback();
    expect(mixer.isPlaying, isFalse);
    expect(mixer.volume('Soft Rain'), 0.45);
    mixer.togglePlayback();
    expect(app.active, {'Soft Rain': 0.45});
  });

  test('volume edits are clamped, finite and persisted', () {
    mixer.setVolume('Soft Rain', 4);
    expect(mixer.volume('Soft Rain'), 1);
    mixer.setVolume('Soft Rain', double.nan);
    expect(mixer.volume('Soft Rain'), 1);
    mixer.setVolume('Soft Rain', -2);
    expect(mixer.volume('Soft Rain'), 0);
    expect(app.cached['Soft Rain'], 0);
    expect(mixer.isPlaying, isFalse);
  });

  test('a preset replaces active tracks instead of accumulating them', () {
    mixer.togglePlayback();
    mixer.applyMix({'Ocean Waves': 0.7, 'Bamboo Chimes': 0.2}, name: 'Beach');
    expect(app.active, {'Ocean Waves': 0.7, 'Bamboo Chimes': 0.2});
    expect(mixer.volume('Soft Rain'), 0);
    expect(mixer.preset, 'Beach');
  });

  test(
    'the shared controller follows audio changes from other screens',
    () async {
      mixer.togglePlayback();
      await app.stopAllAudio();
      await app.updateSoundTrackVolume('Campfire', 0.5);
      expect(mixer.levels, {'Campfire': 0.5});
      expect(mixer.isPlaying, isTrue);
    },
  );

  test('guided playback is not reported as an active ambient mixer', () async {
    await app.playGuidedSession('Gentle Relief & Comfort', 15);
    expect(app.isGuidedPlaying, isTrue);
    expect(mixer.isPlaying, isFalse);
    expect(mixer.levels, {'Soft Rain': 0.3});
    mixer.togglePlayback();
    expect(mixer.isPlaying, isTrue);
    expect(app.isGuidedPlaying, isFalse);
    expect(app.hasGuidedSession, isTrue);
  });

  test('shuffle selects exactly three independent tracks', () {
    mixer.shuffle();
    expect(mixer.selectedCount, 3);
    expect(mixer.levels.values.every((v) => v >= 0.3 && v <= 0.6), isTrue);
  });

  test('saving snapshots the mix and rejects empty names', () {
    expect(mixer.saveMix('   '), isFalse);
    expect(mixer.saveMix(' Rainy evening '), isTrue);
    mixer.setVolume('Soft Rain', 0.8);
    expect(app.saved.single.name, 'Rainy evening');
    expect(app.saved.single.volumes['Soft Rain'], 0.3);
  });

  test(
    'a paused share link includes selected levels and preserves the host',
    () {
      final uri = mixer.shareUri(
        base: Uri.parse('https://example.com/preview/?lang=en'),
      );
      expect(uri.host, 'example.com');
      expect(uri.path, '/preview/');
      expect(uri.queryParameters['lang'], 'en');
      expect(uri.queryParameters['mix'], 'Soft Rain:30');
      expect(mixer.isPlaying, isFalse);
    },
  );

  test(
    'categories accept the catalog and favorites, not arbitrary strings',
    () {
      mixer.selectCategory('nature');
      expect(mixer.category, 'nature');
      mixer.selectCategory('invalid-category');
      expect(mixer.category, 'nature');
      mixer.selectCategory('favorites');
      expect(mixer.category, 'favorites');
    },
  );
}
