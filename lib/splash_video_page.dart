import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import 'login.dart';
import 'home.dart';
import 'onboarding1.dart';

/// Plays the MP4 splash animation once, then navigates to whichever
/// screen the existing app flow (onboarding / auth session) resolves to.
class SplashVideoPage extends StatefulWidget {
  const SplashVideoPage({super.key});

  @override
  State<SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage> {
  static const String _videoAssetPath = 'assets/videos/splash_screen.mp4';

  VideoPlayerController? _controller;
  Future<Widget>? _targetPageFuture;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _targetPageFuture = _resolveTargetPage();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_videoAssetPath);
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.setLooping(false);
      controller.addListener(_onVideoTick);
      setState(() {
        _controller = controller;
      });
      FlutterNativeSplash.remove();
      await controller.play();
    } catch (_) {
      controller.dispose();
      FlutterNativeSplash.remove();
      _goToTargetPage();
    }
  }

  void _onVideoTick() {
    if (!mounted) return;
    final value = _controller?.value;
    if (value == null) return;

    if (value.hasError) {
      _goToTargetPage();
      return;
    }

    final isFinished = value.isInitialized &&
        !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration;

    if (isFinished) {
      _goToTargetPage();
    }
  }

  Future<Widget> _resolveTargetPage() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (!onboardingDone) {
      return const OnboardingOnePage();
    } else if (session != null) {
      final active = await _isAccountActive(session.user.id);
      if (!active) {
        await Supabase.instance.client.auth.signOut();
        return const LoginPage();
      }
      return const IgnisHomePage();
    } else {
      return const LoginPage();
    }
  }

  Future<bool> _isAccountActive(String userId) async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('is_active')
          .eq('id', userId)
          .maybeSingle();

      return (row?['is_active'] ?? true) != false;
    } catch (_) {
      return true;
    }
  }

  Future<void> _goToTargetPage() async {
    if (_navigated) return;
    _navigated = true;

    final targetPage = await _targetPageFuture!;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetPage),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isReady
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
