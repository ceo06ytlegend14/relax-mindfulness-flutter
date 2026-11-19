import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all 75 familiar sound names remain and have real bundled cover assets',
    () async {
      expect(allMixerTracks, hasLength(75));
      expect(allMixerTracks.map((track) => track.name).toSet(), hasLength(75));
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
    'the replacement library has exactly six distinct existing local clips',
    () async {
      expect(bundledRecordings, hasLength(6));
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
      expect(bytes, hasLength(6), reason: 'Aliases are not new recordings');
      expect(
        bundledRecordings.any(
          (recording) => recording.assetPath.contains('calm_guided'),
        ),
        isFalse,
      );
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
}
