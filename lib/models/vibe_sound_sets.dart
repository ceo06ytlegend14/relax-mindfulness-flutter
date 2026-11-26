/// Ten live mixer recipes, not new recordings or rendered/narrated sessions.
/// The preview mirrors this data; catalog_sync_test.mjs guards both clients.
class VibeSoundSet {
  const VibeSoundSet(
    this.id,
    this.name,
    this.purpose,
    this.vibe,
    this.icon,
    this.levels,
  );

  final String id, name, purpose, vibe, icon;
  final Map<String, double> levels;

  String get recipe => levels.entries
      .map((entry) => '${entry.key} ${(entry.value * 100).round()}%')
      .join(' · ');

  /// A user-saved mix can share a name without sharing this recipe. Never show
  /// official percentages for a custom/edited mix just because its name matches.
  bool matchesLevels(Map<String, double> candidate) {
    final selected = candidate.entries.where((entry) => entry.value > 0);
    return selected.length == levels.length &&
        selected.every(
          (entry) =>
              levels.containsKey(entry.key) &&
              (levels[entry.key]! - entry.value).abs() < 0.000001,
        );
  }
}

/// Values are independent volume-slider positions, not normalized proportions.
/// Requested slider totals are 1.10–1.65; the existing master gain, ducking and
/// fade rules still apply to output without rewriting these selected levels.
/// These levels are not an acoustic loudness or hearing-safety guarantee.
const vibeSoundSets = <VibeSoundSet>[
  VibeSoundSet(
    'rainy-window-cafe',
    'Rainy Window Café',
    'Focus',
    'Gentle rain, distant café chatter, a low-noise bed and light chimes.',
    'rain',
    {
      'Soft Rain': 0.65,
      'Coffee Shop': 0.25,
      'Brown Noise': 0.15,
      'Bamboo Chimes': 0.10,
    },
  ),
  VibeSoundSet(
    'enchanted-forest-morning',
    'Enchanted Forest Morning',
    'Morning',
    'Two woodland bird recordings with open-field breeze and a running stream.',
    'nature',
    {
      'Woodland Morning': 0.65,
      'Forest Birds': 0.55,
      'Meadow Breeze': 0.25,
      'Mountain Stream': 0.20,
    },
  ),
  VibeSoundSet(
    'ocean-deep-sleep',
    'Ocean Deep Sleep',
    'Sleep',
    'Rolling ocean waves over low brown noise and a little night cricket ambience.',
    'beach',
    {'Ocean Waves': 0.65, 'Brown Noise': 0.35, 'Crickets': 0.15},
  ),
  VibeSoundSet(
    'mountain-meditation',
    'Mountain Meditation',
    'Meditate',
    'Running water, field breeze, birds and a light singing-bowl layer.',
    'nature',
    {
      'Mountain Stream': 0.50,
      'Meadow Breeze': 0.30,
      'Forest Birds': 0.25,
      'Temple Bowl': 0.15,
    },
  ),
  VibeSoundSet(
    'cozy-fireplace-night',
    'Cozy Fireplace Night',
    'Comfort',
    'Indoor fire and night crickets with light rain and a low-noise bed.',
    'thunder',
    {
      'Fireplace': 0.65,
      'Crickets': 0.30,
      'Soft Rain': 0.20,
      'Brown Noise': 0.15,
    },
  ),
  VibeSoundSet(
    'tropical-rainforest',
    'Tropical Rainforest',
    'Relax',
    'A forest-inspired mix of running water, rain, birds and light field breeze.',
    'nature',
    {
      'Mountain Stream': 0.55,
      'Soft Rain': 0.40,
      'Forest Birds': 0.40,
      'Meadow Breeze': 0.15,
    },
  ),
  VibeSoundSet(
    'zen-temple-sanctuary',
    'Zen Temple Sanctuary',
    'Meditate',
    'Singing bowl, field breeze, stream and wind chimes for a quiet pause.',
    'places',
    {
      'Temple Bowl': 0.55,
      'Meadow Breeze': 0.25,
      'Mountain Stream': 0.20,
      'Bamboo Chimes': 0.15,
    },
  ),
  VibeSoundSet(
    'midnight-focus',
    'Midnight Focus',
    'Focus',
    'A brown-and-white noise bed with distant café chatter and light rain.',
    'noise',
    {
      'Brown Noise': 0.55,
      'White Noise': 0.30,
      'Coffee Shop': 0.15,
      'Soft Rain': 0.10,
    },
  ),
  VibeSoundSet(
    'campfire-under-stars',
    'Campfire Under Stars',
    'Relax',
    'An outdoor fire, night crickets, field breeze and a little ocean wash.',
    'nature',
    {
      'Campfire': 0.65,
      'Crickets': 0.50,
      'Meadow Breeze': 0.20,
      'Ocean Waves': 0.10,
    },
  ),
  VibeSoundSet(
    'peaceful-ocean-journey',
    'Peaceful Ocean Journey',
    'Escape',
    'Boat-rope creaks and rolling waves with field breeze and light chimes.',
    'transport',
    {
      'Boat Deck': 0.45,
      'Ocean Waves': 0.65,
      'Meadow Breeze': 0.20,
      'Bamboo Chimes': 0.10,
    },
  ),
];

VibeSoundSet? vibeSoundSetForName(String? name) {
  for (final soundSet in vibeSoundSets) {
    if (soundSet.name == name) return soundSet;
  }
  return null;
}
