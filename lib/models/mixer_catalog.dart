import 'package:flutter/material.dart';

/// Presentation metadata shared by the landing page and the Sounds tab.
class MixerTrack {
  const MixerTrack(
    this.emoji,
    this.name,
    this.description,
    this.color, {
    this.artwork,
  });
  final String emoji, name, description;
  final Color color;
  final String? artwork;
}

class MixerCategory {
  const MixerCategory(this.id, this.emoji, this.label, this.tracks);
  final String id, emoji, label;
  final List<MixerTrack> tracks;
}

const mixerCategories = <MixerCategory>[
  MixerCategory('rain', '🌧️', 'Rain', [
    MixerTrack(
      '🌧️',
      'Soft Rain',
      'Gentle Downpour',
      Color(0xFF42A5F5),
      artwork: 'assets/images/mixer/soft_rain.webp',
    ),
    MixerTrack(
      '⛈️',
      'Thunderstorm',
      'Distant Low Rumble',
      Color(0xFF5C6BC0),
      artwork: 'assets/images/mixer/thunderstorm.webp',
    ),
    MixerTrack(
      '🪟',
      'Rain on Window',
      'Soft Drops on Glass',
      Color(0xFF29B6F6),
      artwork: 'assets/images/mixer/rain_window.webp',
    ),
    MixerTrack(
      '🏠',
      'Rain on Roof',
      'Cozy Attic Downpour',
      Color(0xFF0288D1),
      artwork: 'assets/images/mixer/rain_roof.webp',
    ),
    MixerTrack(
      '🌂',
      'Rain on Umbrella',
      'Rhythmic Pitter Patter',
      Color(0xFF039BE5),
      artwork: 'assets/images/mixer/rain_umbrella.webp',
    ),
    MixerTrack(
      '⛺',
      'Rain on Tent',
      'Wilderness Camping Rain',
      Color(0xFF00ACC1),
      artwork: 'assets/images/mixer/rain_tent.webp',
    ),
    MixerTrack(
      '🍃',
      'Rain on Leaves',
      'Forest Canopy Drizzle',
      Color(0xFF26A69A),
    ),
    MixerTrack('🏙️', 'Urban Rain', 'City Street Rainfall', Color(0xFF78909C)),
    MixerTrack(
      '🌧️',
      'Heavy Rain',
      'Continuous Pouring Storm',
      Color(0xFF1E88E5),
    ),
    MixerTrack(
      '🌧️',
      'Light Drizzle',
      'Gentle Atmospheric Mist',
      Color(0xFF80DEEA),
    ),
    MixerTrack('洞', 'Rain Cave', 'Echoing Cavern Drops', Color(0xFF3F51B5)),
    MixerTrack(
      '🌴',
      'Tropical Storm',
      'Warm Rainforest Gale',
      Color(0xFF00897B),
    ),
  ]),
  MixerCategory('nature', '🌲', 'Nature', [
    MixerTrack('🌊', 'Ocean Waves', 'Rolling Pacific Tide', Color(0xFF26A69A)),
    MixerTrack(
      '🏞️',
      'Mountain Stream',
      'Flowing Crystal Creek',
      Color(0xFF66BB6A),
    ),
    MixerTrack('🐦', 'Forest Birds', 'Morning Canopy Chirp', Color(0xFF9CCC65)),
    MixerTrack('🔥', 'Campfire', 'Warm Crackling Wood Logs', Color(0xFFFF7043)),
    MixerTrack(
      '💨',
      'Wind in Trees',
      'Calm Mountain Breeze',
      Color(0xFF78909C),
    ),
    MixerTrack('🦗', 'Crickets', 'Night Meadow Symphony', Color(0xFF8D6E63)),
    MixerTrack('🌊', 'Waterfall', 'Majestic Cascade Spray', Color(0xFF00BCD4)),
    MixerTrack('🐸', 'Frogs', 'Serene Marshland Night', Color(0xFF4CAF50)),
    MixerTrack(
      '🪨',
      'Waves on Pebbles',
      'Gentle Shoreline Shimmer',
      Color(0xFF80CBC4),
    ),
    MixerTrack('🤿', 'Underwater', 'Deep Ocean Submersion', Color(0xFF0277BD)),
    MixerTrack(
      '🌾',
      'Meadow Breeze',
      'Soft Grasslands Whispers',
      Color(0xFFAED581),
    ),
    MixerTrack('🏜️', 'Desert Wind', 'Solitary Dune Sweep', Color(0xFFFFB74D)),
    MixerTrack('🌴', 'Jungle Night', 'Nocturnal Rainforest', Color(0xFF2E7D32)),
    MixerTrack('🍂', 'Leaves Rustling', 'Autumn Footsteps', Color(0xFFD84315)),
    MixerTrack(
      '⛰️',
      'Mountain Echo',
      'Resonant Valley Stillness',
      Color(0xFF546E7A),
    ),
  ]),
  MixerCategory('places', '🪷', 'Places', [
    MixerTrack('☕', 'Coffee Shop', 'Gentle Ambient Chatter', Color(0xFF8D6E63)),
    MixerTrack('📚', 'Library', 'Silent Study Sanctuary', Color(0xFF5D4037)),
    MixerTrack(
      '🏢',
      'Office Ambience',
      'Low Productivity Hum',
      Color(0xFF78909C),
    ),
    MixerTrack(
      '🔔',
      'Church Bells',
      'Distant Resonant Chimes',
      Color(0xFFFFB300),
    ),
    MixerTrack('🌳', 'Quiet Park', 'Peaceful Bench Retreat', Color(0xFF7CB342)),
    MixerTrack(
      '🛍️',
      'Street Market',
      'Soft Bustling Market',
      Color(0xFFFB8C00),
    ),
    MixerTrack('🥣', 'Temple Bowl', 'Zen Monastery Gong', Color(0xFFAB47BC)),
    MixerTrack('🎍', 'Zen Garden', 'Raked Sand Fountain', Color(0xFF00ACC1)),
    MixerTrack('⚓', 'Harbor', 'Gentle Boat Dock Lapping', Color(0xFF0288D1)),
    MixerTrack('🚜', 'Farmyard', 'Rural Countryside', Color(0xFF8BC34A)),
  ]),
  MixerCategory('transport', '🚆', 'Transport', [
    MixerTrack(
      '🚆',
      'Train Track',
      'Rhythmic Iron Rail Clicker',
      Color(0xFF546E7A),
    ),
    MixerTrack(
      '✈️',
      'Airplane Cabin',
      'Soothing White Noise Cruise',
      Color(0xFF0288D1),
    ),
    MixerTrack(
      '🚗',
      'Driving Rain Car',
      'Highway Windshield Rain',
      Color(0xFF455A64),
    ),
    MixerTrack(
      '⛵',
      'Boat Deck',
      'Creaking Wooden Hull Waves',
      Color(0xFF0097A7),
    ),
    MixerTrack(
      '🚇',
      'Subway Train',
      'Low Underground Metro',
      Color(0xFF37474F),
    ),
    MixerTrack('🚲', 'Bicycle Ride', 'Gentle Coasting Wind', Color(0xFF689F38)),
    MixerTrack(
      '⛵',
      'Sailing Ship',
      'Rigging Breeze & Swell',
      Color(0xFF00838F),
    ),
    MixerTrack(
      '🛣️',
      'Highway Traffic',
      'Distant Asphalt Roll',
      Color(0xFF607D8B),
    ),
  ]),
  MixerCategory('things', '⚙️', 'Things', [
    MixerTrack(
      '🕰️',
      'Clock Ticking',
      'Steady Rhythmic Pendulum',
      Color(0xFF78909C),
    ),
    MixerTrack('🌀', 'Fan Noise', 'Cooling Air Circulation', Color(0xFF00ACC1)),
    MixerTrack(
      '⌨️',
      'Keyboard Typing',
      'Soft Mechanical Keys',
      Color(0xFF546E7A),
    ),
    MixerTrack(
      '🧺',
      'Washing Machine',
      'Gentle Laundry Rinsing',
      Color(0xFF0288D1),
    ),
    MixerTrack(
      '📻',
      'Vinyl Crackle',
      'Warm Analog Nostalgia',
      Color(0xFF8D6E63),
    ),
    MixerTrack(
      '🫖',
      'Boiling Kettle',
      'Cozy Teatime Whistle',
      Color(0xFFFF7043),
    ),
    MixerTrack(
      '🎋',
      'Bamboo Chimes',
      'Pentatonic Wind Chimes',
      Color(0xFF26C6DA),
    ),
    MixerTrack('📖', 'Page Turning', 'Book Study Leaf', Color(0xFFA1887F)),
    MixerTrack('⏱️', 'Pendulum', 'Hypnotic Second Beat', Color(0xFF455A64)),
    MixerTrack(
      '💨',
      'Wind Generator',
      'Constant Turbine Sweep',
      Color(0xFF90A4AE),
    ),
  ]),
  MixerCategory('noise', '🔊', 'Noise', [
    MixerTrack(
      '⚪',
      'White Noise',
      'Full Spectrum Flat Noise',
      Color(0xFFCFD8DC),
    ),
    MixerTrack(
      '🌸',
      'Pink Noise',
      'Balanced Waterfall Spectrum',
      Color(0xFFF48FB1),
    ),
    MixerTrack(
      '🤎',
      'Brown Noise',
      'Deep Low Frequency Rumble',
      Color(0xFF8D6E63),
    ),
    MixerTrack('🔵', 'Blue Noise', 'High Pitch Crisp Hiss', Color(0xFF64B5F6)),
    MixerTrack('💜', 'Violet Noise', 'Ultra Crisp Shimmer', Color(0xFFBA68C8)),
    MixerTrack(
      '🩶',
      'Grey Noise',
      'Equal Perception Contour',
      Color(0xFF90A4AE),
    ),
  ]),
  MixerCategory('solfeggio', '🔮', 'Solfeggio', [
    MixerTrack(
      '🧘',
      '432Hz Healing',
      'Natural Harmony Tone',
      Color(0xFFAB47BC),
    ),
    MixerTrack(
      '✨',
      '528Hz Transformation',
      'Miracle Healing Frequency',
      Color(0xFF00E676),
    ),
    MixerTrack(
      '💖',
      '639Hz Harmonics',
      'Heart Relationship Harmony',
      Color(0xFFFF4081),
    ),
    MixerTrack(
      '🧠',
      '108Hz Theta Drone',
      'Deep Meditation State',
      Color(0xFF00ACC1),
    ),
    MixerTrack(
      '💤',
      'Delta Deep Sleep',
      'Restful Subconscious Waves',
      Color(0xFF3F51B5),
    ),
    MixerTrack(
      '⚡',
      'Alpha Focus Flow',
      'Peak Concentration Alpha Waves',
      Color(0xFFFFC107),
    ),
    MixerTrack(
      '🔥',
      'Beta Energy Boost',
      'Active Consciousness',
      Color(0xFFFF5722),
    ),
    MixerTrack(
      '🌌',
      'Gamma Insight',
      'High Cognitive Transcendence',
      Color(0xFF9C27B0),
    ),
    MixerTrack(
      '🛡️',
      '174Hz Pain Relief',
      'Physical Comfort Frequency',
      Color(0xFF4CAF50),
    ),
    MixerTrack(
      '🌿',
      '285Hz Cellular',
      'Vitality & Tissue Renewal',
      Color(0xFF8BC34A),
    ),
    MixerTrack(
      '🕊️',
      '396Hz Liberation',
      'Liberating Guilt & Fear',
      Color(0xFF00BCD4),
    ),
    MixerTrack(
      '👁️',
      '741Hz Intuition',
      'Awakening Inner Intuition',
      Color(0xFF7C4DFF),
    ),
    MixerTrack(
      '✡️',
      '852Hz Awakening',
      'Spiritual Order & Light',
      Color(0xFFE040FB),
    ),
    MixerTrack(
      '👑',
      '963Hz Crown State',
      'Divine Unity Consciousness',
      Color(0xFFFFD700),
    ),
  ]),
];

Iterable<MixerTrack> get allMixerTracks =>
    mixerCategories.expand((category) => category.tracks);
