import 'package:alchemist/src/interactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('press', () {
    Widget buildWrapper(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('presses', (tester) async {
      var onPressedCalled = false;
      await tester.pumpWidget(
        buildWrapper(
          ElevatedButton(
            onPressed: () {
              onPressedCalled = true;
            },
            child: const Text('button'),
          ),
        ),
      );
      final cleanup = await press(find.byType(ElevatedButton))(tester);
      await cleanup();
      expect(onPressedCalled, isTrue);
    });

    testWidgets('longPresses', (tester) async {
      var onLongPressedCalled = false;
      await tester.pumpWidget(
        buildWrapper(
          ElevatedButton(
            onPressed: null,
            onLongPress: () {
              onLongPressedCalled = true;
            },
            child: const Text('button'),
          ),
        ),
      );
      final cleanup = await longPress(find.byType(ElevatedButton))(tester);
      await cleanup();
      expect(onLongPressedCalled, isTrue);
    });
  });
}
