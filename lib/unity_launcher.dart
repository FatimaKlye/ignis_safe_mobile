import 'package:flutter/services.dart';

class UnityLauncher {
  static const MethodChannel _channel = MethodChannel('ignis_safe/unity');

  static Future<void> openScene(String sceneName) async {
    await _channel.invokeMethod('openUnityScene', {
      'sceneName': sceneName,
    });
  }
}