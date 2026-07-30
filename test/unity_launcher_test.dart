import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/module_progress_overview_service.dart';
import 'package:ignis_safe/unity_launcher.dart';

void main() {
  group('UnityLaunchResult', () {
    test('accepts an explicit completion result', () {
      final result = UnityLaunchResult.fromDynamic({
        'completed': true,
        'sceneName': 'FireExtinguisher_PASS',
      });

      expect(result.completed, isTrue);
      expect(result.sceneName, 'FireExtinguisher_PASS');
    });

    test('treats a cancelled activity result as incomplete', () {
      final result = UnityLaunchResult.fromDynamic({
        'completed': false,
        'sceneName': 'House_FireEscape',
      });

      expect(result.completed, isFalse);
      expect(result.sceneName, 'House_FireEscape');
    });

    test('defaults malformed native responses to incomplete', () {
      expect(UnityLaunchResult.fromDynamic(null).completed, isFalse);
      expect(UnityLaunchResult.fromDynamic('completed').completed, isFalse);
    });
  });

  test('module progress overview maps database booleans safely', () {
    final overview = ModuleProgressOverview.fromMap({
      'module_no': 4,
      'pre_test_completed': true,
      'can_open_learning': true,
      'learning_completed': true,
      'can_open_post_test': false,
      'post_test_completed': true,
    });

    expect(overview.moduleNo, 4);
    expect(overview.preTestCompleted, isTrue);
    expect(overview.canOpenLearning, isTrue);
    expect(overview.learningCompleted, isTrue);
    expect(overview.canOpenPostTest, isFalse);
    expect(overview.postTestCompleted, isTrue);
  });
}
