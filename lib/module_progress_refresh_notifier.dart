import 'package:flutter/foundation.dart';

/// Notifies the long-lived home tabs (Learning Materials, Modules) that the
/// signed-in learner's saved module progress changed in Supabase, so they can
/// re-fetch it instead of showing a stale unlock/completion state.
///
/// Mirrors `profileRefreshNotifier`: a bumped counter the tabs listen to.
final ValueNotifier<int> moduleProgressRefreshNotifier = ValueNotifier<int>(0);

void notifyModuleProgressChanged() {
  moduleProgressRefreshNotifier.value++;
}
