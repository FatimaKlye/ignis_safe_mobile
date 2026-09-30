import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ignis_safe/consent_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const userId = '11111111-1111-4111-8111-111111111111';

Map<String, dynamic> consent(String type, {String owner = userId}) => {
  'user_id': owner,
  'document_type': type,
  'document_version': ConsentDocuments.versionOf(type),
  'accepted': true,
  'withdrawn_at': null,
  'accepted_at': '2026-09-01T00:00:00Z',
};

class ConsentApi {
  final rows = <Map<String, dynamic>>[];
  final inserted = <Map<String, dynamic>>[];
  final duplicateTypes = <String>{};
  bool denyMirror = false;
  bool denyInsert = false;
  bool hideSaved = false;
  bool failRead = false;
  int profileUpdates = 0;
  bool profileAccepted = false;

  late final client = SupabaseClient(
    'https://example.supabase.co',
    'test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      http.Response json(Object value, int status) => http.Response(
        jsonEncode(value),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );
      if (request.url.path.endsWith('/user_consents')) {
        if (request.method == 'GET') {
          if (failRead) throw Exception('Connection unavailable');
          final owner = request.url.queryParameters['user_id']!.substring(3);
          return json(
            hideSaved
                ? []
                : rows
                      .where(
                        (row) =>
                            row['user_id'] == owner &&
                            row['accepted'] == true &&
                            row['withdrawn_at'] == null,
                      )
                      .toList(),
            200,
          );
        }
        if (request.method == 'POST') {
          if (denyInsert) {
            return json({'code': '42501', 'message': 'Denied'}, 403);
          }
          final row = Map<String, dynamic>.from(
            jsonDecode(request.body) as Map,
          );
          inserted.add(row);
          rows.add({...row, 'withdrawn_at': null});
          if (duplicateTypes.contains(row['document_type'])) {
            return json({
              'code': '23505',
              'message': 'Concurrent acceptance',
            }, 409);
          }
          return http.Response('', 201, request: request);
        }
      }
      if (request.url.path.endsWith('/profiles')) {
        if (request.method == 'GET') {
          return json({
            'terms_accepted': profileAccepted,
            'terms_accepted_at': null,
          }, 200);
        }
        if (request.method == 'PATCH') {
          profileUpdates++;
          if (denyMirror) {
            return json({'code': '42501', 'message': 'Denied'}, 403);
          }
          profileAccepted = true;
          return http.Response('', 204, request: request);
        }
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.url.path}',
      );
    }),
  );

  ConsentService get service => ConsentService(client: client);
  Future<void> save({List<String> types = ConsentDocuments.required}) => service
      .recordConsents(userId: userId, documentTypes: types, languageCode: 'en');
}

void main() {
  test(
    'saved consent succeeds even if personnel profile mirror is denied',
    () async {
      final api = ConsentApi()..denyMirror = true;
      await api.save();
      expect(await api.service.hasRequiredConsents(userId), isTrue);
      expect(api.profileUpdates, 1);
      expect(
        api.inserted.map((r) => r['document_type']),
        ConsentDocuments.required,
      );
    },
  );

  test('revisit does not rewrite acceptance dates or profile', () async {
    final api = ConsentApi()
      ..rows.addAll(ConsentDocuments.required.map(consent));
    await api.save();
    expect(api.inserted, isEmpty);
    expect(api.profileUpdates, 0);
    expect(api.rows.first['accepted_at'], '2026-09-01T00:00:00Z');
  });

  test(
    'concurrent duplicate does not skip the other required document',
    () async {
      final api = ConsentApi()..duplicateTypes.add(ConsentDocuments.terms);
      await api.save();
      expect(await api.service.hasRequiredConsents(userId), isTrue);
      expect(api.inserted, hasLength(2));
    },
  );

  test('unverified writes cannot report success or update profile', () async {
    final api = ConsentApi()..hideSaved = true;
    await expectLater(api.save(), throwsStateError);
    expect(api.profileUpdates, 0);
  });

  test('denied consent write is still a real error', () async {
    final api = ConsentApi()..denyInsert = true;
    await expectLater(api.save(), throwsA(isA<PostgrestException>()));
    expect(api.profileUpdates, 0);
  });

  test('lookup failure is not returned as a new-account status', () async {
    final api = ConsentApi()..failRead = true;
    await expectLater(api.service.hasRequiredConsents(userId), throwsException);
  });

  test('old versions and withdrawn decisions require a new decision', () async {
    final api = ConsentApi()
      ..rows.addAll([
        {...consent(ConsentDocuments.terms), 'document_version': '1.0'},
        {...consent(ConsentDocuments.privacy), 'withdrawn_at': '2026-09-02'},
      ]);
    expect(await api.service.hasRequiredConsents(userId), isFalse);
  });

  test('acceptance is account-specific', () async {
    final api = ConsentApi()
      ..rows.addAll(ConsentDocuments.required.map(consent));
    expect(await api.service.hasRequiredConsents('another-user'), isFalse);
  });

  test('optional research is not automatically granted', () async {
    final api = ConsentApi();
    await api.save();
    expect(
      await api.service.activeConsentTypes(userId),
      isNot(contains(ConsentDocuments.research)),
    );
  });

  test('only missing documents are saved', () async {
    final api = ConsentApi()..rows.add(consent(ConsentDocuments.terms));
    await api.save();
    expect(api.inserted.single['document_type'], ConsentDocuments.privacy);
    expect(api.rows.first['accepted_at'], '2026-09-01T00:00:00Z');
  });
}
