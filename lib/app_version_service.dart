import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A published mobile release, as stored in `public.mobile_app_versions`.
class AppRelease {
  const AppRelease({
    required this.version,
    this.buildNumber,
    this.releaseNotesEn,
    this.releaseNotesTl,
    this.downloadUrl,
    this.isMandatory = false,
  });

  final String version;
  final int? buildNumber;
  final String? releaseNotesEn;
  final String? releaseNotesTl;
  final String? downloadUrl;
  final bool isMandatory;

  static AppRelease? fromRow(Map<String, dynamic> row) {
    final version = row['version']?.toString().trim() ?? '';
    if (version.isEmpty) return null;

    return AppRelease(
      version: version,
      buildNumber: _toIntOrNull(row['build_number']),
      releaseNotesEn: _trimToNull(row['release_notes']),
      releaseNotesTl: _trimToNull(row['release_notes_tl']),
      downloadUrl: _trimToNull(row['download_url']),
      isMandatory: row['is_mandatory'] == true,
    );
  }

  /// Version label as shown to the user, e.g. `1.2.0 (7)`.
  String get displayLabel =>
      buildNumber == null ? version : '$version ($buildNumber)';
}

/// Result of comparing the installed build with the latest published release.
class AppUpdateStatus {
  const AppUpdateStatus({
    required this.installedVersion,
    this.installedBuildNumber,
    this.latest,
  });

  final String installedVersion;
  final int? installedBuildNumber;

  /// Latest release published in Supabase, or null when the release table
  /// holds nothing for this platform yet.
  final AppRelease? latest;

  String get installedLabel => installedBuildNumber == null
      ? installedVersion
      : '$installedVersion ($installedBuildNumber)';

  bool get updateAvailable {
    final release = latest;
    if (release == null) return false;

    final comparison = compareAppVersions(release.version, installedVersion);
    if (comparison != 0) return comparison > 0;

    final latestBuild = release.buildNumber;
    final installedBuild = installedBuildNumber;
    if (latestBuild == null || installedBuild == null) return false;

    return latestBuild > installedBuild;
  }
}

/// Reads the installed build from the platform package and the latest
/// published release from Supabase.
///
/// An app binary cannot be swapped out by refreshing data, so this check never
/// touches the content refresh: it only reports whether a newer build exists
/// so the update dialog can point the user at the real download.
class AppVersionService {
  AppVersionService._();

  static const String tableName = 'mobile_app_versions';

  /// Postgres/PostgREST codes returned when the release table has not been
  /// created in this project yet. Treated as "no release published" instead of
  /// an error so the refresh action keeps working before the migration runs.
  static const Set<String> _missingTableCodes = {'42P01', 'PGRST205'};

  static Future<AppUpdateStatus> check({SupabaseClient? client}) async {
    final packageInfo = await PackageInfo.fromPlatform();

    return AppUpdateStatus(
      installedVersion: packageInfo.version.trim(),
      installedBuildNumber: _toIntOrNull(packageInfo.buildNumber),
      latest: await _fetchLatestRelease(client ?? Supabase.instance.client),
    );
  }

  static Future<AppRelease?> _fetchLatestRelease(SupabaseClient client) async {
    try {
      final row = await client
          .from(tableName)
          .select()
          .eq('platform', currentPlatformKey)
          .eq('is_active', true)
          .order('released_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return null;

      return AppRelease.fromRow(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      if (_missingTableCodes.contains(e.code)) {
        debugPrint('APP VERSION CHECK: $tableName is not provisioned yet.');
        return null;
      }
      rethrow;
    }
  }

  static String get currentPlatformKey {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'android';
    }
  }
}

/// Compares dotted numeric version strings (`1.10.2` > `1.9.9`).
///
/// Returns a negative number when [a] is older than [b], zero when they match
/// and a positive number when [a] is newer.
int compareAppVersions(String a, String b) {
  final left = _versionParts(a);
  final right = _versionParts(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final leftPart = i < left.length ? left[i] : 0;
    final rightPart = i < right.length ? right[i] : 0;
    if (leftPart != rightPart) return leftPart.compareTo(rightPart);
  }

  return 0;
}

List<int> _versionParts(String version) {
  // Drops any build/pre-release suffix such as `1.2.0+4` or `1.2.0-beta`.
  final core = version.trim().split(RegExp(r'[+\-\s]')).first;

  return core
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

int? _toIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return int.tryParse(text);
}

String? _trimToNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
