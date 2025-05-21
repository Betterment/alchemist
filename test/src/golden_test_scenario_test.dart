import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:alchemist/src/golden_test_scenario_constraints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoldenTestScenario', () {
    Widget buildSubject({
      Key? key,
      String name = 'name',
      Widget child = const Text('child'),
      BoxConstraints? constraints,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: GoldenTestScenario(
            key: key,
            name: name,
            constraints: constraints,
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders name as label', (tester) async {
      final subject = buildSubject();

      await tester.pumpWidget(subject);

      expect(find.text('name'), findsOneWidget);
    });

    testWidgets('renders child', (tester) async {
      final subject = buildSubject();

      await tester.pumpWidget(subject);

      expect(find.text('child'), findsOneWidget);
    });

    group('constraints', () {
      testWidgets('when null defaults to inherited constraints', (
        tester,
      ) async {
        const constraints = BoxConstraints(maxWidth: 400);
        final subject = buildSubject();

        await tester.pumpWidget(
          GoldenTestScenarioConstraints(
            constraints: constraints,
            child: subject,
          ),
        );

        final findConstraints = find.ancestor(
          of: find.text('child'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox && widget.constraints == constraints,
          ),
        );

        expect(findConstraints, findsOneWidget);
      });

      testWidgets('constrains the child', (tester) async {
        const constraints = BoxConstraints(maxWidth: 400);
        final subject = buildSubject(constraints: constraints);

        await tester.pumpWidget(subject);

        final findConstraints = find.ancestor(
          of: find.text('child'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox && widget.constraints == constraints,
          ),
        );

        expect(findConstraints, findsOneWidget);
      });

      testWidgets('takes precedence over inherited constraints', (
        tester,
      ) async {
        const constraints = BoxConstraints(maxWidth: 400);
        final subject = buildSubject(constraints: constraints);

        await tester.pumpWidget(
          GoldenTestScenarioConstraints(
            constraints: const BoxConstraints(maxHeight: 400),
            child: subject,
          ),
        );

        final findConstraints = find.ancestor(
          of: find.text('child'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox && widget.constraints == constraints,
          ),
        );

        expect(findConstraints, findsOneWidget);
      });
    });

    testWidgets('.builder constructor provides builder', (tester) async {
      Object? providedContext;

      final subject = GoldenTestScenario.builder(
        name: 'name',
        builder: (context) {
          providedContext = context;
          return const Text('child');
        },
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: subject)));

      expect(providedContext, isNotNull);
      expect(providedContext, isA<BuildContext>());
    });

    testWidgets('.withTextScaleFactor sets correct default textScaler', (
      tester,
    ) async {
      const textScaler = TextScaler.linear(2);
      final subject = GoldenTestScenario.withTextScaleFactor(
        textScaler: textScaler,
        name: 'name',
        child: const Text('child'),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: subject)));

      final element = tester.element(find.text('child'));
      final mediaQuery = MediaQuery.maybeOf(element);

      expect(mediaQuery, isNotNull);
      expect(
        mediaQuery,
        isA<MediaQueryData>().having(
          (m) => m.textScaler,
          'textScaler',
          textScaler,
        ),
      );
    });
  });
}
