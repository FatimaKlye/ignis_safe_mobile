import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
import 'signup.dart';
import 'home.dart';

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

      // IMPORTANT:
      // Always start on Login. Do NOT auto-route to home just because session exists.
      // This prevents OTP verification from jumping to Home.
      home: const LoginPage(),

      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const RegisterPage(),
        '/home': (_) => const IgnisHomePage(),
      },
    );
  }
}