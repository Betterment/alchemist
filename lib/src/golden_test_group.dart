import 'dart:math';

import 'package:alchemist/alchemist.dart';
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
/// See also:
/// * [GoldenTestScenario], which describes a single test scenario or state of
///   widget that should be included in a golden test group.
///
/// {@endtemplate}
class GoldenTestGroup extends StatelessWidget {
  /// {@macro golden_test_group}
  const GoldenTestGroup({
    super.key,
    this.columns,
    this.columnWidthBuilder,
    required this.children,
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

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      columnWidths: columnWidths,
      border: TableBorder.symmetric(
        inside: BorderSide(
          color: Colors.black.withOpacity(0.3),
        ),
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
    );
  }
}
