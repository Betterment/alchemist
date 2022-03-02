import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWidgetTester extends Mock implements WidgetTester {}

void main() {
  group('Custom pump functions', () {
    late WidgetTester tester;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(EnginePhase.sendSemanticsUpdate);
    });

    setUp(() {
      tester = MockWidgetTester();
      when(() => tester.pump(any(), any())).thenAnswer((_) async {});
      when(() => tester.pumpAndSettle(any(), any(), any()))
          .thenAnswer((_) async => 1);
    });

    group('pumpNTimes', () {
      test('calls pump the given amount of times', () async {
        final pump = pumpNTimes(3);
        await pump(tester);

        verify(() => tester.pump()).called(3);
      });

      test('provides the given duration to the pump call', () async {
        const duration = Duration(milliseconds: 123);
        final pump = pumpNTimes(3, duration);
        await pump(tester);

        verify(() => tester.pump(duration)).called(3);
      });
    });

    group('pumpOnce', () {
      test('calls pump once', () async {
        await pumpOnce(tester);

        verify(() => tester.pump()).called(1);
      });
    });

    group('onlyPumpAndSettle', () {
      test('calls pumpAndSettle', () async {
        await onlyPumpAndSettle(tester);

        verify(() => tester.pumpAndSettle()).called(1);
      });
    });
  });
}
