import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Identifiers and versions of the consent documents shown in [terms.dart].
///
/// Bump a version whenever the corresponding document changes materially.
/// Learners whose stored consent points at an older version are asked to read
/// and accept the document again on their next login.
class ConsentDocuments {
  const ConsentDocuments._();

  static const String terms = 'terms';
  static const String privacy = 'privacy';
  static const String research = 'research';

  static const String termsVersion = '2.0';
  static const String privacyVersion = '2.1';
  static const String researchVersion = '1.0';

  /// Effective date of the current Terms and Privacy Notice.
  static const String effectiveDateEn = '1 September 2026';
  static const String effectiveDateTl = '1 Setyembre 2026';

  /// Consents a learner must give before the app may be used.
  /// Research participation is deliberately excluded — it stays optional.
  static const List<String> required = <String>[terms, privacy];

  static String versionOf(String documentType) {
    switch (documentType) {
      case terms:
        return termsVersion;
      case privacy:
        return privacyVersion;
      case research:
        return researchVersion;
      default:
        throw ArgumentError.value(
          documentType,
          'documentType',
          'Unknown consent document type',
        );
    }
  }
}

/// Reads and writes the versioned consent history in `public.user_consents`.
///
/// `profiles.terms_accepted` is still maintained alongside it so the existing
/// admin dashboard keeps working, but this table is the authoritative record.
class ConsentService {
  ConsentService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const String _table = 'user_consents';

  /// Document types the user has currently accepted at their **current**
  /// version and has not withdrawn.
  Future<Set<String>> activeConsentTypes(String userId) async {
    final rows = await _supabase
        .from(_table)
        .select('document_type, document_version, accepted, withdrawn_at')
        .eq('user_id', userId)
        .eq('accepted', true)
        .isFilter('withdrawn_at', null);

    final active = <String>{};

    for (final row in (rows as List)) {
      final type = row['document_type']?.toString();
      final version = row['document_version']?.toString();
      if (type == null || version == null) continue;

      String currentVersion;
      try {
        currentVersion = ConsentDocuments.versionOf(type);
      } on ArgumentError {
        continue;
      }

      if (version == currentVersion) {
        active.add(type);
      }
    }

    return active;
  }

  /// True only when every required document has been accepted at its current
  /// version. A material version bump therefore re-triggers the consent flow.
  ///
  /// Throws on network/permission failures so the caller can decide how to
  /// handle them.
  Future<bool> hasRequiredConsents(String userId) async {
    final active = await activeConsentTypes(userId);
    return ConsentDocuments.required.every(active.contains);
  }

  /// Appends a consent record for each requested document type, skipping any
  /// the user has already accepted at the current version.
  ///
  /// Also mirrors acceptance of the required documents onto
  /// `profiles.terms_accepted` for backwards compatibility.
  Future<void> recordConsents({
    required String userId,
    required List<String> documentTypes,
    required String languageCode,
  }) async {
    if (documentTypes.isEmpty) return;

    final language = languageCode == 'tl' ? 'tl' : 'en';
    final alreadyActive = await activeConsentTypes(userId);
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    final requested = documentTypes.toSet();
    final payload = <Map<String, dynamic>>[
      for (final type in requested)
        if (!alreadyActive.contains(type))
          {
            'user_id': userId,
            'document_type': type,
            'document_version': ConsentDocuments.versionOf(type),
            'accepted': true,
            'accepted_at': nowUtc,
            'language': language,
          },
    ];

    // An ordinary revisit is read-only: keep the original acceptance dates.
    if (payload.isEmpty) return;

    // Insert individually so a concurrent duplicate cannot roll back the
    // other document decisions in a bulk insert.
    for (final row in payload) {
      try {
        await _supabase.from(_table).insert(row);
      } on PostgrestException catch (e) {
        // Verify the existing row below rather than assuming a duplicate
        // means all requested decisions have been recorded.
        if (e.code != '23505') rethrow;
      }
    }

    final persisted = await activeConsentTypes(userId);
    if (!requested.every(persisted.contains)) {
      throw StateError(
        'Consent decisions could not be verified. Please retry.',
      );
    }

    if (ConsentDocuments.required.every(persisted.contains)) {
      // This legacy dashboard flag is not the consent record. Personnel may
      // have permission to save their own consents but not update profiles.
      // Never report verified acceptance as failed due to this mirror.
      try {
        final profile = await _supabase
            .from('profiles')
            .select('terms_accepted, terms_accepted_at')
            .eq('id', userId)
            .maybeSingle();
        if (profile != null && profile['terms_accepted'] != true) {
          await _supabase
              .from('profiles')
              .update({
                'terms_accepted': true,
                if (profile['terms_accepted_at'] == null)
                  'terms_accepted_at': nowUtc,
              })
              .eq('id', userId);
        }
      } catch (_) {
        debugPrint(
          'Consent saved; legacy profile acceptance mirror unavailable.',
        );
      }
    }
  }

  /// Marks the user's current consent for [documentType] as withdrawn.
  /// The historical row is kept — only `withdrawn_at` is stamped.
  Future<void> withdrawConsent({
    required String userId,
    required String documentType,
  }) async {
    try {
      await _supabase
          .from(_table)
          .update({'withdrawn_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', userId)
          .eq('document_type', documentType)
          .eq('document_version', ConsentDocuments.versionOf(documentType))
          .eq('accepted', true)
          .isFilter('withdrawn_at', null);
    } catch (e) {
      debugPrint('Could not withdraw consent for $documentType: $e');
      rethrow;
    }
  }
}
