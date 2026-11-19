import 'dart:convert';

/// Validates a complete or partial legacy backup without changing application
/// state. Unknown metadata is ignored; it can never grant paid access or execute
/// code. Collections are bounded and immutable after validation.
class UserBackupData {
  UserBackupData._(Map<String, dynamic> values)
    : values = Map<String, dynamic>.unmodifiable(values);

  static const version = '2.0.0';
  static const maxBytes = 2 * 1024 * 1024;
  final Map<String, dynamic> values;

  static UserBackupData parse(
    String source, {
    required Set<String> themeModes,
  }) {
    if (source.length > maxBytes || utf8.encode(source).length > maxBytes) {
      throw const FormatException('Backup exceeds the 2 MiB import limit.');
    }
    final input = _object(jsonDecode(source), 'backup');
    if (input.containsKey('version') && input['version'] != version) {
      throw const FormatException('This backup version is not supported.');
    }
    final result = <String, dynamic>{};
    for (final key in ['streak', 'longest_streak']) {
      if (input.containsKey(key)) {
        result[key] = _integer(input[key], key, 0, 1000000);
      }
    }
    if (result.containsKey('streak') &&
        result.containsKey('longest_streak') &&
        (result['streak'] as int) > (result['longest_streak'] as int)) {
      throw const FormatException(
        'Longest streak cannot be shorter than streak.',
      );
    }
    if (input.containsKey('theme_mode')) {
      final name = _text(input['theme_mode'], 'theme_mode', 64);
      if (!themeModes.contains(name)) {
        throw const FormatException('The backup uses an unknown theme.');
      }
      result['theme_mode'] = name;
    }
    for (final key in ['favorites', 'favorite_sounds']) {
      if (input.containsKey(key)) {
        final items = _list(input[key], key, 10000);
        result[key] = List<String>.unmodifiable(
          items.map((item) => _text(item, key, 256)).toSet(),
        );
      }
    }
    if (input.containsKey('presets')) {
      result['presets'] = List<Map<String, dynamic>>.unmodifiable(
        _list(input['presets'], 'presets', 1000).map((item) {
          final preset = _object(item, 'preset');
          final volumes = _object(preset['volumes'], 'volumes');
          if (volumes.length > 200) {
            throw const FormatException('A preset has too many tracks.');
          }
          final normalized = <String, double>{};
          for (final entry in volumes.entries) {
            _text(entry.key, 'track name', 256);
            final volume = entry.value;
            if (volume is! num ||
                !volume.isFinite ||
                volume < 0 ||
                volume > 1) {
              throw const FormatException(
                'Track levels must be between 0 and 1.',
              );
            }
            normalized[entry.key] = volume.toDouble();
          }
          return Map<String, dynamic>.unmodifiable({
            'name': _text(preset['name'], 'preset name', 256),
            'volumes': Map<String, double>.unmodifiable(normalized),
          });
        }),
      );
    }
    if (input.containsKey('renamed_presets')) {
      final names = _object(input['renamed_presets'], 'renamed_presets');
      if (names.length > 1000) {
        throw const FormatException('Too many preset names.');
      }
      result['renamed_presets'] = Map<String, String>.unmodifiable({
        for (final entry in names.entries)
          _text(entry.key, 'original preset name', 256): _text(
            entry.value,
            'preset name',
            256,
          ),
      });
    }
    if (input.containsKey('sessions')) {
      final ids = <String>{};
      result['sessions'] = List<Map<String, dynamic>>.unmodifiable(
        _list(input['sessions'], 'sessions', 5000).map((item) {
          final session = _object(item, 'session');
          final id = _text(session['id'], 'session id', 128);
          if (!ids.add(id)) {
            throw const FormatException('Session IDs must be unique.');
          }
          return Map<String, dynamic>.unmodifiable({
            'id': id,
            'title': _text(session['title'], 'session title', 256),
            'type': _text(session['type'], 'session type', 64),
            'dur': _integer(session['dur'], 'session duration', 0, 1440),
            'ts': _integer(
              session['ts'],
              'session timestamp',
              0,
              8640000000000000,
            ),
            'mood': session.containsKey('mood')
                ? _integer(session['mood'], 'mood', 0, 5)
                : 0,
          });
        }),
      );
    }
    if (input.containsKey('reminder_enabled')) {
      if (input['reminder_enabled'] is! bool) {
        throw const FormatException('reminder_enabled must be true or false.');
      }
      result['reminder_enabled'] = input['reminder_enabled'];
    }
    if (input.containsKey('reminder_hour')) {
      result['reminder_hour'] = _integer(
        input['reminder_hour'],
        'reminder_hour',
        0,
        23,
      );
    }
    if (input.containsKey('reminder_minute')) {
      result['reminder_minute'] = _integer(
        input['reminder_minute'],
        'reminder_minute',
        0,
        59,
      );
    }
    if (result.isEmpty) {
      throw const FormatException('No supported profile data was found.');
    }
    return UserBackupData._(result);
  }

  static Map<String, dynamic> _object(Object? value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$field must be a JSON object.');
    }
    return value;
  }

  static List<dynamic> _list(Object? value, String field, int maximum) {
    if (value is! List || value.length > maximum) {
      throw FormatException('$field must be a list of at most $maximum items.');
    }
    return value;
  }

  static String _text(Object? value, String field, int maximum) {
    if (value is! String || value.trim().isEmpty || value.length > maximum) {
      throw FormatException(
        '$field must be nonempty text up to $maximum characters.',
      );
    }
    return value;
  }

  static int _integer(Object? value, String field, int minimum, int maximum) {
    if (value is! int || value < minimum || value > maximum) {
      throw FormatException(
        '$field must be a whole number from $minimum to $maximum.',
      );
    }
    return value;
  }
}
