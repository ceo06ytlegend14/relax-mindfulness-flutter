/// One entry per distinct local source in the replacement chooser. Aliases in
/// saved mixes are source identities, never additional recordings.
class BundledRecording {
  const BundledRecording(
    this.name,
    this.assetPath,
    this.description, {
    this.credit,
  });
  final String name;
  final String assetPath;
  final String description;

  /// Recording-specific provenance for the new pack. Older app-provided audio
  /// is kept separate; its redistribution receipts still need owner review.
  final String? credit;
}

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
  'Woodland Morning': 'assets/sounds/woodland_morning.mp3',
  'Boat Deck': 'assets/sounds/boat_deck.mp3',
  'Mountain Stream': 'assets/sounds/woodland_stream.mp3',
  'Meadow Breeze': 'assets/sounds/meadow_wind.mp3',
  'Coffee Shop': 'assets/sounds/cafe_ambience.mp3',
  'Fireplace': 'assets/sounds/fireplace.mp3',
  'Crickets': 'assets/sounds/night_crickets.mp3',
  'White Noise': 'assets/sounds/noise_white.mp3',
  'Pink Noise': 'assets/sounds/noise_pink.mp3',
  'Brown Noise': 'assets/sounds/noise_brown.mp3',
  'Blue Noise': 'assets/sounds/noise_blue.mp3',
  'Violet Noise': 'assets/sounds/noise_violet.mp3',
};

/// The twelve additions have individual sources/terms and output checksums in
/// assets/sounds/ambient_pack.json. Noise is generated, not a field recording.
/// These grants do not clear the six legacy clips or unrelated stream URLs.
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
  BundledRecording(
    'Woodland Morning',
    'assets/sounds/woodland_morning.mp3',
    'Wood thrush and woodland birds',
    credit: 'kvgarlic · CC0',
  ),
  BundledRecording(
    'Boat Deck',
    'assets/sounds/boat_deck.mp3',
    'Rope creaks aboard a boat at night',
    credit: 'Falcet · CC0',
  ),
  BundledRecording(
    'Mountain Stream',
    'assets/sounds/woodland_stream.mp3',
    'Meandering woodland stream',
    credit: 'gluckose · CC0',
  ),
  BundledRecording(
    'Meadow Breeze',
    'assets/sounds/meadow_wind.mp3',
    'Wind across an open field',
    credit: 'felix.blume · CC0',
  ),
  BundledRecording(
    'Coffee Shop',
    'assets/sounds/cafe_ambience.mp3',
    'Restaurant chatter and room ambience',
    credit: 'stephan · Public domain',
  ),
  BundledRecording(
    'Fireplace',
    'assets/sounds/fireplace.mp3',
    'Indoor fire, crackles and sizzle',
    credit: 'ezwa · Public domain',
  ),
  BundledRecording(
    'Crickets',
    'assets/sounds/night_crickets.mp3',
    'Crickets chirping at night',
    credit: 'Lisa Redfern · Public domain',
  ),
  BundledRecording(
    'White Noise',
    'assets/sounds/noise_white.mp3',
    'Generated flat-spectrum noise',
    credit: 'Sanctuary project · CC0',
  ),
  BundledRecording(
    'Pink Noise',
    'assets/sounds/noise_pink.mp3',
    'Generated, gently weighted noise',
    credit: 'Sanctuary project · CC0',
  ),
  BundledRecording(
    'Brown Noise',
    'assets/sounds/noise_brown.mp3',
    'Generated low-weighted rumble',
    credit: 'Sanctuary project · CC0',
  ),
  BundledRecording(
    'Blue Noise',
    'assets/sounds/noise_blue.mp3',
    'Generated high-weighted hiss',
    credit: 'Sanctuary project · CC0',
  ),
  BundledRecording(
    'Violet Noise',
    'assets/sounds/noise_violet.mp3',
    'Generated bright, high-weighted noise',
    credit: 'Sanctuary project · CC0',
  ),
];

/// Existing related recordings, not fabricated alternate takes of every card.
const bundledRecordingFamilies = <String, List<String>>{
  'Fire': ['Campfire', 'Fireplace'],
  'Birds': ['Forest Birds', 'Woodland Morning'],
};

String? recordingFamilyForName(String name) {
  final asset = bundledSoundAssets[name];
  if (asset == null) return null;
  for (final entry in bundledRecordingFamilies.entries) {
    if (entry.value.any((choice) => bundledSoundAssets[choice] == asset)) {
      return entry.key;
    }
  }
  return null;
}

List<BundledRecording> recordingChoicesForName(String name) {
  final family = recordingFamilyForName(name);
  if (family == null) return const [];
  return List.unmodifiable(
    bundledRecordings.where(
      (recording) => bundledRecordingFamilies[family]!.contains(recording.name),
    ),
  );
}
