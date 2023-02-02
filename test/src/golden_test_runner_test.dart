import 'dart:async';
import 'dart:ui' as ui;

import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdapter extends Mock implements GoldenTestAdapter {}

class MockUiImage extends Mock implements ui.Image {}

class MockWidgetTester extends Mock implements WidgetTester {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockWidgetTester());
    registerFallbackValue(const BoxConstraints());
    registerFallbackValue(ThemeData.light());
    registerFallbackValue(const SizedBox());
    registerFallbackValue(find.byType(Widget));
  });

  group('Overrides', () {
    group('adapter', () {
      late MockAdapter adapter;

      setUp(() {
        adapter = MockAdapter();
        goldenTestAdapter = adapter;
      });

      test('overrides value', () {
        expect(goldenTestAdapter, adapter);
      });

      tearDown(() {
        goldenTestAdapter = defaultGoldenTestAdapter;
      });
    });
  });

  group('GoldenTestRunner', () {
    const goldenTestRunner = FlutterGoldenTestRunner();
    late MockAdapter adapter;

    setUp(() {
      adapter = MockAdapter();
      goldenTestAdapter = adapter;

      when(
        () => goldenTestAdapter.pumpGoldenTest(
          rootKey: any(named: 'rootKey'),
          tester: any(named: 'tester'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          obscureFont: any(named: 'obscureFont'),
          variantConfigTheme: any(named: 'variantConfigTheme'),
          globalConfigTheme: any(named: 'globalConfigTheme'),
          pumpBeforeTest: any(named: 'pumpBeforeTest'),
          pumpWidget: any(named: 'pumpWidget'),
          widget: any(named: 'widget'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => goldenTestAdapter.getBlockedTextImage(
          finder: any(named: 'finder'),
          tester: any(named: 'tester'),
        ),
      ).thenAnswer((_) async => MockUiImage());

      when(
        () => goldenTestAdapter.goldenFileExpectation,
      ).thenReturn((_, __) => () async {});

      when(
        () => goldenTestAdapter.withForceUpdateGoldenFiles<void>(
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((invocation) async {
        // Invoke the given callback.
        await (invocation.namedArguments[#callback]
                as MatchesGoldenFileInvocation<void>)
            .call();
      });
    });

    tearDownAll(() {
      goldenTestAdapter = defaultGoldenTestAdapter;
    });

    testWidgets('throws on invalid golden path type', (tester) async {
      await expectLater(
        goldenTestRunner.run(
          tester: tester,
          goldenPath: 1,
          widget: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('throws when matcher fails', (tester) async {
      FutureOr<void> matcherInvocation() {
        // ignore: only_throw_errors
        throw TestFailure('simulated failure');
      }

      MatchesGoldenFileInvocation<void> goldenFileExpectation(
        Object a,
        Object b,
      ) {
        return matcherInvocation;
      }

      when(
        () => goldenTestAdapter.goldenFileExpectation,
      ).thenReturn(goldenFileExpectation);

      try {
        await goldenTestRunner.run(
          tester: tester,
          goldenPath: 'path/to/golden',
          widget: const SizedBox(),
        );
        fail('Expected goldenTestRunner.run to throw TestFailure');
      } catch (e) {
        expect(e, isA<TestFailure>());
      }
    });

    testWidgets(
        'renderShadows sets debugDisableShadows correctly '
        'and resets it after the test has run', (tester) async {
      late final bool debugDisableShadowsDuringTestRun;

      final givenException = Exception();
      await expectLater(
        goldenTestRunner.run(
          tester: tester,
          goldenPath: 'path/to/golden',
          renderShadows: true,
          widget: const SizedBox(),
          whilePerforming: (_) {
            debugDisableShadowsDuringTestRun = debugDisableShadows;
            throw givenException;
          },
        ),
        throwsA(same(givenException)),
      );

      expect(debugDisableShadows, isTrue);
      expect(debugDisableShadowsDuringTestRun, isFalse);
    });

    testWidgets('resets window size after the test has run', (tester) async {
      late final Size sizeDuringTestRun;
      final originalSize = tester.view.physicalSize;
      when(
        () => goldenTestAdapter.pumpGoldenTest(
          rootKey: any(named: 'rootKey'),
          tester: any(named: 'tester'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          pumpBeforeTest: any(named: 'pumpBeforeTest'),
          pumpWidget: any(named: 'pumpWidget'),
          widget: any(named: 'widget'),
          obscureFont: any(named: 'obscureFont'),
          globalConfigTheme: any(named: 'globalConfigTheme'),
          variantConfigTheme: any(named: 'variantConfigTheme'),
        ),
      ).thenAnswer((_) async {
        tester.view.physicalSize = Size.zero;
      });

      final givenException = Exception();
      await expectLater(
        goldenTestRunner.run(
          tester: tester,
          goldenPath: 'path/to/golden',
          renderShadows: true,
          widget: const SizedBox.square(dimension: 200),
          whilePerforming: (testerDuringTestRun) {
            sizeDuringTestRun = testerDuringTestRun.view.physicalSize;
            throw givenException;
          },
        ),
        throwsA(same(givenException)),
      );

      expect(tester.view.physicalSize, originalSize);
      expect(sizeDuringTestRun, Size.zero);
    });

    group('attempts to set file comparator and', () {
      test(
        'succeeds when existing comparator is a '
        'LocalFileComparator',
        () {
          // TODO(jeroen-meijer): Write test.
        },
      );

      test(
        'succeeds when existing comparator is a '
        'AlchemistFileComparator',
        () {
          // TODO(jeroen-meijer): Write test.
        },
      );

      test('fails when existing comparator is not recognized', () {
        // TODO(jeroen-meijer): Write test.
      });
    });
  });
}
