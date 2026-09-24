import 'package:flutter/material.dart';

/// Shared action row for the pre/post-assessment submission confirmation
/// modals: an outlined "Review" button on the left and a solid "Submit"
/// button on the right, equal in width and height.
class AssessmentConfirmActions extends StatelessWidget {
  const AssessmentConfirmActions({
    super.key,
    required this.reviewText,
    required this.submitText,
    required this.onReview,
    required this.onSubmit,
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  final String reviewText;
  final String submitText;
  final VoidCallback onReview;
  final VoidCallback onSubmit;

  /// Module accent color used for the outline and the solid fill.
  final Color primaryColor;

  /// Text color on top of [primaryColor].
  final Color onPrimaryColor;

  static const double _height = 50;
  static const double _gap = 12;
  static const double _radius = 14;

  Widget _label(String text, Color color) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _height,
            child: OutlinedButton(
              onPressed: onReview,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 1.3),
                shape: shape,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: _label(reviewText, primaryColor),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: SizedBox(
            height: _height,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.35),
                shape: shape,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: _label(submitText, onPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
