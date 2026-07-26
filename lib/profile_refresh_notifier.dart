import 'package:flutter/foundation.dart';

/// Notifies long-lived home tabs that the signed-in user's profile changed.
final ValueNotifier<int> profileRefreshNotifier = ValueNotifier<int>(0);

void notifyProfileChanged() {
  profileRefreshNotifier.value++;
}
