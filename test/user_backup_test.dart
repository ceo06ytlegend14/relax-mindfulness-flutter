import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/models/user_backup.dart';

import 'support/user_backup_fixture.dart';

UserBackupData parseBackup(Object? input) =>
    UserBackupData.parse(jsonEncode(input), themeModes: backupThemes);

void main() {
  test('the existing 2.0.0 export format is accepted without model loss', () {
    final input = validBackup();
    final backup = parseBackup(input);
    final expected = Map<String, dynamic>.of(input)
      ..remove('version')
      ..remove('exported_at');
    expect(backup.values, expected);
    expect(parseBackup(backup.values).values, backup.values);
  });

  test(
    'partial versionless legacy profiles retain only provided categories',
    () {
      expect(
        parseBackup({
          'favorites': ['one'],
        }).values,
        {
          'favorites': ['one'],
        },
      );
    },
  );

  for (final value in [
    null,
    [],
    4,
    true,
    'profile',
    {},
    {'version': '2.0.0'},
    {'unknown_field': 'data'},
    {'version': '99.0.0', 'streak': 0},
  ]) {
    test('unsupported or empty document is rejected: $value', () {
      expect(() => parseBackup(value), throwsFormatException);
    });
  }

  for (final invalid in <Map<String, dynamic>>[
    {'streak': -1},
    {'streak': 1.5},
    {'streak': true},
    {'streak': 8, 'longest_streak': 3},
    {'longest_streak': 1000001},
    {'theme_mode': 'missing-theme'},
    {'favorites': null},
    {
      'favorites': ['ok', 4],
    },
    {
      'favorite_sounds': ['  '],
    },
    {
      'presets': [
        {
          'name': 'Mix',
          'volumes': {'Soft Rain': -0.1},
        },
      ],
    },
    {
      'presets': [
        {
          'name': 'Mix',
          'volumes': {'Soft Rain': 1.1},
        },
      ],
    },
    {
      'presets': [
        {
          'name': 'Mix',
          'volumes': {'Soft Rain': '0.5'},
        },
      ],
    },
    {
      'presets': [
        {'name': '', 'volumes': {}},
      ],
    },
    {
      'renamed_presets': {'old': false},
    },
    {
      'sessions': [7],
    },
    {
      'sessions': [
        {'id': 'missing-other-fields'},
      ],
    },
    {'reminder_enabled': 'yes'},
    {'reminder_hour': 24},
    {'reminder_minute': 60},
    {'reminder_hour': 7.0},
  ]) {
    test(
      'invalid category is rejected before application: ${jsonEncode(invalid)}',
      () {
        expect(() => parseBackup(invalid), throwsFormatException);
      },
    );
  }

  for (final entry in <String, Object>{
    'dur': -1,
    'mood': 6,
    'ts': -1,
    'title': '',
    'type': 7,
    'id': '',
  }.entries) {
    test('session ${entry.key} validates its type and range', () {
      final input = validBackup();
      (input['sessions'] as List).single[entry.key] = entry.value;
      expect(() => parseBackup(input), throwsFormatException);
    });
  }

  test(
    'duplicate session IDs are rejected instead of silently discarding history',
    () {
      final input = validBackup();
      (input['sessions'] as List).add((input['sessions'] as List).first);
      expect(() => parseBackup(input), throwsFormatException);
    },
  );

  test(
    'duplicate favorites are normalized without reordering the selection',
    () {
      expect(
        parseBackup({
          'favorites': ['b', 'a', 'b'],
        }).values['favorites'],
        ['b', 'a'],
      );
    },
  );

  test('legacy sessions without mood are preserved as unrated', () {
    final input = validBackup();
    (input['sessions'] as List).single.remove('mood');
    expect((parseBackup(input).values['sessions'] as List).single['mood'], 0);
  });

  test('untrusted billing and credential metadata is never imported', () {
    final input = validBackup()
      ..addAll({
        'is_premium': true,
        'trial_active': true,
        'api_key': 'not-a-real-key',
      });
    final backup = parseBackup(input);
    for (final key in ['is_premium', 'trial_active', 'api_key']) {
      expect(backup.values.containsKey(key), isFalse);
    }
  });

  test('normalized collections cannot be mutated after review', () {
    final backup = parseBackup(validBackup());
    expect(() => backup.values['streak'] = 3, throwsUnsupportedError);
    expect(
      () => (backup.values['favorites'] as List).add('new'),
      throwsUnsupportedError,
    );
    final preset = (backup.values['presets'] as List).single;
    expect(
      () => (preset['volumes'] as Map)['Soft Rain'] = 2.0,
      throwsUnsupportedError,
    );
  });

  test('oversized input is rejected before JSON decoding', () {
    expect(
      () => UserBackupData.parse(
        'a'.padRight(UserBackupData.maxBytes + 1, 'a'),
        themeModes: backupThemes,
      ),
      throwsFormatException,
    );
  });

  test('the size limit counts UTF-8 bytes, not only string code units', () {
    final source = jsonEncode({
      'favorites': [List.filled(UserBackupData.maxBytes ~/ 2, 'é').join()],
    });
    expect(source.length, lessThan(UserBackupData.maxBytes));
    expect(
      () => UserBackupData.parse(source, themeModes: backupThemes),
      throwsFormatException,
    );
  });

  test('collection limits prevent an unbounded history restore', () {
    final input = validBackup();
    input['sessions'] = List.filled(5001, (input['sessions'] as List).single);
    expect(() => parseBackup(input), throwsFormatException);
  });

  test('non-finite exponent values are never accepted as volume levels', () {
    expect(
      () => UserBackupData.parse(
        '{"presets":[{"name":"Mix","volumes":{"Soft Rain":1e999}}]}',
        themeModes: backupThemes,
      ),
      throwsFormatException,
    );
  });
}
