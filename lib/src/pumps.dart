import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

/// A function that may perform pumping actions to prime a golden test.
///
/// Used in the [goldenTest] function to perform any actions necessary to prime
/// the widget tree before the golden test is compared or generated.
typedef PumpAction = Future<void> Function(WidgetTester tester);

/// Returns a custom pump action that pumps the widget tree [n] times before
/// golden evaluation.
///
/// See [PumpAction] for more details.
PumpAction pumpNTimes(int n, [Duration? duration]) {
  return (tester) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(duration);
    }
  };
}

/// A custom pump action that pumps the widget tree once before golden
/// evaluation.
///
/// See [PumpAction] for more details.
final pumpOnce = pumpNTimes(1);

/// A custom pump action that pumps and settles the widget tree before golden
/// evaluation.
///
/// See [PumpAction] for more details.
Future<void> onlyPumpAndSettle(WidgetTester tester) => tester.pumpAndSettle();
