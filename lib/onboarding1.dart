import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'onboarding_helper.dart';

class OnboardingOnePage extends StatelessWidget {
  const OnboardingOnePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingFlow(initialPage: 0);
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.initialPage = 0})
    : assert(initialPage >= 0 && initialPage < _itemsCount);

  final int initialPage;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final PageController _pageController;
  late double _currentPage;
  late int _currentIndex;

  static const Color _brandRed = Color(0xFFB11217);
  static const Color _warmSurface = Color(0xFFFFF8F5);
  static const Color _ink = Color(0xFF171923);
  static const Color _body = Color(0xFF344054);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    _currentPage = widget.initialPage.toDouble();
    _pageController = PageController(initialPage: widget.initialPage)
      ..addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients) return;

    setState(() {
      _currentPage = _pageController.page ?? _currentIndex.toDouble();
    });
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_handlePageScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_currentIndex == _items.length - 1) {
      await OnboardingHelper.finishOnboarding(context);
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmSurface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 20.0 : 28.0;
            final footerGap = constraints.maxHeight < 680 ? 14.0 : 22.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                12,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                          _currentPage = index.toDouble();
                        });
                      },
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return _OnboardingSlide(
                          item: _items[index],
                          index: index,
                          currentPage: _currentPage,
                          brandRed: _brandRed,
                          ink: _ink,
                          body: _body,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: footerGap),
                  _PaginationIndicator(
                    currentPage: _currentPage,
                    count: _items.length,
                    activeColor: _brandRed,
                  ),
                  SizedBox(height: footerGap),
                  _FooterActions(
                    isLastPage: _currentIndex == _items.length - 1,
                    onSkip: () => OnboardingHelper.skipOnboarding(context),
                    onNext: _goNext,
                    brandRed: _brandRed,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.item,
    required this.index,
    required this.currentPage,
    required this.brandRed,
    required this.ink,
    required this.body,
  });

  final _OnboardingItem item;
  final int index;
  final double currentPage;
  final Color brandRed;
  final Color ink;
  final Color body;

  @override
  Widget build(BuildContext context) {
    final signedDistance = (currentPage - index).clamp(-1.0, 1.0);
    final distance = signedDistance.abs();

    return Opacity(
      opacity: 1 - (distance * 0.18),
      child: Transform.translate(
        offset: Offset(signedDistance * 18, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 560;
            final stageHeight = math.min(
              constraints.maxHeight * (isShort ? 0.46 : 0.5),
              constraints.maxWidth * 0.86,
            );
            final topGap = constraints.maxHeight < 600 ? 10.0 : 22.0;
            final contentGap = constraints.maxHeight < 600 ? 16.0 : 24.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: topGap),
                    _IllustrationStage(
                      asset: item.asset,
                      semanticLabel: '${item.label} fire safety illustration',
                      height: stageHeight,
                      brandRed: brandRed,
                    ),
                    SizedBox(height: contentGap),
                    _SectionLabel(label: item.label, brandRed: brandRed),
                    const SizedBox(height: 12),
                    Text(
                      item.heading,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: constraints.maxWidth < 350 ? 27 : 29,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.min(constraints.maxWidth * 0.9, 340),
                      ),
                      child: Text(
                        item.body,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: constraints.maxWidth < 350 ? 15 : 16,
                          fontWeight: FontWeight.w500,
                          color: body,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: topGap),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IllustrationStage extends StatelessWidget {
  const _IllustrationStage({
    required this.asset,
    required this.semanticLabel,
    required this.height,
    required this.brandRed,
  });

  final String asset;
  final String semanticLabel;
  final double height;
  final Color brandRed;

  @override
  Widget build(BuildContext context) {
    final stageHeight = height.clamp(190.0, 330.0);

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        height: stageHeight,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: EdgeInsets.all(stageHeight * 0.08),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: brandRed.withValues(alpha: 0.12),
              blurRadius: 34,
              offset: const Offset(0, 22),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: RadialGradient(
              center: const Alignment(-0.15, -0.22),
              radius: 0.9,
              colors: [
                brandRed.withValues(alpha: 0.18),
                const Color(0xFFFFE8E1),
                const Color(0xFFFFFBF8),
              ],
              stops: const [0, 0.54, 1],
            ),
          ),
          child: Center(
            child: Image.asset(
              asset,
              height: stageHeight * 0.74,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.brandRed});

  final String label;
  final Color brandRed;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: brandRed,
        height: 1,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _PaginationIndicator extends StatelessWidget {
  const _PaginationIndicator({
    required this.currentPage,
    required this.count,
    required this.activeColor,
  });

  final double currentPage;
  final int count;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Onboarding page ${currentPage.round() + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final proximity = (1 - (currentPage - index).abs()).clamp(0.0, 1.0);
          final width = 8 + (22 * proximity);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: width,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFFE5E7EB),
                activeColor,
                proximity,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
    required this.brandRed,
  });

  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final Color brandRed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF667085),
              minimumSize: const Size(64, 48),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          _PressableActionButton(
            key: ValueKey(isLastPage),
            label: isLastPage ? 'Get Started' : 'Next',
            width: isLastPage ? 150 : 104,
            onPressed: onNext,
            backgroundColor: brandRed,
          ),
        ],
      ),
    );
  }
}

class _PressableActionButton extends StatefulWidget {
  const _PressableActionButton({
    super.key,
    required this.label,
    required this.width,
    required this.onPressed,
    required this.backgroundColor,
  });

  final String label;
  final double width;
  final VoidCallback onPressed;
  final Color backgroundColor;

  @override
  State<_PressableActionButton> createState() => _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) return;

    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: widget.width,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: widget.backgroundColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: widget.backgroundColor.withValues(alpha: 0.22),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.white.withValues(alpha: 0.14);
                    }
                    if (states.contains(WidgetState.focused) ||
                        states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.08);
                    }

                    return null;
                  }),
                ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.label,
    required this.heading,
    required this.body,
    required this.asset,
  });

  final String label;
  final String heading;
  final String body;
  final String asset;
}

const int _itemsCount = 3;

const List<_OnboardingItem> _items = [
  _OnboardingItem(
    label: 'Learn',
    heading: 'Safety Starts with Awareness',
    body:
        'Learn essential fire safety skills to protect yourself and the people around you.',
    asset: 'assets/fire_onboard1.png',
  ),
  _OnboardingItem(
    label: 'Prepare',
    heading: 'Be Ready. Stay Safe.',
    body:
        'Learn how to respond confidently before, during, and after a fire emergency.',
    asset: 'assets/onboard2.png',
  ),
  _OnboardingItem(
    label: 'Simulate',
    heading: "Train Like It's Real",
    body:
        'Practice your response through realistic, interactive fire simulations.',
    asset: 'assets/onboard3.png',
  ),
];
