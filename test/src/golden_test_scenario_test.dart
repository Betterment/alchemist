import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoldenTestScenario', () {
    Widget buildSubject({
      Key? key,
      String name = 'name',
      Widget child = const Text('child'),
    }) {
      return MaterialApp(
        home: Scaffold(
          body: GoldenTestScenario(
            key: key,
            name: name,
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

    testWidgets('.builder constructor provides builder', (tester) async {
      Object? providedContext;

      final subject = GoldenTestScenario.builder(
        name: 'name',
        builder: (context) {
          providedContext = context;
          return const Text('child');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: subject,
          ),
        ),
      );

      expect(providedContext, isNotNull);
      expect(providedContext, isA<BuildContext>());
    });

    testWidgets(
      '.withTextScaleFactor sets correct default text scale factor',
      (tester) async {
        final subject = GoldenTestScenario.withTextScaleFactor(
          textScaleFactor: 2,
          name: 'name',
          child: const Text('child'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: subject,
            ),
          ),
        );

        final element = tester.element(find.text('child'));
        final mediaQuery = MediaQuery.maybeOf(element);

        expect(mediaQuery, isNotNull);
        expect(
          mediaQuery,
          isA<MediaQueryData>().having(
            (m) => m.textScaleFactor,
            'textScaleFactor',
            2.0,
          ),
        );
      },
    );
  });
}
