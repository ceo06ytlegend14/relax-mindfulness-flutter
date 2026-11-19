/// Local presentation assets and the existing meditation/sleep session catalog.
/// Playback is still provided by AppState; artwork never contains interface text.
class MeditationSession {
  const MeditationSession({
    required this.id,
    required this.title,
    required this.minutes,
    required this.intent,
    required this.eyebrow,
    required this.description,
    required this.artwork,
    required this.backdrop,
  });

  final String id, title, intent, eyebrow, description, artwork, backdrop;
  final int minutes;
  String get favoriteId => 'meditation-$id';
}

const dailyMeditation = MeditationSession(
  id: 'calm-mountain',
  title: 'Calm Mountain Horizon',
  minutes: 10,
  intent: 'Comfort',
  eyebrow: 'DAILY GUIDED JOURNEY',
  description: 'Deep Relaxation',
  artwork: 'assets/images/meditate/daily_journey.webp',
  backdrop: 'assets/images/meditate/forest_sunrise.webp',
);

const meditationIntents = [
  'All',
  'Comfort',
  'Morning',
  'Sleep',
  'Focus',
  'Healing',
];

const meditationSessions = [
  MeditationSession(
    id: 'gentle-relief',
    title: 'Gentle Relief & Comfort',
    minutes: 15,
    intent: 'Comfort',
    eyebrow: 'GENTLE REMINDER',
    description:
        'Soften your heart, ease tension, and find comfort in the present moment.',
    artwork: 'assets/images/meditate/comfort.webp',
    backdrop: 'assets/images/meditate/comfort_backdrop.webp',
  ),
  MeditationSession(
    id: 'body-rest',
    title: 'Soft Body Rest & Ease',
    minutes: 18,
    intent: 'Comfort',
    eyebrow: 'HEART & BODY',
    description:
        'Warm ocean waves to help your body feel completely weightless and safe.',
    artwork: 'assets/images/meditate/body_rest.webp',
    backdrop: 'assets/images/meditate/body_backdrop.webp',
  ),
  MeditationSession(
    id: 'morning-awakening',
    title: 'Peaceful Morning Awakening',
    minutes: 10,
    intent: 'Morning',
    eyebrow: 'MORNING BOOST',
    description:
        'Gentle morning birds and soft warmth to welcome a brand new day.',
    artwork: 'assets/images/meditate/morning.webp',
    backdrop: 'assets/images/meditate/morning_backdrop.webp',
  ),
  MeditationSession(
    id: 'quiet-mind',
    title: 'Quiet Mind Sanctuary',
    minutes: 8,
    intent: 'Morning',
    eyebrow: 'QUIET MIND',
    description:
        'A soft quiet space to rest your thoughts without any pressure.',
    artwork: 'assets/images/meditate/quiet_mind.webp',
    backdrop: 'assets/images/meditate/quiet_backdrop.webp',
  ),
  MeditationSession(
    id: 'bedtime-slumber',
    title: 'Cozy Bedtime Slumber',
    minutes: 20,
    intent: 'Sleep',
    eyebrow: 'EASE INTO SLEEP',
    description:
        'A gentle bedtime soundscape to help you drift into sweet, easy rest.',
    artwork: 'assets/images/sleep/night_forest.webp',
    backdrop: 'assets/images/meditate/quiet_backdrop.webp',
  ),
  MeditationSession(
    id: 'crystal-chimes',
    title: 'Healing Crystal Chimes',
    minutes: 35,
    intent: 'Sleep',
    eyebrow: 'RESTFUL HARMONY',
    description:
        'Peaceful harmonic chimes for a slower, softer end to your day.',
    artwork: 'assets/images/meditate/quiet_mind.webp',
    backdrop: 'assets/images/meditate/body_backdrop.webp',
  ),
  MeditationSession(
    id: 'warm-heart',
    title: 'Warm Heart Comfort',
    minutes: 15,
    intent: 'Healing',
    eyebrow: 'A LITTLE KINDNESS',
    description: 'Feel held in a soft, gentle sanctuary of warmth.',
    artwork: 'assets/images/meditate/comfort.webp',
    backdrop: 'assets/images/meditate/comfort_backdrop.webp',
  ),
  MeditationSession(
    id: 'peaceful-haven',
    title: 'Peaceful Haven Journey',
    minutes: 25,
    intent: 'Focus',
    eyebrow: 'ROOM TO FOCUS',
    description: 'Follow a quiet forest stream into your own peaceful place.',
    artwork: 'assets/images/meditate/quiet_mind.webp',
    backdrop: 'assets/images/meditate/quiet_backdrop.webp',
  ),
  MeditationSession(
    id: 'breeze-rest',
    title: 'Gentle Breeze Rest',
    minutes: 30,
    intent: 'Healing',
    eyebrow: 'LET IT BE LIGHT',
    description:
        'Whispering pine trees and a little space to let heavy thoughts pass.',
    artwork: 'assets/images/sleep/night_forest.webp',
    backdrop: 'assets/images/meditate/quiet_backdrop.webp',
  ),
  MeditationSession(
    id: 'loving-warmth',
    title: 'Loving Warmth & Peace',
    minutes: 15,
    intent: 'Healing',
    eyebrow: 'COME AS YOU ARE',
    description: 'Cozy companion warmth to bring a little peace to your day.',
    artwork: 'assets/images/meditate/comfort.webp',
    backdrop: 'assets/images/meditate/comfort_backdrop.webp',
  ),
  MeditationSession(
    id: 'ocean-horizon',
    title: 'Ocean Horizon Slumber',
    minutes: 25,
    intent: 'Sleep',
    eyebrow: 'FOLLOW THE TIDE',
    description:
        'Lapping waves under moonlight for a gentle journey toward sleep.',
    artwork: 'assets/images/sleep/ocean_waves.webp',
    backdrop: 'assets/images/meditate/body_backdrop.webp',
  ),
  MeditationSession(
    id: 'solfeggio',
    title: 'Chakra Solfeggio Alignment',
    minutes: 30,
    intent: 'Healing',
    eyebrow: 'FIND YOUR BALANCE',
    description:
        'A quiet moment with resonant crystal tones and room to breathe.',
    artwork: 'assets/images/meditate/daily_journey.webp',
    backdrop: 'assets/images/meditate/morning_backdrop.webp',
  ),
  MeditationSession(
    id: 'forest-bathing',
    title: 'Pine Forest Bathing',
    minutes: 20,
    intent: 'Comfort',
    eyebrow: 'BACK TO NATURE',
    description: 'Walk among whispering pines and fresh mountain air.',
    artwork: 'assets/images/meditate/quiet_mind.webp',
    backdrop: 'assets/images/meditate/quiet_backdrop.webp',
  ),
  MeditationSession(
    id: 'release-tension',
    title: 'Release Anxious Tension',
    minutes: 12,
    intent: 'Comfort',
    eyebrow: 'SOFTEN & RELEASE',
    description:
        'Slow down and make a little room for ease, one breath at a time.',
    artwork: 'assets/images/meditate/body_rest.webp',
    backdrop: 'assets/images/meditate/body_backdrop.webp',
  ),
];

class SleepSoundscape {
  const SleepSoundscape({
    required this.id,
    required this.title,
    required this.minutes,
    required this.artwork,
    required this.levels,
  });

  final String id, title, artwork;
  final int minutes;
  final Map<String, double> levels;
}

const oceanSleepJourney = SleepSoundscape(
  id: 'ocean-sleep',
  title: 'Ocean Sleep',
  minutes: 45,
  artwork: 'assets/images/sleep/ocean_journey.webp',
  levels: {'Ocean Waves': 0.7, 'Soft Rain': 0.3},
);

const sleepSoundscapes = [
  SleepSoundscape(
    id: 'ocean-waves',
    title: 'Ocean Waves',
    minutes: 45,
    artwork: 'assets/images/sleep/ocean_waves.webp',
    levels: {'Ocean Waves': 0.6},
  ),
  SleepSoundscape(
    id: 'campfire',
    title: 'Campfire',
    minutes: 35,
    artwork: 'assets/images/sleep/campfire.webp',
    levels: {'Campfire': 0.6},
  ),
  SleepSoundscape(
    id: 'night-forest',
    title: 'Night Forest',
    minutes: 40,
    artwork: 'assets/images/sleep/night_forest.webp',
    levels: {'Night Forest': 0.5, 'Soothing Breeze': 0.2},
  ),
  SleepSoundscape(
    id: 'heavy-rain',
    title: 'Heavy Rain',
    minutes: 30,
    artwork: 'assets/images/sleep/heavy_rain.webp',
    levels: {'Heavy Rain': 0.6},
  ),
  SleepSoundscape(
    id: 'thunderstorm',
    title: 'Thunderstorm',
    minutes: 45,
    artwork: 'assets/images/sleep/thunderstorm.webp',
    levels: {'Thunderstorm': 0.5, 'Soft Rain': 0.25},
  ),
];

class SleepStory {
  const SleepStory({
    required this.id,
    required this.title,
    required this.narrator,
    required this.minutes,
    required this.artwork,
  });

  final String id, title, narrator, artwork;
  final int minutes;
  String get favoriteId => 'story-$id';
}

const sleepStories = [
  SleepStory(
    id: 'starry-night',
    title: 'The Starry Night',
    narrator: 'Emma Wallace',
    minutes: 35,
    artwork: 'assets/images/sleep/thunderstorm.webp',
  ),
  SleepStory(
    id: 'dreamland',
    title: 'Journey to Dreamland',
    narrator: 'James Harrington',
    minutes: 42,
    artwork: 'assets/images/sleep/ocean_waves.webp',
  ),
  SleepStory(
    id: 'hidden-waterfall',
    title: 'The Hidden Waterfall',
    narrator: 'Luna Harmony',
    minutes: 38,
    artwork: 'assets/images/meditate/quiet_mind.webp',
  ),
  SleepStory(
    id: 'lighthouse',
    title: 'The Lighthouse Keeper',
    narrator: 'Oliver M.',
    minutes: 40,
    artwork: 'assets/images/sleep/ocean_waves.webp',
  ),
  SleepStory(
    id: 'japanese-garden',
    title: 'Moonlit Japanese Garden',
    narrator: 'Mei Lin',
    minutes: 35,
    artwork: 'assets/images/meditate/quiet_mind.webp',
  ),
  SleepStory(
    id: 'whispering-pines',
    title: 'Whispering Pine Forest',
    narrator: 'Julian Ross',
    minutes: 28,
    artwork: 'assets/images/sleep/night_forest.webp',
  ),
  SleepStory(
    id: 'stargazing',
    title: 'Desert Stargazing',
    narrator: 'Kai Thompson',
    minutes: 32,
    artwork: 'assets/images/sleep/thunderstorm.webp',
  ),
  SleepStory(
    id: 'temple-bells',
    title: 'Ancient Temple Bells',
    narrator: 'Ravi Sharma',
    minutes: 45,
    artwork: 'assets/images/meditate/daily_journey.webp',
  ),
];

String sleepArtworkForTrack(String name) {
  for (final soundscape in sleepSoundscapes) {
    if (soundscape.title == name) return soundscape.artwork;
  }
  return switch (name) {
    'Soft Rain' => 'assets/images/mixer/soft_rain.webp',
    'Rain on Window' => 'assets/images/mixer/rain_window.webp',
    'Soothing Breeze' ||
    'Mountain Stream' => 'assets/images/meditate/quiet_mind.webp',
    _ => 'assets/images/sleep/continue_listening.webp',
  };
}
