import 'package:flutter/material.dart';

import '../localization/language_controller.dart';

/// IGNIS SAFE brand red — the default accent, used by Module 1 whose theme
/// is the brand red itself. Other modules pass their own theme colors.
const Color kIgnisSafeRed = Color(0xFFB11217);
const Color kIgnisSafeRedPressed = Color(0xFF7A1014);
const Color kIgnisSafeRedShadow = Color(0x4DB11217);

/// The two side-by-side actions shown at the bottom of a Pre-Assessment
/// Score Result screen: a secondary "Answer Feedback" button and a primary
/// "Continue" button. Kept as a single shared widget so all module Score
/// Result screens stay structurally consistent while each module supplies
/// its own accent color from its existing `AppColors` palette.
class ScoreResultActionButtons extends StatelessWidget {
  const ScoreResultActionButtons({
    super.key,
    required this.onAnswerFeedback,
    required this.onContinue,
    this.accentColor = kIgnisSafeRed,
    this.accentPressedColor = kIgnisSafeRedPressed,
    this.accentShadowColor = kIgnisSafeRedShadow,
  });

  final VoidCallback onAnswerFeedback;
  final VoidCallback onContinue;

  /// Module theme color: border/icon/text of "Answer Feedback" and the solid
  /// background of "Continue".
  final Color accentColor;

  /// Pressed-state background of "Continue".
  final Color accentPressedColor;

  /// Drop shadow beneath "Continue" — the accent color at low opacity.
  final Color accentShadowColor;

  @override
  Widget build(BuildContext context) {
    const double height = 56;

    return Row(
      // Each button already gets its height from the SizedBox below.
      // CrossAxisAlignment.stretch would force a tight infinite-height
      // constraint here, because this Row is laid out inside a scrollable
      // Column with an unbounded vertical constraint.
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              style: ButtonStyle(
                backgroundColor: const WidgetStatePropertyAll<Color>(
                  Colors.white,
                ),
                side: WidgetStatePropertyAll<BorderSide>(
                  BorderSide(color: accentColor, width: 1.6),
                ),
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                shape: WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              onPressed: onAnswerFeedback,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    color: accentColor,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      t(context, 'Answer Feedback', 'Paliwanag sa Sagot'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: height,
            child: ElevatedButton(
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.pressed)) {
                      return accentPressedColor;
                    }
                    return accentColor;
                  },
                ),
                foregroundColor: const WidgetStatePropertyAll<Color>(
                  Colors.white,
                ),
                elevation: const WidgetStatePropertyAll<double>(8),
                shadowColor: WidgetStatePropertyAll<Color>(
                  accentShadowColor,
                ),
                shape: WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              onPressed: onContinue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      t(context, 'Continue', 'Magpatuloy'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
