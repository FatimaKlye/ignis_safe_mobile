import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mvgpeiejwstrxjmfslke.supabase.co',
    anonKey: 'sb_publishable_rPBCsdTPJUWlslIDbF5f3g_uK-TKqxw',
  );
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfilePage(name: 'Preview User'),
    );
  }
}
