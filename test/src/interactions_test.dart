import 'package:alchemist/src/interactions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWrapper(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('press', () {
    testWidgets('press presses correctly', (tester) async {
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
      await cleanup?.call();
      expect(onPressedCalled, isTrue);
    });

    testWidgets('press for custom time pumps correctly', (tester) async {
      await tester.pumpWidget(
        buildWrapper(
          ElevatedButton(onPressed: () {}, child: const Text('button')),
        ),
      );
      const holdForDuration = Duration(seconds: 3);
      // Since `testWidgets` runs inside a `fakeAsync` context, we can grab the
      // fake starting time. Pumping for a certain [Duration] advances the
      // fake test clock, allowing us to verify we are pumping correctly
      // in the interactions code.
      final startTime = tester.binding.clock.now();
      final cleanup = await press(
        find.byType(ElevatedButton),
        holdFor: holdForDuration,
      )(tester);
      await cleanup?.call();
      final elapsed = tester.binding.clock.now().difference(startTime);
      expect(elapsed, greaterThanOrEqualTo(holdForDuration + kPressTimeout));
    });
  });

  testWidgets('longPress', (tester) async {
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
    await cleanup?.call();
    expect(onLongPressedCalled, isTrue);
  });

  testWidgets('scroll', (tester) async {
    await tester.pumpWidget(
      buildWrapper(
        ListView.builder(
          // this `itemCount` is long enough to reach the `dragOffset`
          // we're using on our scroll interaction.
          itemCount: 20,
          itemBuilder: (context, index) {
            return ListTile(title: Text('item $index'));
          },
        ),
      ),
    );

    const dragOffset = 100.0;

    final cleanup = await scroll(
      find.byType(Scrollable),
      offset: const Offset(0, -dragOffset),
    )(tester);

    await cleanup?.call();

    final viewportFinder = find.byType(Viewport);
    final viewport = tester.renderObject(viewportFinder) as RenderViewport;

    expect(viewport.offset.pixels, dragOffset);
  });
}
