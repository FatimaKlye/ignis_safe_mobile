import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis_safe/widgets/keyboard_dismiss_scope.dart';

void main() {
  testWidgets('navigation releases focused input', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [KeyboardDismissNavigatorObserver()],
        builder: (context, child) =>
            KeyboardDismissScope(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focusNode),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Next')),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
    expect(find.text('Next'), findsOneWidget);
  });
}
