import 'package:alchemist/src/golden_test_scenario_constraints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoldenTestScenarioConstraints', () {
    const child = SizedBox();
    group('updateShouldNotify', () {
      test('returns false when constraints are the same', () {
        const newWidget = GoldenTestScenarioConstraints(
          constraints: BoxConstraints(maxHeight: 400),
          child: child,
        );
        const oldWidget = GoldenTestScenarioConstraints(
          constraints: BoxConstraints(maxHeight: 400),
          child: child,
        );

        expect(newWidget.updateShouldNotify(oldWidget), isFalse);
      });

      test('returns true when constraints are different', () {
        const newWidget = GoldenTestScenarioConstraints(
          constraints: BoxConstraints(maxHeight: 400),
          child: child,
        );
        const oldWidget = GoldenTestScenarioConstraints(
          constraints: BoxConstraints(maxWidth: 400),
          child: child,
        );

        expect(newWidget.updateShouldNotify(oldWidget), isTrue);
      });
    });

    group('maybeOf', () {
      testWidgets('returns the constraints from the nearest widget', (
        tester,
      ) async {
        late BoxConstraints? constraints;
        await tester.pumpWidget(
          GoldenTestScenarioConstraints(
            constraints: const BoxConstraints(maxHeight: 200),
            child: GoldenTestScenarioConstraints(
              constraints: const BoxConstraints(minWidth: 200),
              child: Builder(
                builder: (context) {
                  constraints = GoldenTestScenarioConstraints.maybeOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(constraints, equals(const BoxConstraints(minWidth: 200)));
      });
    });
  });
}
