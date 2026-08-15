import 'package:flutter/material.dart';

/// The pair of pill-shaped actions shown at the bottom of every
/// Pre-Assessment / Post-Assessment screen (question nav, summary review,
/// and locked/completed states).
///
/// Both buttons scale their label + icon as a single unit via [FittedBox]
/// instead of truncating with an ellipsis, so long labels (e.g. "Review
/// Summary" / "Suriin") always stay fully visible on narrow phone screens.
/// Padding is kept tight so most screens render at natural size and only
/// the smallest screens trigger the automatic shrink.
class AssessmentPrimaryButton extends StatelessWidget {
  const AssessmentPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.disabledBackgroundColor,
    this.icon,
    this.textColor = Colors.white,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color disabledBackgroundColor;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          elevation: onPressed == null ? 0 : 7,
          shadowColor: backgroundColor.withOpacity(0.32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 7),
                Icon(icon, color: textColor, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AssessmentSecondaryButton extends StatelessWidget {
  const AssessmentSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.accentColor,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color accentColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: accentColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: accentColor,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
