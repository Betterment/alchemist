import 'dart:async';
import 'dart:ui' as ui;

import 'package:alchemist/src/alchemist_file_comparator.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAdapter extends Mock implements GoldenTestAdapter {}

class MockUiImage extends Mock implements ui.Image {}

class MockWidgetTester extends Mock implements WidgetTester {}

class _FakeGoldenFileComparator extends Fake implements GoldenFileComparator {}

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
          goldenTestTheme: any(named: 'goldenTestTheme'),
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
        // Simulate a test failure.
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
      } on TestFailure catch (e) {
        expect(e, isA<TestFailure>());
      }
    });

    testWidgets('renderShadows sets debugDisableShadows correctly '
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

    testWidgets(
      'installs AlchemistFileComparator when diffThreshold > 0 and comparator '
      'is LocalFileComparator',
      (tester) async {
        final originalComparator = LocalFileComparator(
          Uri.parse('file:///test/golden_test.dart'),
        );
        goldenFileComparator = originalComparator;

        GoldenFileComparator? comparatorDuringTest;
        when(
          () => goldenTestAdapter.withForceUpdateGoldenFiles<void>(
            callback: any(named: 'callback'),
          ),
        ).thenAnswer((invocation) async {
          comparatorDuringTest = goldenFileComparator;
          await (invocation.namedArguments[#callback]
                  as MatchesGoldenFileInvocation<void>)
              .call();
        });

        await goldenTestRunner.run(
          tester: tester,
          goldenPath: 'path/to/golden',
          widget: const SizedBox(),
          diffThreshold: 0.001,
        );

        expect(comparatorDuringTest, isA<AlchemistFileComparator>());
        expect(
          (comparatorDuringTest! as AlchemistFileComparator).diffThreshold,
          0.001,
        );
        expect(goldenFileComparator, same(originalComparator));
      },
    );

    testWidgets('restores original comparator after test throws', (
      tester,
    ) async {
      final originalComparator = LocalFileComparator(
        Uri.parse('file:///test/golden_test.dart'),
      );
      goldenFileComparator = originalComparator;

      final givenException = Exception('test error');
      when(
        () => goldenTestAdapter.withForceUpdateGoldenFiles<void>(
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((_) async => throw givenException);

      await expectLater(
        goldenTestRunner.run(
          tester: tester,
          goldenPath: 'path/to/golden',
          widget: const SizedBox(),
          diffThreshold: 0.001,
        ),
        throwsA(same(givenException)),
      );

      expect(goldenFileComparator, same(originalComparator));
    });

    testWidgets('does not change comparator when diffThreshold is 0', (
      tester,
    ) async {
      final originalComparator = LocalFileComparator(
        Uri.parse('file:///test/golden_test.dart'),
      );
      goldenFileComparator = originalComparator;

      GoldenFileComparator? comparatorDuringTest;
      when(
        () => goldenTestAdapter.withForceUpdateGoldenFiles<void>(
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((invocation) async {
        comparatorDuringTest = goldenFileComparator;
        await (invocation.namedArguments[#callback]
                as MatchesGoldenFileInvocation<void>)
            .call();
      });

      await goldenTestRunner.run(
        tester: tester,
        goldenPath: 'path/to/golden',
        widget: const SizedBox(),
      );

      expect(comparatorDuringTest, same(originalComparator));
    });

    testWidgets(
      'throws UnsupportedError when diffThreshold > 0 and comparator is not '
      'LocalFileComparator',
      (tester) async {
        goldenFileComparator = _FakeGoldenFileComparator();

        await expectLater(
          goldenTestRunner.run(
            tester: tester,
            goldenPath: 'path/to/golden',
            widget: const SizedBox(),
            diffThreshold: 0.001,
          ),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

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
          goldenTestTheme: any(named: 'goldenTestTheme'),
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

    tearDownAll(() {
      goldenTestAdapter = defaultGoldenTestAdapter;
    });
  });
}
