import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

const Color brandRed = Color(0xFFB11217);

class FloatingNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  /// Exactly 3 outlined/inactive icons.
  final List<IconData> icons;

  /// Exactly 3 filled/active icons when provided.
  final List<IconData>? activeIcons;

  /// Hidden visually. Used only for accessibility.
  final List<String> labels;

  final Color? activeColor;
  final Color? inactiveColor;
  final Color? navBarColor;
  final Color? borderColor;

  final double navBarHeight;
  final double horizontalMargin;
  final double bottomPadding;
  final double blurSigma;

  /// Keeps the active icon locked to the brand red even if old home.dart
  /// still passes activeColor: Colors.black.
  final bool forceBrandActiveColor;

  /// Kept only so old calls do not break.
  final double fabSize;
  final double dipWidth;
  final double dipDepth;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
    this.activeIcons,
    this.labels = const ['Module', 'About', 'Profile'],
    this.activeColor,
    this.inactiveColor,
    this.navBarColor,
    this.borderColor,
    this.navBarHeight = 62.0,
    this.horizontalMargin = 28.0,
    this.bottomPadding = 14.0,
    this.blurSigma = 22.0,
    this.forceBrandActiveColor = true,
    this.fabSize = 0.0,
    this.dipWidth = 0.0,
    this.dipDepth = 0.0,
  })  : assert(icons.length == 3, 'FloatingNavBar must have exactly 3 icons.'),
        assert(
          activeIcons == null || activeIcons.length == 3,
          'activeIcons must have exactly 3 icons.',
        ),
        assert(labels.length == 3, 'FloatingNavBar must have exactly 3 labels.');

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  int? _pressedIndex;

  void _setPressedIndex(int? index) {
    if (_pressedIndex == index) return;

    setState(() {
      _pressedIndex = index;
    });
  }

  int _safeIndex(int index) {
    return index.clamp(0, 2).toInt();
  }

  double _responsiveHorizontalMargin(double width) {
    final double maxSafeMargin = math.max(0.0, (width - 240.0) / 2);
    final double responsiveMargin =
        (width * 0.065).clamp(14.0, 30.0).toDouble();

    return math
        .min(widget.horizontalMargin, math.min(responsiveMargin, maxSafeMargin))
        .clamp(0.0, 40.0)
        .toDouble();
  }

  double _responsiveHeight(double width) {
    final double responsiveHeight =
        (width * 0.18).clamp(54.0, 64.0).toDouble();

    return math
        .min(widget.navBarHeight, responsiveHeight)
        .clamp(52.0, 68.0)
        .toDouble();
  }

  double _responsiveIconSize({
    required double barWidth,
    required double barHeight,
  }) {
    final double slotWidth = barWidth / 3;

    final double heightBased =
        (barHeight * 0.43).clamp(23.0, 28.0).toDouble();
    final double widthBased = (slotWidth * 0.30).clamp(22.0, 28.0).toDouble();

    return math.min(heightBased, widthBased);
  }

  Size _responsiveIndicatorSize({
    required double slotWidth,
    required double barHeight,
    required double iconSize,
  }) {
    final double maxPillWidth = math.max(0.0, slotWidth - 8.0);
    final double maxPillHeight = math.max(0.0, barHeight - 10.0);

    final double preferredPillWidth =
        math.min(math.max(iconSize * 2.65, 48.0), 78.0);
    final double preferredPillHeight =
        math.min(math.max(iconSize * 1.95, 42.0), 54.0);

    return Size(
      math.min(preferredPillWidth, maxPillWidth),
      math.min(preferredPillHeight, maxPillHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color activeIconColor =
        widget.forceBrandActiveColor ? brandRed : (widget.activeColor ?? brandRed);

    final Color inactiveIconColor = widget.inactiveColor ??
        (isDark
            ? Colors.white.withOpacity(0.46)
            : Colors.black.withOpacity(0.42));

    final Color glassColor = widget.navBarColor ??
        (isDark
            ? Colors.black.withOpacity(0.34)
            : Colors.white.withOpacity(0.68));

    final Color effectiveBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withOpacity(0.18)
            : Colors.black.withOpacity(0.10));

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final double sideMargin = _responsiveHorizontalMargin(screenWidth);
        final double barHeight = _responsiveHeight(screenWidth);
        final double bottomGap = widget.bottomPadding.clamp(10.0, 18.0).toDouble();
        final double radius = barHeight / 2;

        return SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: bottomGap),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sideMargin),
            child: SizedBox(
              height: barHeight,
              child: LayoutBuilder(
                builder: (context, barConstraints) {
                  final double barWidth = barConstraints.maxWidth.isFinite
                      ? barConstraints.maxWidth
                      : math.max(0.0, screenWidth - (sideMargin * 2));

                  final double slotWidth = barWidth / 3;
                  final double iconSize = _responsiveIconSize(
                    barWidth: barWidth,
                    barHeight: barHeight,
                  );

                  final int safeSelectedIndex = _safeIndex(widget.selectedIndex);

                  final Size indicatorSize = _responsiveIndicatorSize(
                    slotWidth: slotWidth,
                    barHeight: barHeight,
                    iconSize: iconSize,
                  );

                  final double indicatorLeft =
                      (safeSelectedIndex * slotWidth) +
                      ((slotWidth - indicatorSize.width) / 2);

                  final double indicatorTop =
                      (barHeight - indicatorSize.height) / 2;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.28 : 0.14),
                          blurRadius: 28,
                          spreadRadius: -8,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: widget.blurSigma,
                          sigmaY: widget.blurSigma,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: glassColor,
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(
                              color: effectiveBorderColor,
                              width: 0.7,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                left: indicatorLeft,
                                top: indicatorTop,
                                width: indicatorSize.width,
                                height: indicatorSize.height,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color: brandRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(
                                      indicatorSize.height / 2,
                                    ),
                                    border: Border.all(
                                      color: brandRed.withOpacity(0.10),
                                      width: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Row(
                                  children: List.generate(3, (index) {
                                    final bool isActive =
                                        index == safeSelectedIndex;
                                    final bool isPressed =
                                        index == _pressedIndex;

                                    return _GlassInstagramNavItem(
                                      label: widget.labels[index],
                                      icon: widget.icons[index],
                                      activeIcon: widget.activeIcons?[index] ??
                                          widget.icons[index],
                                      isActive: isActive,
                                      isPressed: isPressed,
                                      iconSize: iconSize,
                                      activeColor: activeIconColor,
                                      inactiveColor: inactiveIconColor,
                                      onTapDown: () => _setPressedIndex(index),
                                      onTapCancel: () => _setPressedIndex(null),
                                      onTapUp: () {
                                        Future<void>.delayed(
                                          const Duration(milliseconds: 70),
                                          () {
                                            if (!mounted) return;
                                            _setPressedIndex(null);
                                          },
                                        );
                                      },
                                      onTap: () => widget.onItemTapped(index),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassInstagramNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final bool isPressed;
  final double iconSize;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;
  final VoidCallback onTapUp;
  final VoidCallback onTap;

  const _GlassInstagramNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.isPressed,
    required this.iconSize,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTapUp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive ? activeColor : inactiveColor;
    final double scale = isPressed ? 0.88 : (isActive ? 1.06 : 1.0);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onTapDown(),
          onTapCancel: onTapCancel,
          onTapUp: (_) => onTapUp(),
          onTap: onTap,
          child: Center(
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 95),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey('$label-$isActive'),
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}