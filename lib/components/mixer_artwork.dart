import 'package:flutter/widgets.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';

/// Local decorative covers with a font-independent recovery state.
class MixerArtwork extends StatelessWidget {
  const MixerArtwork({required this.track, super.key});
  final MixerTrack track;

  @override
  Widget build(BuildContext context) => Image.asset(
    track.coverAsset,
    key: ValueKey('cover-${track.name}'),
    fit: BoxFit.cover,
    excludeFromSemantics: true,
    errorBuilder: (_, error, stack) => const ColoredBox(
      color: Color(0xFF104349),
      child: Center(
        child: SanctuaryIcon(
          SanctuarySymbol.sounds,
          size: 30,
          color: Color(0xFF9AEBD7),
        ),
      ),
    ),
  );
}
