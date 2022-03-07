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
    registerFallbackValue<WidgetTester>(MockWidgetTester());
    registerFallbackValue<BoxConstraints>(const BoxConstraints());
    registerFallbackValue<ThemeData>(ThemeData.light());
    registerFallbackValue<Widget>(const SizedBox.square());
    registerFallbackValue<Finder>(find.byType(Widget));
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
    var pumpBeforeTestCalled = false;
    var cleanupCalled = false;
    var interactionCalled = false;
    var goldenFileExpectationCalled = false;
    var matcherInvocationCalled = false;

    Future<void> pumpBeforeTest(WidgetTester tester) async {
      pumpBeforeTestCalled = true;
    }

    Future<void> cleanup() async {
      cleanupCalled = true;
    }

    Future<Future<void> Function()> interaction(WidgetTester tester) async {
      interactionCalled = true;
      return cleanup;
    }

    FutureOr<void> matcherInvocation() {
      matcherInvocationCalled = true;
    }

    MatchesGoldenFileInvocation<void> goldenFileExpectation(
      Object a,
      Object b,
    ) {
      goldenFileExpectationCalled = true;
      return matcherInvocation;
    }

    setUp(() {
      adapter = MockAdapter();
      goldenTestAdapter = adapter;

      pumpBeforeTestCalled = false;
      cleanupCalled = false;
      interactionCalled = false;
      goldenFileExpectationCalled = false;
      matcherInvocationCalled = false;

      when(
        () => goldenTestAdapter.pumpGoldenTest(
          rootKey: any(named: 'rootKey'),
          tester: any(named: 'tester'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          theme: any(named: 'theme'),
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
      ).thenReturn(goldenFileExpectation);

      when(
        () => goldenTestAdapter.withForceUpdateGoldenFiles(
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((invocation) async {
        // Invoke the given callback.
        await (invocation.namedArguments[#callback]
                as MatchesGoldenFileInvocation<void>)
            .call();
        return;
      });
    });

    testWidgets('throws on invalid golden path type', (tester) async {
      await expectLater(
        goldenTestRunner.run(
          tester: tester,
          goldenPath: 1,
          widget: Container(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('invokes everything correctly', (tester) async {
      const themeColor = Colors.blue;
      final theme = ThemeData.light().copyWith(
        primaryColor: themeColor,
      );
      await goldenTestRunner.run(
        tester: tester,
        goldenPath: 'path/to/golden',
        widget: Container(),
        theme: theme,
        pumpBeforeTest: pumpBeforeTest,
        whilePerforming: interaction,
        obscureText: true,
      );

      expect(pumpBeforeTestCalled, isTrue);
      expect(interactionCalled, isTrue);
      expect(cleanupCalled, isTrue);
      expect(goldenFileExpectationCalled, isTrue);
      expect(matcherInvocationCalled, isTrue);

      final capturedTheme = verify(
        () => adapter.pumpGoldenTest(
          rootKey: any(named: 'rootKey'),
          tester: any(named: 'tester'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          theme: captureAny(named: 'theme'),
          widget: any(named: 'widget'),
        ),
      ).captured.first as ThemeData;

      expect(
        capturedTheme,
        isA<ThemeData>().having(
          (theme) => theme.primaryColor,
          'primaryColor',
          themeColor,
        ),
      );

      expect(
        capturedTheme,
        isA<ThemeData>().having(
          (theme) => theme.textTheme.bodyText1!.fontFamily,
          'textTheme.bodyText1!.fontFamily',
          obscuredTextFontFamily,
        ),
      );
    });

    testWidgets('invokes everything with defaults', (tester) async {
      await goldenTestRunner.run(
        tester: tester,
        goldenPath: 'path/to/golden',
        widget: Container(),
      );

      expect(pumpBeforeTestCalled, isFalse);
      expect(interactionCalled, isFalse);
      expect(cleanupCalled, isFalse);
      expect(goldenFileExpectationCalled, isTrue);
      expect(matcherInvocationCalled, isTrue);

      final capturedTheme = verify(
        () => adapter.pumpGoldenTest(
          rootKey: any(named: 'rootKey'),
          tester: any(named: 'tester'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          theme: captureAny(named: 'theme'),
          widget: any(named: 'widget'),
        ),
      ).captured.first as ThemeData;

      expect(capturedTheme, equals(ThemeData.light()));
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
          widget: Container(),
        );
        fail('Expected goldenTestRunner.run to throw TestFailure');
      } catch (e) {
        expect(e, isA<TestFailure>());
      }
    });

    tearDownAll(() {
      goldenTestAdapter = defaultGoldenTestAdapter;
    });
  });
}
