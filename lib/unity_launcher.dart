
import 'package:flutter/services.dart';

class UnityLaunchResult {
  final bool completed;
  final String? sceneName;

  const UnityLaunchResult({
    required this.completed,
    this.sceneName,
  });

  factory UnityLaunchResult.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return UnityLaunchResult(
        completed: map['completed'] == true,
        sceneName: map['sceneName'] as String?,
      );
    }

    if (raw is bool) {
      return UnityLaunchResult(completed: raw);
    }

    return const UnityLaunchResult(completed: false);
  }
}

class UnityLauncher {
  static const MethodChannel _channel = MethodChannel('ignis_safe/unity');

  static Future<UnityLaunchResult> openScene(String sceneName) async {
    final dynamic raw = await _channel.invokeMethod(
      'openUnityScene',
      {'sceneName': sceneName},
    );

    return UnityLaunchResult.fromDynamic(raw);
  }
}
