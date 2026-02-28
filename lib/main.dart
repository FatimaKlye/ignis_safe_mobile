import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'signup.dart';
import 'home.dart'; // <-- contains IgnisHomePage (navbar shell)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mvgpeiejwstrxjmfslke.supabase.co',
    anonKey: 'sb_publishable_rPBCsdTPJUWlslIDbF5f3g_uK-TKqxw',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // Rebuild app when auth changes (login/logout)
    _authSub = supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return MaterialApp(
      title: 'Ignis Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),

      // IMPORTANT: Let home decide what to show.
      home: session == null ? const LoginPage() : const IgnisHomePage(),

      // Keep routes for explicit navigation if you want them.
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const RegisterPage(),
        '/home': (_) => const IgnisHomePage(),
      },
    );
  }
}