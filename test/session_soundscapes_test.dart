import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/models/session_soundscapes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every catalog session has one explicit, distinct arrangement', () {
    final cards = [
      (dailyMeditation.id, dailyMeditation.title),
      for (final session in meditationSessions) (session.id, session.title),
      for (final journey in sleepStories) (journey.id, journey.title),
    ];
    expect(cards, hasLength(23));
    expect(sessionSoundscapes, hasLength(23));
    final paths = <String>{};
    for (final (id, title) in cards) {
      final audio = sessionSoundscapeForTitle(title);
      expect(audio, isNotNull, reason: title);
      expect(audio!.id, id);
      expect(audio.sources, hasLength(2));
      expect(audio.sources.toSet(), hasLength(2));
      for (final source in audio.sources) {
        expect(bundledSoundAssets.containsKey(source), isTrue, reason: source);
      }
      paths.add(audio.assetPath);
    }
    expect(paths, hasLength(23));
  });

  test(
    'generated routes and actual bundled bytes match the recipe catalog',
    () async {
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/sounds/session_soundscapes.json',
                ),
              )
              as Map<String, dynamic>;
      for (final row in manifest['sessions'] as List<dynamic>) {
        final recipe = row as Map<String, dynamic>;
        final audio = sessionSoundscapeForTitle(recipe['title'] as String)!;
        expect(audio.assetPath, recipe['asset']);
        expect(audio.sources, [
          for (final layer in recipe['layers'] as List<dynamic>)
            (layer as Map<String, dynamic>)['recording'],
        ]);
        final bytes = await rootBundle.load(audio.assetPath);
        expect(bytes.lengthInBytes, recipe['bytes']);
      }
    },
  );

  test(
    'only explicit legacy titles alias; unknown content has no sample default',
    () {
      expect(
        sessionSoundscapeForTitle('Peaceful Morning Start'),
        same(sessionSoundscapeForTitle('Peaceful Morning Awakening')),
      );
      expect(
        sessionSoundscapeForTitle('Soft Sanctuary Horizon'),
        same(sessionSoundscapeForTitle(dailyMeditation.title)),
      );
      expect(sessionSoundscapeForTitle(null), isNull);
      expect(sessionSoundscapeForTitle('Missing practice'), isNull);
      expect(sessionSourceLabel('Missing practice'), 'Audio unavailable');
    },
  );

  test(
    'featured Meditate practices resolve to the same real catalog and audio IDs',
    () {
      expect(meditationSessions, hasLength(14));
      expect(featuredMeditationIds, [
        'gentle-relief',
        'quiet-mind',
        'body-rest',
      ]);
      for (final id in featuredMeditationIds) {
        final practice = meditationSessions.singleWhere(
          (session) => session.id == id,
        );
        expect(practice.favoriteId, 'meditation-$id');
        expect(sessionSoundscapeForTitle(practice.title)!.id, id);
        expect(practice.sourceLabel, isNot('Audio unavailable'));
      }
    },
  );

  test(
    'simple practice filters group old intents without changing any session',
    () {
      expect(simpleMeditationFilters, [
        'All',
        'Calm',
        'Focus',
        'Rest',
        'Saved',
      ]);
      final grouped = <String>{};
      for (final (filter, intents) in [
        ('Calm', {'Comfort', 'Healing'}),
        ('Focus', {'Focus', 'Morning'}),
        ('Rest', {'Sleep'}),
      ]) {
        final matches = meditationSessions.where(
          (session) => meditationMatchesFilter(session, filter, false),
        );
        expect(
          matches.map((session) => session.id),
          meditationSessions
              .where((session) => intents.contains(session.intent))
              .map((session) => session.id),
        );
        grouped.addAll(matches.map((session) => session.id));
      }
      expect(grouped, meditationSessions.map((session) => session.id).toSet());
      expect(
        meditationSessions.where(
          (session) => meditationMatchesFilter(session, 'All', false),
        ),
        hasLength(14),
      );
      expect(
        meditationMatchesFilter(meditationSessions.first, 'unknown', true),
        isFalse,
      );
    },
  );

  test(
    'Saved filter uses the existing favorite decision, not new access or playback state',
    () {
      for (final practice in [dailyMeditation, ...meditationSessions]) {
        expect(meditationMatchesFilter(practice, 'Saved', true), isTrue);
        expect(meditationMatchesFilter(practice, 'Saved', false), isFalse);
      }
    },
  );
}
