import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all 75 familiar sounds plus two new cards have real bundled cover assets',
    () async {
      expect(allMixerTracks, hasLength(77));
      expect(allMixerTracks.map((track) => track.name).toSet(), hasLength(77));
      final paths = allMixerTracks.map((track) => track.coverAsset).toSet();
      for (final path in paths) {
        expect(path, startsWith('assets/images/'));
        expect(
          (await rootBundle.load(path)).lengthInBytes,
          greaterThan(0),
          reason: path,
        );
      }
      for (final name in [
        'Rain on Leaves',
        'Urban Rain',
        'Light Drizzle',
        'Rain Cave',
      ]) {
        expect(allMixerTracks.any((track) => track.name == name), isTrue);
      }
    },
  );

  test(
    'the replacement library has 18 distinct local sources, not aliases',
    () async {
      expect(bundledRecordings, hasLength(18));
      final bytes = <String>{};
      for (final recording in bundledRecordings) {
        expect(
          allMixerTracks.any((track) => track.name == recording.name),
          isTrue,
        );
        expect(AppState.localSoundAssets[recording.name], recording.assetPath);
        final data = await rootBundle.load(recording.assetPath);
        bytes.add(
          base64Encode(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
        );
      }
      expect(bytes, hasLength(18), reason: 'Aliases are not new recordings');
      expect(
        bundledRecordings.any(
          (recording) => recording.assetPath.contains('calm_guided'),
        ),
        isFalse,
      );
    },
  );

  test(
    'new sources have per-file provenance and never fall back to unrelated streams',
    () async {
      final manifest =
          jsonDecode(
                await rootBundle.loadString('assets/sounds/ambient_pack.json'),
              )
              as Map<String, dynamic>;
      final entries = (manifest['sounds'] as List).cast<Map<String, dynamic>>();
      expect(entries, hasLength(12));
      expect(
        entries.where((entry) => entry['kind'] == 'field-recording'),
        hasLength(7),
      );
      expect(
        entries.where((entry) => entry['kind'] == 'generated-noise'),
        hasLength(5),
      );
      for (final entry in entries) {
        final name = entry['name'] as String;
        final choice = bundledRecordings.singleWhere(
          (recording) => recording.name == name,
        );
        expect(choice.assetPath, entry['asset']);
        expect(choice.credit, isNotEmpty);
        expect(AppState.hasAmbientSource(name), isTrue);
        expect(AppState.soundStreamUrls.containsKey(name), isFalse);
        expect(entry['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      }
    },
  );

  test('legacy names explicitly share their source identity', () {
    expect(bundledSoundAssets['Cozy Hearth'], bundledSoundAssets['Campfire']);
    expect(
      bundledSoundAssets['Singing Bowls'],
      bundledSoundAssets['Temple Bowl'],
    );
    expect(
      bundledSoundAssets['Wind Chimes'],
      bundledSoundAssets['Bamboo Chimes'],
    );
  });

  test(
    'recording families contain different existing sources, never rain aliases',
    () {
      expect(bundledRecordingFamilies, {
        'Fire': ['Campfire', 'Fireplace'],
        'Birds': ['Forest Birds', 'Woodland Morning'],
      });
      for (final entry in bundledRecordingFamilies.entries) {
        final choices = recordingChoicesForName(entry.value.first);
        expect(choices.map((recording) => recording.name), entry.value);
        expect(
          choices.map((recording) => recording.assetPath).toSet(),
          hasLength(2),
        );
        for (final name in entry.value) {
          expect(recordingFamilyForName(name), entry.key);
        }
      }
      expect(recordingFamilyForName('Cozy Hearth'), 'Fire');
      expect(
        recordingChoicesForName(
          'Cozy Hearth',
        ).map((recording) => recording.name),
        ['Campfire', 'Fireplace'],
      );
      for (final name in [
        'Soft Rain',
        'Light Drizzle',
        'Rain on Umbrella',
        'not a source',
      ]) {
        expect(recordingFamilyForName(name), isNull);
        expect(recordingChoicesForName(name), isEmpty);
      }
    },
  );
}
