import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/app_content_refresh.dart';
import 'package:ignis_safe/app_version_service.dart';

void main() {
  group('contentFingerprint', () {
    test('is stable for equal payloads that arrive in a different order', () {
      final first = [
        {'key': 'a', 'text': 'Alpha'},
        {'key': 'b', 'text': 'Bravo'},
      ];
      final second = [
        {'text': 'Bravo', 'key': 'b'},
        {'text': 'Alpha', 'key': 'a'},
      ];

      expect(contentFingerprint(first), contentFingerprint(second));
    });

    test('changes when a value changes', () {
      final before = [
        {'key': 'a', 'text': 'Alpha'},
      ];
      final after = [
        {'key': 'a', 'text': 'Alpha edited'},
      ];

      expect(contentFingerprint(before), isNot(contentFingerprint(after)));
    });

    test('distinguishes keyed booleans', () {
      expect(
        contentFingerprint({'pre': true, 'post': false}),
        isNot(contentFingerprint({'pre': false, 'post': true})),
      );
    });
  });

  group('AppContentRefreshRegistry', () {
    setUp(AppContentRefreshRegistry.reset);
    tearDown(AppContentRefreshRegistry.reset);

    test('reports no change when the content is identical', () async {
      final owner = Object();
      final rows = [
        {'id': 1, 'title': 'Module 1'},
      ];

      AppContentRefreshRegistry.reportContent(owner, 'modules', rows);
      AppContentRefreshRegistry.register(owner, () async {
        AppContentRefreshRegistry.reportContent(owner, 'modules', rows);
      });

      final result = await AppContentRefreshRegistry.refreshAll();

      expect(result.failed, isFalse);
      expect(result.changed, isFalse);
    });

    test('reports a change when the refreshed content differs', () async {
      final owner = Object();

      AppContentRefreshRegistry.reportContent(owner, 'modules', [
        {'id': 1, 'title': 'Module 1'},
      ]);
      AppContentRefreshRegistry.register(owner, () async {
        AppContentRefreshRegistry.reportContent(owner, 'modules', [
          {'id': 1, 'title': 'Module 1 (updated)'},
        ]);
      });

      final result = await AppContentRefreshRegistry.refreshAll();

      expect(result.failed, isFalse);
      expect(result.changed, isTrue);
    });

    test('surfaces a handler failure and never claims a change', () async {
      final owner = Object();

      AppContentRefreshRegistry.register(owner, () async {
        throw Exception('offline');
      });

      final result = await AppContentRefreshRegistry.refreshAll();

      expect(result.failed, isTrue);
      expect(result.changed, isFalse);
    });

    test('runs every registered handler', () async {
      final firstOwner = Object();
      final secondOwner = Object();
      var calls = 0;

      AppContentRefreshRegistry.register(firstOwner, () async => calls++);
      AppContentRefreshRegistry.register(secondOwner, () async => calls++);

      await AppContentRefreshRegistry.refreshAll();

      expect(calls, 2);
    });
  });

  group('compareAppVersions', () {
    test('compares numerically, not alphabetically', () {
      expect(compareAppVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareAppVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareAppVersions('1.0.0', '1.0.0'), 0);
    });

    test('treats missing trailing parts as zero', () {
      expect(compareAppVersions('1.2', '1.2.0'), 0);
      expect(compareAppVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('ignores build and pre-release suffixes', () {
      expect(compareAppVersions('1.0.0+9', '1.0.0'), 0);
      expect(compareAppVersions('1.1.0-beta', '1.0.0'), greaterThan(0));
    });
  });

  group('AppUpdateStatus', () {
    AppUpdateStatus statusFor(AppRelease? latest) => AppUpdateStatus(
          installedVersion: '1.0.0',
          installedBuildNumber: 1,
          latest: latest,
        );

    test('is not an update when no release is published', () {
      expect(statusFor(null).updateAvailable, isFalse);
    });

    test('is not an update for the installed build', () {
      expect(
        statusFor(const AppRelease(version: '1.0.0', buildNumber: 1))
            .updateAvailable,
        isFalse,
      );
    });

    test('is not an update for an older release', () {
      expect(
        statusFor(const AppRelease(version: '0.9.0')).updateAvailable,
        isFalse,
      );
    });

    test('is an update for a newer version', () {
      expect(
        statusFor(const AppRelease(version: '1.1.0')).updateAvailable,
        isTrue,
      );
    });

    test('is an update for a newer build of the same version', () {
      expect(
        statusFor(const AppRelease(version: '1.0.0', buildNumber: 2))
            .updateAvailable,
        isTrue,
      );
    });
  });

  group('AppRelease.fromRow', () {
    test('maps a published release row', () {
      final release = AppRelease.fromRow({
        'version': ' 1.2.0 ',
        'build_number': '4',
        'release_notes': 'Bug fixes.',
        'release_notes_tl': '  ',
        'download_url': 'https://example.org/ignis-safe.apk',
        'is_mandatory': true,
      });

      expect(release, isNotNull);
      expect(release!.version, '1.2.0');
      expect(release.buildNumber, 4);
      expect(release.releaseNotesEn, 'Bug fixes.');
      expect(release.releaseNotesTl, isNull);
      expect(release.downloadUrl, 'https://example.org/ignis-safe.apk');
      expect(release.isMandatory, isTrue);
      expect(release.displayLabel, '1.2.0 (4)');
    });

    test('rejects a row without a version', () {
      expect(AppRelease.fromRow({'version': '  '}), isNull);
    });
  });
}
