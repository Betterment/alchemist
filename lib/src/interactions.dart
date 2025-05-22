import 'package:alchemist/src/utilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// An interaction to perform while rendering a golden test. Returns
/// an asynchronous callback that should be called to cleanup when
/// the golden test completes.
typedef Interaction = Future<AsyncCallback?> Function(WidgetTester);

/// Presses all widgets matching `finder`.
Interaction press(
  Finder finder, {
  Duration? holdFor = const Duration(milliseconds: 300),
}) => (WidgetTester tester) async {
  final gestures = await tester.pressAll(finder);
  await tester.pump(kPressTimeout);
  await tester.pump(holdFor);
  return gestures.releaseAll;
};

/// Long-presses all widgets matching [finder].
Interaction longPress(Finder finder) => (WidgetTester tester) async {
  final gestures = await tester.pressAll(finder);
  await tester.pump(kLongPressTimeout);
  return gestures.releaseAll;
};

/// Scrolls all widgets matching `finder`.
Interaction scroll(
  Finder finder, {
  required Offset offset,
  double speed = kMinFlingVelocity,
}) => (WidgetTester tester) async {
  final elements = finder.evaluate();
  for (final element in elements) {
    await tester.fling(find.byWidget(element.widget), offset, speed);
  }
  return;
};
