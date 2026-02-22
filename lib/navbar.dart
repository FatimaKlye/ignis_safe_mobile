import 'package:flutter/material.dart';

/// ModernFloatingNavBar — sleek floating navigation bar with concave dip
///
/// Usage:
/// ModernFloatingNavBar(
///   selectedIndex: _currentIndex,
///   onItemTapped: (i) => setState(() => _currentIndex = i),
///   icons: [Icons.menu_book_rounded, Icons.view_in_ar_rounded,
///           Icons.info_outline_rounded, Icons.person_outline_rounded],
/// )
class FloatingNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<IconData> icons;

  // Customization
  final Color activeColor;
  final Color inactiveColor;
  final Color navBarColor;
  final double navBarHeight;
  final double fabSize;
  final double dipWidth;
  final double dipDepth;
  final double horizontalMargin;
  final double bottomPadding;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
    this.activeColor = const Color(0xFFB11217),
    this.inactiveColor = const Color(0xFF9E9E9E),
    this.navBarColor = Colors.white,
    this.navBarHeight = 64.0,
    this.fabSize = 56.0,
    this.dipWidth = 80.0,
    this.dipDepth = 22.0,
    this.horizontalMargin = 20.0,
    this.bottomPadding = 20.0,
  });

  @override
  State<FloatingNavBar> createState() => _ModernFloatingNavBarState();
}

class _ModernFloatingNavBarState extends State<FloatingNavBar>
    with TickerProviderStateMixin {
  late AnimationController _posCtrl;
  late Animation<double> _posAnim;
  double _fromX = -1;
  double _toX = -1;

  late AnimationController _iconCtrl;
  late Animation<double> _iconFade;
  int _displayedIndex = 0;
  int _nextIndex = 0;

  double _barWidth = 0;

  @override
  void initState() {
    super.initState();
    _displayedIndex = widget.selectedIndex;
    _nextIndex = widget.selectedIndex;

    _posCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _posAnim = const AlwaysStoppedAnimation(1.0);

    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _iconFade = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(FloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && _barWidth > 0) {
      _animateTo(
        from: _slotCentreX(old.selectedIndex),
        to: _slotCentreX(widget.selectedIndex),
      );
      _crossFadeIcon(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _posCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  double _slotCentreX(int index) {
    final slotW = _barWidth / widget.icons.length;
    return slotW * index + slotW / 2;
  }

  double _lerpX() {
    if (_fromX < 0) return _barWidth > 0 ? _slotCentreX(widget.selectedIndex) : 0;
    return _fromX + (_toX - _fromX) * _posAnim.value;
  }

  void _animateTo({required double from, required double to}) {
    _fromX = _lerpX();
    _toX = to;

    final pct = ((_toX - _fromX).abs() / _barWidth).clamp(0.0, 1.0);
    final ms = (180 + (pct * 120)).round();

    _posCtrl.duration = Duration(milliseconds: ms);
    _posAnim = CurvedAnimation(parent: _posCtrl, curve: Curves.easeOutCubic);
    _posCtrl
      ..reset()
      ..forward();
  }

  void _crossFadeIcon(int newIndex) {
    _nextIndex = newIndex;

    _iconFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeIn),
    );

    _iconCtrl
      ..reset()
      ..forward().then((_) {
        if (!mounted) return;
        setState(() => _displayedIndex = _nextIndex);

        _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut),
        );
        _iconCtrl
          ..reset()
          ..forward();
      });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;

              if (_barWidth != barW) {
                _barWidth = barW;
                _fromX = _slotCentreX(widget.selectedIndex);
                _toX = _fromX;
              }

              final totalH = widget.navBarHeight + widget.dipDepth + widget.fabSize / 2;

              return SizedBox(
                height: totalH,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_posCtrl, _iconCtrl]),
                  builder: (context, _) {
                    final animX = _lerpX();

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background pill with dip
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: widget.navBarHeight + widget.dipDepth,
                          child: CustomPaint(
                            painter: _NavBarPainter(
                              activeX: animX,
                              navHeight: widget.navBarHeight,
                              dipWidth: widget.dipWidth,
                              dipDepth: widget.dipDepth,
                              color: widget.navBarColor,
                            ),
                          ),
                        ),

                        // Navigation items
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: widget.navBarHeight,
                          child: Row(
                            children: List.generate(
                              widget.icons.length,
                              (i) => _NavItem(
                                icon: widget.icons[i],
                                label: _getLabel(i),
                                fabX: animX,
                                slotCentreX: _slotCentreX(i),
                                dipWidth: widget.dipWidth,
                                inactiveColor: widget.inactiveColor,
                                onTap: () => widget.onItemTapped(i),
                              ),
                            ),
                          ),
                        ),

                        // Floating action dot
                        Positioned(
                          bottom: widget.navBarHeight - widget.fabSize / 2,
                          left: animX - widget.fabSize / 2,
                          child: FadeTransition(
                            opacity: _iconFade,
                            child: _FloatingDot(
                              size: widget.fabSize,
                              icon: widget.icons[_displayedIndex],
                              color: widget.activeColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getLabel(int index) {
    const labels = ['Learn', 'Simulation', 'About', 'Profile'];
    return index < labels.length ? labels[index] : '';
  }
}

/// Painter for pill background with dip
class _NavBarPainter extends CustomPainter {
  final double activeX;
  final double navHeight;
  final double dipWidth;
  final double dipDepth;
  final Color color;

  const _NavBarPainter({
    required this.activeX,
    required this.navHeight,
    required this.dipWidth,
    required this.dipDepth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 12, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  Path _buildPath(Size size) {
    final W = size.width;
    final top = dipDepth;
    final bot = size.height;
    const r = 32.0;
    final cp = dipWidth * 0.3;

    final ax = activeX.clamp(dipWidth / 2 + r, W - dipWidth / 2 - r);
    final L = ax - dipWidth / 2;
    final R = ax + dipWidth / 2;

      return Path()
        ..moveTo(r, top)
        ..lineTo(L, top)
        ..cubicTo(L + cp, top, ax - cp, top + dipDepth, ax, top + dipDepth)
        ..cubicTo(ax + cp, top + dipDepth, R - cp, top, R, top)
        ..lineTo(W - r, top)
        ..quadraticBezierTo(W, top, W, top + r)       // ✅ fixed parenthesis
        ..lineTo(W, bot - r)
        ..quadraticBezierTo(W, bot, W - r, bot)       // ↘
        ..lineTo(r, bot)
        ..quadraticBezierTo(0, bot, 0, bot - r)       // ↙
        ..lineTo(0, top + r)
        ..quadraticBezierTo(0, top, r, top)           // ↖
        ..close();

  }

  @override
  bool shouldRepaint(_NavBarPainter old) =>
      old.activeX != activeX || old.color != color;
}

/// Floating dot with gradient + shadow
class _FloatingDot extends StatelessWidget {
  final double size;
  final IconData icon;
  final Color color;

  const _FloatingDot({
    required this.size,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.05)!,
            color,
            Color.lerp(color, Colors.black, 0.15)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.42,
        shadows: const [
          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

/// One tappable nav item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fabX;
  final double slotCentreX;
  final double dipWidth;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.fabX,
    required this.slotCentreX,
    required this.dipWidth,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dist = (fabX - slotCentreX).abs();
    final fadeZone = dipWidth * 0.55;
    final t = (dist / fadeZone).clamp(0.0, 1.0);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: t > 0.15 ? onTap : null,
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24, color: inactiveColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: inactiveColor,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
