import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/consent_service.dart';
import 'package:ignis_safe/terms.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeConsentService extends ConsentService {
  FakeConsentService()
    : super(
        client: SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  Set<String> active = {};
  bool failLoad = false;
  int saves = 0;
  List<String> savedTypes = [];

  @override
  Future<Set<String>> activeConsentTypes(String userId) async {
    if (failLoad) throw Exception('Connection unavailable');
    return active;
  }

  @override
  Future<void> recordConsents({
    required String userId,
    required List<String> documentTypes,
    required String languageCode,
  }) async {
    saves++;
    savedTypes = documentTypes;
  }
}

void main() {
  Future<void> open(
    WidgetTester tester,
    FakeConsentService service, {
    String? userId = 'test-user',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TermsAndConditionsPage(userId: userId, consentService: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> readToBottom(WidgetTester tester) async {
    final list = tester.widget<ListView>(find.byType(ListView));
    list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
    await tester.pumpAndSettle();
  }

  testWidgets('accepted account can review without scrolling or checkboxes', (
    tester,
  ) async {
    final service = FakeConsentService()
      ..active = ConsentDocuments.required.toSet();
    await open(tester, service);
    expect(find.text('Already accepted'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Scroll to the bottom to continue'), findsNothing);
    expect(find.text('Optional research consent: Not given'), findsOneWidget);
    expect(service.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-time account must read and approve required documents', (
    tester,
  ) async {
    final service = FakeConsentService();
    await open(tester, service);
    expect(find.text('Scroll to the bottom to continue'), findsOneWidget);
    expect(find.text('Already accepted'), findsNothing);
    await readToBottom(tester);
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed lookup offers retry and does not offer approval', (
    tester,
  ) async {
    final service = FakeConsentService()..failLoad = true;
    await open(tester, service);
    expect(find.text('Acceptance status unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await readToBottom(tester);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('I Agree and Continue'), findsNothing);
    service.failLoad = false;
    service.active = ConsentDocuments.required.toSet();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Already accepted'), findsOneWidget);
    expect(service.saves, 0);
  });

  testWidgets(
    'existing individual consent is restored and cannot be unchecked',
    (tester) async {
      final service = FakeConsentService()..active = {ConsentDocuments.terms};
      await open(tester, service);
      await readToBottom(tester);
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes[0].value, isTrue);
      expect(boxes[0].onChanged, isNull);
      expect(boxes[1].value, isFalse);
      expect(boxes[1].onChanged, isNotNull);
    },
  );

  testWidgets(
    'signed-out document viewing is read-only, not a new-account form',
    (tester) async {
      await open(tester, FakeConsentService(), userId: null);
      expect(find.text('Review the documents'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Already accepted'), findsNothing);
      await readToBottom(tester);
      expect(find.byType(Checkbox), findsNothing);
    },
  );

  testWidgets(
    'accepted Done returns success to the login gate without resaving',
    (tester) async {
      final service = FakeConsentService()
        ..active = ConsentDocuments.required.toSet();
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TermsAndConditionsPage(
                      userId: 'test-user',
                      consentService: service,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(service.saves, 0);
    },
  );

  testWidgets(
    'accepted review fits a small phone and preserves research choice',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final service = FakeConsentService()
        ..active = {...ConsentDocuments.required, ConsentDocuments.research};
      await open(tester, service);
      expect(find.text('Already accepted'), findsOneWidget);
      expect(find.text('Optional research consent: Accepted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
