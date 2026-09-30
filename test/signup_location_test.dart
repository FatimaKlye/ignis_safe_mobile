import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/dasmarinas_location.dart';
import 'package:ignis_safe/localization/language_controller.dart';
import 'package:ignis_safe/signup.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('outside selection clears barangay and allows a complete form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final language = LanguageController();
    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageController>.value(
        value: language,
        child: const MaterialApp(home: RegisterPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select your location'), findsNWidgets(2));
    expect(find.text('Barangay'), findsNothing);

    Future<void> chooseLocation(String value) async {
      await tester.ensureVisible(find.byType(DropdownButton<String>).first);
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    await chooseLocation(dasmarinasLocationLabel);
    expect(find.text('Barangay'), findsOneWidget);
    expect(
      find.text('Select your barangay in Dasmariñas City'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byType(DropdownButton<String>).last);
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(dasmarinasBarangays.first).last);
    await tester.pumpAndSettle();
    expect(find.text(dasmarinasBarangays.first), findsOneWidget);

    await chooseLocation(outsideDasmarinasLocationLabel);
    expect(find.text('Barangay'), findsNothing);
    expect(find.text(dasmarinasBarangays.first), findsNothing);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Jane Doe');
    await tester.enterText(fields.at(1), 'jane@gmail.com');
    await tester.enterText(fields.at(2), 'Password1!');
    await tester.enterText(fields.at(3), 'Password1!');
    await tester.pumpAndSettle();

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue to Email Verification'),
    );
    expect(continueButton.onPressed, isNotNull);

    await chooseLocation(dasmarinasLocationLabel);
    expect(
      find.text('Select your barangay in Dasmariñas City'),
      findsOneWidget,
    );
    final requiresBarangay = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue to Email Verification'),
    );
    expect(requiresBarangay.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
