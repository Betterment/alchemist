import 'dart:math';

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/golden_test_scenario_constraints.dart';
import 'package:flutter/material.dart';

/// A function that receives the index of a column in a table and returns the
/// desired column width behavior.
typedef ColumnWidthBuilder = TableColumnWidth? Function(int columns);

/// {@template golden_test_group}
/// A widget responsible for grouping test scenarios for use in golden tests.
///
/// Commonly used in the [goldenTest] function. See its documentation for more
/// details.
///
/// This widgets groups together all provided [children] into a single widget
/// with a table layout, and its resulting snapshot will be used when generating
/// golden test images. The list of [children] must be provided and must not be
/// empty.
///
/// The [columns] parameter determines the number of columns in the table. If
/// provided, the resulting table will have the specified number of columns. If
/// left unset, the number of columns will be determined by the number of
/// provided [children].
///
/// The [columnWidthBuilder], if provided, will be used to determine the width
/// of each column in the table. If not provided, the width for every column is
/// determined by the widest widget in that column ([IntrinsicColumnWidth]).
/// Returning `null` will tell the table to use the default column width for the
/// column at the given index.
///
/// The [scenarioConstraints] parameter, if provided, will be applied to
/// the children of each [GoldenTestScenario] in [children]. Otherwise, the
/// children will only be constrained based on each column's width according
/// to the [columnWidthBuilder], and unconstrained vertically. Note: the
/// constraints will not apply to children that aren't [GoldenTestScenario]s.
///
/// See also:
/// * [GoldenTestScenario], which describes a single test scenario or state of
///   widget that should be included in a golden test group.
///
/// {@endtemplate}
class GoldenTestGroup extends StatelessWidget {
  /// {@macro golden_test_group}
  const GoldenTestGroup({
    required this.children,
    super.key,
    this.columns,
    this.columnWidthBuilder,
    this.scenarioConstraints,
  });

  /// The number of columns in the grid.
  ///
  /// If left unset, the number of columns will be calculated based on the
  /// number of children.
  final int? columns;

  /// A builder that returns the desired column widths for every column in the
  /// table that shows the children in this builder.
  ///
  /// Returning `null` will tell the table to use the default column width for
  /// the column at the given index.
  ///
  /// The default width for every column is determined by the widest widget in
  /// that column ([IntrinsicColumnWidth]).
  ///
  /// If this function returns `null` for a given column, the table uses the
  /// default column width instead.
  ///
  /// See [Table.columnWidths] for details.
  final ColumnWidthBuilder? columnWidthBuilder;

  /// An optional set of constraints that will be applied to the child of each
  /// [GoldenTestScenario] in the [children].
  ///
  /// If set, every child will be constrained according to these constraints.
  /// Otherwise, the children will only be constrained based on each column's
  /// width according to the [columnWidthBuilder].
  ///
  /// Note: the constraints will not apply to any child that isn't a
  /// [GoldenTestScenario].
  final BoxConstraints? scenarioConstraints;

  /// The scenarios to display in this test group.
  ///
  /// This list should contain every widget that should be included in the
  /// golden test. See [GoldenTestScenario] for more details.
  ///
  /// This list must be provided and must not be empty.
  final List<Widget> children;

  /// The amount of columns that the [build] method should return when building
  /// the golden file.
  int get _effectiveColumns => columns ?? sqrt(children.length).ceil();

  /// The the amount of rows that the [build] method should return when building
  /// the golden file.
  int get _effectiveRows => (children.length / _effectiveColumns).ceil();

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{};

    if (columnWidthBuilder != null) {
      for (var i = 0; i < _effectiveColumns; i++) {
        final value = columnWidthBuilder!(i);
        if (value != null) {
          columnWidths[i] = value;
        }
      }
    }

    final testTheme =
        Theme.of(context).extension<GoldenTestTheme>() ??
        AlchemistConfig.current().goldenTestTheme ??
        GoldenTestTheme.standard();

    return GoldenTestScenarioConstraints(
      constraints: scenarioConstraints,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        columnWidths: columnWidths,
        border: TableBorder.symmetric(
          inside: BorderSide(color: testTheme.borderColor),
        ),
        children: [
          for (int i = 0; i < _effectiveRows; i++)
            TableRow(
              children: [
                for (int j = 0; j < _effectiveColumns; j++)
                  if (i * _effectiveColumns + j < children.length)
                    children[i * _effectiveColumns + j]
                  else
                    const SizedBox.shrink(),
              ],
            ),
        ],
      ),
    );
  }
}
