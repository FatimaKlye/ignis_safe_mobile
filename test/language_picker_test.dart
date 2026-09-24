import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/localization/language_controller.dart';
import 'package:ignis_safe/widgets/language_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness(LanguageController controller) {
  return ChangeNotifierProvider<LanguageController>.value(
    value: controller,
    child: Consumer<LanguageController>(
      builder: (context, lang, _) => MaterialApp(
        locale: lang.locale,
        supportedLocales: const [Locale('en'), Locale('tl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const CompactLanguageToggle(),
                Text('current:${lang.currentLanguageName}'),
                TextButton(
                  onPressed: () => showLanguagePicker(context),
                  child: const Text('open picker'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('compact toggle and picker share and persist the language',
      (tester) async {
    final controller = LanguageController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();
    expect(find.text('current:English'), findsOneWidget);

    // Login-style compact toggle.
    await tester.tap(find.text('Filipino'));
    await tester.pumpAndSettle();
    expect(controller.locale.languageCode, 'tl');
    expect(find.text('current:Filipino'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language_code'), 'tl');

    // Profile-style picker reflects and changes the same preference.
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.widgetWithText(ListTile, 'English'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(controller.locale.languageCode, 'en');
    expect(find.text('current:English'), findsOneWidget);
    expect(prefs.getString('app_language_code'), 'en');
  });

  testWidgets('saved language is restored on startup', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language_code': 'tl'});
    final controller = LanguageController();
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();
    expect(controller.locale.languageCode, 'tl');
    expect(find.text('current:Filipino'), findsOneWidget);
  });
}
