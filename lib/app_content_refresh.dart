import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Re-fetches one screen's Supabase-backed content and applies it to that
/// screen's state.
///
/// A handler must only complete once the screen shows the freshly fetched
/// data, and must throw when the re-fetch failed so the "Refresh & Check
/// Updates" action can tell the user instead of silently claiming success.
typedef AppContentRefreshHandler = Future<void> Function();

/// Outcome of [AppContentRefreshRegistry.refreshAll].
class AppContentRefreshResult {
  const AppContentRefreshResult({required this.changed, this.error});

  /// True when at least one screen's database content differs from what was
  /// on screen before the refresh.
  final bool changed;

  /// First failure raised by a refresh handler, if any.
  final Object? error;

  bool get failed => error != null;
}

/// Registry the long-lived home tabs (Learning Materials, About Us, Profile)
/// hook into so the profile menu's "Refresh & Check Updates" action can
/// re-fetch every screen's Supabase content at once, apply it immediately, and
/// still tell whether anything actually changed.
///
/// Screens report a fingerprint of the rows they just loaded from their normal
/// load path (start-up, realtime and manual refresh alike). Comparing the
/// fingerprints taken before and after [refreshAll] is what separates the
/// "IGNIS SAFE is up to date." message from "Latest content loaded
/// successfully.".
class AppContentRefreshRegistry {
  AppContentRefreshRegistry._();

  static final Map<Object, AppContentRefreshHandler> _handlers =
      <Object, AppContentRefreshHandler>{};
  static final Map<Object, Map<String, String>> _fingerprints =
      <Object, Map<String, String>>{};

  /// Registers [handler] for [owner] (normally the calling `State` object).
  static void register(Object owner, AppContentRefreshHandler handler) {
    _handlers[owner] = handler;
  }

  /// Drops [owner]'s handler and its recorded fingerprints.
  static void unregister(Object owner) {
    _handlers.remove(owner);
    _fingerprints.remove(owner);
  }

  /// Records what [owner] currently displays for [slot], e.g. the raw rows a
  /// screen just fetched from Supabase.
  static void reportContent(Object owner, String slot, Object? content) {
    (_fingerprints[owner] ??= <String, String>{})[slot] =
        contentFingerprint(content);
  }

  /// Runs every registered handler and reports whether the reloaded content
  /// differs from what was already on screen.
  static Future<AppContentRefreshResult> refreshAll() async {
    final before = _snapshotFingerprints();
    Object? firstError;

    await Future.wait(
      List<AppContentRefreshHandler>.of(_handlers.values).map((handler) async {
        try {
          await handler();
        } catch (error, stackTrace) {
          debugPrint('APP CONTENT REFRESH ERROR: $error\n$stackTrace');
          firstError ??= error;
        }
      }),
    );

    final error = firstError;

    return AppContentRefreshResult(
      // A partially failed refresh cannot be trusted to say whether content
      // changed, so only report a change when everything reloaded cleanly.
      changed: error == null &&
          !_fingerprintsEqual(before, _snapshotFingerprints()),
      error: error,
    );
  }

  @visibleForTesting
  static void reset() {
    _handlers.clear();
    _fingerprints.clear();
  }

  static Map<Object, Map<String, String>> _snapshotFingerprints() {
    return <Object, Map<String, String>>{
      for (final entry in _fingerprints.entries)
        entry.key: Map<String, String>.of(entry.value),
    };
  }

  static bool _fingerprintsEqual(
    Map<Object, Map<String, String>> a,
    Map<Object, Map<String, String>> b,
  ) {
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      if (other.length != entry.value.length) return false;
      for (final slot in entry.value.entries) {
        if (other[slot.key] != slot.value) return false;
      }
    }

    return true;
  }
}

/// Builds a short, stable fingerprint of decoded Supabase content.
///
/// The value is canonicalised first (map keys and list items sorted) so two
/// identical payloads that merely arrived in a different order are not
/// mistaken for an admin edit.
@visibleForTesting
String contentFingerprint(Object? content) {
  final canonical = _canonicalize(content);
  final bytes = utf8.encode(canonical);

  return '${canonical.length}-'
      '${_fnv1a32(bytes, 0x811C9DC5)}-'
      '${_fnv1a32(bytes, 0x01000193)}';
}

String _canonicalize(Object? value) {
  if (value == null) return 'null';

  if (value is Map) {
    final entries = value.entries
        .map((e) => '${jsonEncode(e.key.toString())}:${_canonicalize(e.value)}')
        .toList()
      ..sort();
    return '{${entries.join(',')}}';
  }

  if (value is Iterable) {
    final items = value.map(_canonicalize).toList()..sort();
    return '[${items.join(',')}]';
  }

  if (value is num || value is bool) return value.toString();
  if (value is String) return jsonEncode(value);

  return jsonEncode(value.toString());
}

/// 32-bit FNV-1a. Two passes with different seeds are combined in
/// [contentFingerprint] to keep accidental collisions negligible while staying
/// inside the integer range every Dart platform handles exactly.
int _fnv1a32(List<int> bytes, int seed) {
  var hash = seed;

  for (final byte in bytes) {
    hash = (hash ^ byte) & 0xFFFFFFFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }

  return hash;
}
