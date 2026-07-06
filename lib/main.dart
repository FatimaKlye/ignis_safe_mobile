import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'home.dart';
import 'onboarding1.dart';
import 'localization/language_controller.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
    return ChangeNotifierProvider(
      create: (_) => LanguageController(),
      child: Consumer<LanguageController>(
        builder: (context, languageController, _) {
          return MaterialApp(
            title: 'Ignis Safe',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Poppins',
              useMaterial3: true,
            ),
            locale: languageController.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('tl'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppStartPage(),
            routes: {
              '/login': (_) => const LoginPage(),
              '/home': (_) => const IgnisHomePage(),
              '/onboarding': (_) => const OnboardingOnePage(),
            },
          );
        },
      ),
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
    final results = await Future.wait([
      _resolveTargetPage(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    final targetPage = results[0] as Widget;

    if (!mounted) return;

    setState(() {
      _targetPage = targetPage;
    });

    FlutterNativeSplash.remove();
  }

  Future<Widget> _resolveTargetPage() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (!onboardingDone) {
      return const OnboardingOnePage();
    } else if (session != null) {
      return const IgnisHomePage();
    } else {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Android native splash screen (preserved in main()) stays on
    // screen until FlutterNativeSplash.remove() is called above, so
    // nothing extra needs to be rendered here while we wait.
    return _targetPage ?? const SizedBox.shrink();
  }
}