import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:flutter/material.dart';

/// {@template golden_test_scenario_constraints}
/// Applies constraints to the children of [GoldenTestScenario] widgets. This is
/// intended for internal use only.
/// {@endtemplate}
class GoldenTestScenarioConstraints extends InheritedWidget {
  /// {@macro golden_test_scenario_constraints}
  const GoldenTestScenarioConstraints({
    required super.child,
    required this.constraints,
    super.key,
  });

  /// The constraints to apply to the scenario's child.
  final BoxConstraints? constraints;

  @override
  bool updateShouldNotify(covariant GoldenTestScenarioConstraints oldWidget) {
    return oldWidget.constraints != constraints;
  }

  /// Obtains the constraints from the nearest instance of this widget from the
  /// given context.
  static BoxConstraints? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<GoldenTestScenarioConstraints>()
      ?.constraints;
}
