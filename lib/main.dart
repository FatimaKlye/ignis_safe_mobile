import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login.dart';
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
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Ignis Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: session != null ? const IgnisHomePage() : const LoginPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const IgnisHomePage(),
      },
    );
  }
}