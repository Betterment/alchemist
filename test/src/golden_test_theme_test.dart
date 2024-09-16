import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoldenTestTheme', () {
    group('GoldenTestGroup', () {
      Widget buildSubject() {
        return const MaterialApp(
          home: Scaffold(
            body: GoldenTestGroup(
              children: [
                Text('One'),
                Text('Two'),
                Text('Three'),
              ],
            ),
          ),
        );
      }

      group('borderColor', () {
        group('when no override is provided', () {
          testWidgets('it renders as 0xFF3d394a', (tester) async {
            await tester.pumpWidget(buildSubject());

            await tester.pump();

            final box = find.byType(Table);

            expect(
              tester.widget<Table>(box).border?.horizontalInside.color,
              const Color(0xFF3d394a),
            );

            expect(
              tester.widget<Table>(box).border?.verticalInside.color,
              const Color(0xFF3d394a),
            );
          });
        });

        group('when an override is provided', () {
          testWidgets('it renders as the provided color', (tester) async {
            Future<void> runTest() async {
              await tester.pumpWidget(buildSubject());

              await tester.pump();

              final box = find.byType(Table);

              expect(
                tester.widget<Table>(box).border?.horizontalInside.color,
                const Color(0xFF000000),
              );

              expect(
                tester.widget<Table>(box).border?.verticalInside.color,
                const Color(0xFF000000),
              );
            }

            final config = AlchemistConfig.current().copyWith(
              goldenTestTheme: GoldenTestTheme(
                backgroundColor: Colors.green,
                borderColor: const Color(0xFF000000),
              ),
            );

            await AlchemistConfig.runWithConfig(config: config, run: runTest);
          });
        });
      });

      group('backgroundColor', () {
        group('when no override is provided', () {
          testWidgets('it renders as 0xFF2b54a1', (tester) async {
            const adapter = FlutterGoldenTestAdapter();

            await adapter.pumpGoldenTest(
              tester: tester,
              textScaleFactor: 1,
              constraints: const BoxConstraints(),
              obscureFont: true,
              globalConfigTheme: null,
              variantConfigTheme: null,
              goldenTestTheme: null,
              pumpBeforeTest: onlyPumpAndSettle,
              pumpWidget: onlyPumpWidget,
              widget: const Text('Hello'),
            );

            final box = find.ancestor(
              of: find.byType(Text),
              matching: find.byType(ColoredBox),
            );

            expect(
              tester.widget<ColoredBox>(box).color,
              const Color(0xFF2b54a1),
            );
          });
        });

        group('when an override is provided', () {
          testWidgets('it renders as the provided color', (tester) async {
            const adapter = FlutterGoldenTestAdapter();

            await adapter.pumpGoldenTest(
              tester: tester,
              textScaleFactor: 1,
              constraints: const BoxConstraints(),
              obscureFont: true,
              globalConfigTheme: null,
              variantConfigTheme: null,
              goldenTestTheme: GoldenTestTheme(
                backgroundColor: const Color(0xFF000000),
                borderColor: Colors.green,
              ),
              pumpBeforeTest: onlyPumpAndSettle,
              pumpWidget: onlyPumpWidget,
              widget: const Text('Hello'),
            );

            final box = find.ancestor(
              of: find.byType(Text),
              matching: find.byType(ColoredBox),
            );

            expect(
              tester.widget<ColoredBox>(box).color,
              const Color(0xFF000000),
            );
          });
        });
      });
    });
  });
}
