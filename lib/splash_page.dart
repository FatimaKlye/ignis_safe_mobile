import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home.dart';
import 'login.dart';
import 'onboarding1.dart';

/// A short, lightweight brand reveal shown between the native launch screen
/// and the app's onboarding/auth flow.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Color _brandRed = Color(0xFFB11217);
  static const Color _brandGold = Color(0xFFF2A93B);
  static const Color _brandNavy = Color(0xFF142D57);

  late final AnimationController _controller;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _copyOpacity;
  late final Animation<double> _copyLift;
  late final Future<Widget> _targetPageFuture;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _targetPageFuture = _resolveTargetPage();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1850),
    );

    _backgroundOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.06, 0.42, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.83, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    // The hidden copy below the logo shifts the column's visual center upward.
    // This offset keeps the first Flutter frame aligned with Android's native
    // centered logo, then moves that same logo into its final branded layout.
    _logoLift = Tween<double>(begin: 54, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _copyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.72, curve: Curves.easeOut),
    );
    _copyLift = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.76, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _playSplash();
    });
  }

  Future<void> _playSplash() async {
    await _controller.forward();
    await _goToTargetPage();
  }

  Future<Widget> _resolveTargetPage() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (!onboardingDone) return const OnboardingOnePage();
    if (session != null) return const IgnisHomePage();
    return const LoginPage();
  }

  Future<void> _goToTargetPage() async {
    if (_navigated) return;

    final targetPage = await _targetPageFuture;
    if (!mounted || _navigated) return;
    _navigated = true;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.992, end: 1).animate(fade),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFFBF9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF9),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            FadeTransition(
              opacity: _backgroundOpacity,
              child: const _SplashBackground(),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 620;
                  final emblemSize = compact ? 206.0 : 242.0;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Transform.translate(
                        offset: Offset(0, compact ? -4 : -14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _logoLift.value),
                                  child: Transform.scale(
                                    scale: _logoScale.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: SizedBox.square(
                                dimension: emblemSize,
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: _OrbitPainter(
                                        progress: _controller.value,
                                        red: _brandRed,
                                        gold: _brandGold,
                                        navy: _brandNavy,
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: Center(
                                    child: Container(
                                      width: emblemSize * 0.72,
                                      height: emblemSize * 0.72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandRed.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 34,
                                            spreadRadius: 3,
                                          ),
                                          BoxShadow(
                                            color: _brandGold.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'assets/logo.png',
                                        width: emblemSize * 0.55,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 18 : 24),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _copyOpacity.value,
                                  child: Transform.translate(
                                    offset: Offset(0, _copyLift.value),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  const Text(
                                    'IGNIS SAFE',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _brandNavy,
                                      fontFamily: 'Poppins',
                                      fontSize: 27,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 4.2,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _TaglineDot(color: _brandRed),
                                      SizedBox(width: 9),
                                      Text(
                                        'LEARN  •  PREPARE  •  PROTECT',
                                        style: TextStyle(
                                          color: _brandNavy,
                                          fontFamily: 'Poppins',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      SizedBox(width: 9),
                                      _TaglineDot(color: _brandGold),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  _LoadingAccent(animation: _controller),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF7F3), Color(0xFFF5F8FD)],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -110,
            right: -85,
            child: _AmbientCircle(size: 255, color: Color(0x16B11217)),
          ),
          Positioned(
            bottom: -125,
            left: -95,
            child: _AmbientCircle(size: 280, color: Color(0x12142D57)),
          ),
          Positioned(
            top: 110,
            left: -50,
            child: _AmbientCircle(size: 115, color: Color(0x12F2A93B)),
          ),
        ],
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _TaglineDot extends StatelessWidget {
  const _TaglineDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LoadingAccent extends StatelessWidget {
  const _LoadingAccent({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0x14142D57),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final progress = Curves.easeInOutCubic.transform(
            ((animation.value - 0.56) / 0.44).clamp(0.0, 1.0),
          );
          return FractionallySizedBox(widthFactor: progress, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB11217), Color(0xFFF2A93B)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.progress,
    required this.red,
    required this.gold,
    required this.navy,
  });

  final double progress;
  final Color red;
  final Color gold;
  final Color navy;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reveal = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final rotation = progress * math.pi * 0.16;

    void drawOrbit({
      required double radius,
      required double start,
      required double sweep,
      required Color color,
      required double width,
    }) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.72 * reveal)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start + rotation, sweep * reveal, false, paint);
    }

    drawOrbit(
      radius: size.width * 0.455,
      start: -math.pi * 0.82,
      sweep: math.pi * 0.50,
      color: red,
      width: 3.2,
    );
    drawOrbit(
      radius: size.width * 0.455,
      start: math.pi * 0.18,
      sweep: math.pi * 0.34,
      color: gold,
      width: 3.2,
    );
    drawOrbit(
      radius: size.width * 0.405,
      start: -math.pi * 0.02,
      sweep: math.pi * 0.27,
      color: navy,
      width: 2.0,
    );

    final dotPaint = Paint()..color = gold.withValues(alpha: 0.88 * reveal);
    final angle = -math.pi * 0.82 + rotation;
    canvas.drawCircle(
      center + Offset(math.cos(angle), math.sin(angle)) * (size.width * 0.455),
      4.2 * reveal,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
