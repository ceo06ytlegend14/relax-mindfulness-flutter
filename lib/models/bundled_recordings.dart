/// Existing app-provided clips only. This is a small replacement library, not
/// multiple recordings of every catalog sound or a newly licensed audio pack.
class BundledRecording {
  const BundledRecording(this.name, this.assetPath, this.description);
  final String name;
  final String assetPath;
  final String description;
}

/// Legacy names remain valid in saved mixes. Reused clips are aliases, not
/// additional recordings. Keep their source identity when rejecting duplicates.
const bundledSoundAssets = <String, String>{
  'Soft Rain': 'assets/sounds/soft_rain.mp3',
  'Ocean Waves': 'assets/sounds/ocean_waves.mp3',
  'Forest Birds': 'assets/sounds/forest_birds.mp3',
  'Campfire': 'assets/sounds/campfire.mp3',
  'Cozy Hearth': 'assets/sounds/campfire.mp3',
  'Wind Chimes': 'assets/sounds/wind_chimes.mp3',
  'Bamboo Chimes': 'assets/sounds/wind_chimes.mp3',
  'Singing Bowl': 'assets/sounds/tibetan_bowls.mp3',
  'Singing Bowls': 'assets/sounds/tibetan_bowls.mp3',
  'Tibetan Bowls': 'assets/sounds/tibetan_bowls.mp3',
  'Temple Bowl': 'assets/sounds/tibetan_bowls.mp3',
};

const bundledRecordings = <BundledRecording>[
  BundledRecording(
    'Soft Rain',
    'assets/sounds/soft_rain.mp3',
    'Gentle rainfall',
  ),
  BundledRecording(
    'Ocean Waves',
    'assets/sounds/ocean_waves.mp3',
    'Rolling shoreline waves',
  ),
  BundledRecording(
    'Forest Birds',
    'assets/sounds/forest_birds.mp3',
    'Birdsong and woodland atmosphere',
  ),
  BundledRecording('Campfire', 'assets/sounds/campfire.mp3', 'Crackling fire'),
  BundledRecording(
    'Bamboo Chimes',
    'assets/sounds/wind_chimes.mp3',
    'Wind-chime recording',
  ),
  BundledRecording(
    'Temple Bowl',
    'assets/sounds/tibetan_bowls.mp3',
    'Singing-bowl recording',
  ),
];
