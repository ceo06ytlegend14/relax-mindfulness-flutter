import 'package:flutter/widgets.dart';
import 'package:relax_mindfulness/screens/sounds_screen.dart';

/// The moonlit sound mixer is the new landing experience. The original
/// breathing, backup and progress tools remain in the wellbeing dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const SoundsScreen();
}
