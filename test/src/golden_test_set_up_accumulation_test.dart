import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockGoldenTestRunner extends Mock implements GoldenTestRunner {}

class MockWidgetTester extends Mock implements WidgetTester {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockWidgetTester());
    registerFallbackValue(const SizedBox());
    registerFallbackValue(const BoxConstraints());
  });

  group('goldenTest setUp accumulation', () {
    // Stores every callback passed to setUp during test registration.
    late List<ValueGetter<dynamic>> registeredSetUpCallbacks;

    // Stores every (variant, callback) pair passed to testWidgets.
    late List<(TestVariant<Object?>, Future<void> Function(WidgetTester))>
    registeredTests;

    late MockGoldenTestRunner runner;

    setUp(() {
      registeredSetUpCallbacks = [];
      registeredTests = [];
      runner = MockGoldenTestRunner();

      // Use the real adapter so goldenTest → adapter.setUp → setUpFn path
      // is exercised.
      goldenTestAdapter = const FlutterGoldenTestAdapter();
      goldenTestRunner = runner;
      hostPlatform = HostPlatform.linux;

      // Intercept setUp: record each callback without registering it in
      // flutter_test's real infrastructure (which would pollute this test).
      setUpFn = (body) {
        registeredSetUpCallbacks.add(body);
      };

      // Intercept testWidgets: record the test but don't execute it yet.
      testWidgetsFn =
          (
            String description,
            Future<void> Function(WidgetTester) callback, {
            bool? skip,
            Timeout? timeout,
            bool semanticsEnabled = true,
            TestVariant<Object?> variant = const DefaultTestVariant(),
            dynamic tags,
            int? retry,
          }) {
            registeredTests.add((variant, callback));
          };

      when(
        () => runner.run(
          tester: any(named: 'tester'),
          goldenPath: any(named: 'goldenPath'),
          widget: any(named: 'widget'),
          globalConfigTheme: any(named: 'globalConfigTheme'),
          variantConfigTheme: any(named: 'variantConfigTheme'),
          goldenTestTheme: any(named: 'goldenTestTheme'),
          forceUpdate: any(named: 'forceUpdate'),
          obscureText: any(named: 'obscureText'),
          renderShadows: any(named: 'renderShadows'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          pumpBeforeTest: any(named: 'pumpBeforeTest'),
          pumpWidget: any(named: 'pumpWidget'),
          whilePerforming: any(named: 'whilePerforming'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      goldenTestAdapter = defaultGoldenTestAdapter;
      goldenTestRunner = defaultGoldenTestRunner;
      hostPlatform = defaultHostPlatform;
      setUpFn = defaultSetUpFn;
      testWidgetsFn = defaultTestWidgetsFn;
    });

    test('goldenTest registers no setUp: each test body sets up', () async {
      const n = 10;
      for (var i = 0; i < n; i++) {
        await goldenTest(
          'test $i',
          fileName: 'test_$i',
          builder: () => const SizedBox(),
        );
      }

      // No setUp: a setUp per call ran N times before each of N tests
      // (O(N²)); one setUp belongs to the first group only. The test body
      // loads the fonts (a no-op once loaded).
      expect(registeredSetUpCallbacks, isEmpty);
      expect(registeredTests, hasLength(n));
    });
  });
}
