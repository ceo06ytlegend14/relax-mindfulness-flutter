import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relax_mindfulness/theme/app_theme.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

class ReviewPromptDialog extends StatefulWidget {
  const ReviewPromptDialog({super.key});

  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasReviewed = prefs.getBool('has_reviewed_app') ?? false;
    final lastPromptMs = prefs.getInt('last_review_prompt_ms') ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Show prompt at most once every 7 days if not reviewed yet
    if (!hasReviewed && (nowMs - lastPromptMs > 7 * 24 * 60 * 60 * 1000)) {
      await prefs.setInt('last_review_prompt_ms', nowMs);
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const ReviewPromptDialog(),
        );
      }
    }
  }

  @override
  State<ReviewPromptDialog> createState() => _ReviewPromptDialogState();
}

class _ReviewPromptDialogState extends State<ReviewPromptDialog> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MixerTheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MixerTheme.control,
                  ),
                  child: const Center(
                    child: Text('⭐', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loving Sanctuary?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your 5-star review helps more people find peace, calm, and better sleep.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Interactive 5-Star Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starNum),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedScale(
                          scale: _rating >= starNum ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            _rating >= starNum
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _rating >= starNum
                                ? const Color(0xFFFFD700)
                                : Colors.white24,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // CTA Button
                GestureDetector(
                  onTap: _handleReview,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MixerTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _rating >= 4 ? 'Rate on Store ⭐' : 'Submit Feedback 🌿',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Dismiss Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_reviewed_app', true);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (_rating >= 4) {
      final inAppReview = InAppReview.instance;
      try {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        } else {
          await inAppReview.openStoreListing();
        }
      } catch (e) {
        debugPrint('Error triggering review: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback! We will keep improving Sanctuary. 🌿'),
          backgroundColor: tealPrimary.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
