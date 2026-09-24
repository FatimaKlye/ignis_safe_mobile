import 'package:flutter/material.dart';

/// Circular top-left X button matching the assessment screens' close button
/// (40x40 circle, 1px translucent border, 21px rounded close icon), placed at
/// the same offset (18px from the left, 8px from the top of the safe area).
///
/// The assessment version is white on a red backdrop; here [color] tints the
/// fill, border and icon so it stays visible on light screens. Must be used
/// as a direct child of a [Stack].
class TopCloseButtonOverlay extends StatelessWidget {
  const TopCloseButtonOverlay({
    super.key,
    required this.onTap,
    this.color = const Color(0xFFB71C1C),
  });

  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 18,
      top: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Icon(Icons.close_rounded, color: color, size: 21),
        ),
      ),
    );
  }
}
