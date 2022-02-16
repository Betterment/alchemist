import 'package:alchemist/src/utilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// An interaction to perform while rendering a golden test. Returns
/// an asynchronous callback that should be called to cleanup when
/// the golden test completes.
typedef Interaction = Future<AsyncCallback> Function(WidgetTester);

/// Presses all widgets matching [finder].
Interaction press(Finder finder) => (WidgetTester tester) async {
      final gestures = await tester.pressAll(finder);
      await tester.pump();
      return gestures.releaseAll;
    };

/// Long-presses all widgets matching [finder].
Interaction longPress(Finder finder) => (WidgetTester tester) async {
      final gestures = await tester.pressAll(finder);
      await tester.pump(kLongPressTimeout + kPressTimeout);
      return gestures.releaseAll;
    };
