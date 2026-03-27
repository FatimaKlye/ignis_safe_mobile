import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'home.dart';
import 'onboarding1.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mvgpeiejwstrxjmfslke.supabase.co',
    anonKey: 'sb_publishable_rPBCsdTPJUWlslIDbF5f3g_uK-TKqxw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ignis Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const AppStartPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const IgnisHomePage(),
        '/onboarding': (_) => const OnboardingOnePage(),
      },
    );
  }
}

class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _AppStartPageState extends State<AppStartPage> {
  Widget? _targetPage;

  @override
  void initState() {
    super.initState();
    _checkStartPage();
  }

  Future<void> _checkStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;

    setState(() {
      _targetPage =
          onboardingDone ? const LoginPage() : const OnboardingOnePage();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_targetPage == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _targetPage!;
  }
}