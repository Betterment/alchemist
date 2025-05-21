import 'package:alchemist/src/golden_test_group.dart';
import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:alchemist/src/golden_test_scenario_constraints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [Matcher] that matches a [Table] widget with the given [amount] of
/// columns.
Matcher hasColumns(int amount) {
  return isA<Table>().having(
    (t) => t.children.isEmpty ? null : t.children.first,
    'first row',
    isA<TableRow>().having((r) => r.children.length, 'column count', amount),
  );
}

/// A [Matcher] that matches a [FixedColumnWidth] instance with the given
/// [width].
Matcher isAFixedColumnWidth(double width) {
  return isA<FixedColumnWidth>().having((w) => w.value, 'value', width);
}

void main() {
  group('GoldenTestGroup', () {
    GoldenTestScenario buildScenario({
      String name = 'scenario',
      double width = 100,
      double height = 100,
      Color? color,
    }) {
      return GoldenTestScenario(
        name: name,
        child: SizedBox(
          width: width,
          height: height,
          child: Placeholder(color: color ?? const Color(0xFF000000)),
        ),
      );
    }

    List<GoldenTestScenario> buildScenarios(int amount) {
      return [
        for (int i = 0; i < amount; i++)
          buildScenario(name: 'scenario ${i + 1}', color: Colors.primaries[i]),
      ];
    }

    Widget buildSubject({
      Key? key,
      int? columns,
      ColumnWidthBuilder? columnWidthBuilder,
      BoxConstraints? scenarioConstraints,
      List<Widget>? children,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: GoldenTestGroup(
            key: key,
            columns: columns,
            columnWidthBuilder: columnWidthBuilder,
            scenarioConstraints: scenarioConstraints,
            children: children ?? buildScenarios(4),
          ),
        ),
      );
    }

    testWidgets('renders table with scenarios', (tester) async {
      final subject = buildSubject(children: buildScenarios(4));

      await tester.pumpWidget(subject);

      expect(find.byType(Table), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Table),
          matching: find.byType(GoldenTestScenario),
        ),
        findsNWidgets(4),
      );
    });

    group('default table column count', () {
      testWidgets('is 1 when 1 scenario is provided', (tester) async {
        final subject = buildSubject(children: buildScenarios(1));
        await tester.pumpWidget(subject);

        expect(tester.widget(find.byType(Table)), hasColumns(1));
      });

      testWidgets('is 2 when 4 scenarios are provided', (tester) async {
        final subject = buildSubject(children: buildScenarios(4));
        await tester.pumpWidget(subject);

        expect(tester.widget(find.byType(Table)), hasColumns(2));
      });
      testWidgets('is 3 when 6 scenarios are provided', (tester) async {
        final subject = buildSubject(children: buildScenarios(6));
        await tester.pumpWidget(subject);

        expect(tester.widget(find.byType(Table)), hasColumns(3));
      });

      testWidgets('is 4 when 10 scenarios are provided', (tester) async {
        final subject = buildSubject(children: buildScenarios(10));
        await tester.pumpWidget(subject);

        expect(tester.widget(find.byType(Table)), hasColumns(4));
      });
    });

    testWidgets('sets column count to provided value '
        'regardless of scenario count', (tester) async {
      final subject = buildSubject(columns: 2, children: buildScenarios(10));
      await tester.pumpWidget(subject);

      expect(tester.widget(find.byType(Table)), hasColumns(2));
    });

    testWidgets('sets column width based on provided '
        'column width builder if provided', (tester) async {
      final callArguments = <Object?>[];

      final subject = buildSubject(
        columns: 3,
        columnWidthBuilder: (i) {
          callArguments.add(i);
          return FixedColumnWidth(i * 100 + 100);
        },
        children: buildScenarios(3),
      );
      await tester.pumpWidget(subject);

      final callCount = callArguments.length;
      expect(callCount, 3);
      expect(callArguments, [0, 1, 2]);

      expect(
        tester.widget(find.byType(Table)),
        isA<Table>().having(
          (t) => t.columnWidths,
          'column widths map',
          isA<Map<int, TableColumnWidth>>()
              .having((m) => m.length, 'length', 3)
              .having((m) => m[0], 'first element', isAFixedColumnWidth(100))
              .having((m) => m[1], 'second element', isAFixedColumnWidth(200))
              .having((m) => m[2], 'third element', isAFixedColumnWidth(300)),
        ),
      );
    });

    testWidgets('passes on scenario constraints if provided', (tester) async {
      const constraints = BoxConstraints(
        minWidth: 100,
        minHeight: 100,
        maxWidth: 200,
        maxHeight: 200,
      );

      final subject = buildSubject(
        scenarioConstraints: constraints,
        children: buildScenarios(3),
      );
      await tester.pumpWidget(subject);

      expect(
        tester
            .widget<GoldenTestScenarioConstraints>(
              find.byType(GoldenTestScenarioConstraints),
            )
            .constraints,
        constraints,
      );
    });
  });
}
