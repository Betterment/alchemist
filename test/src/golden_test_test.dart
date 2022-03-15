import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImage extends Mock implements ui.Image {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MockImage';
  }
}

class MockGoldenTestRunner extends Mock implements GoldenTestRunner {}

class MockAlchemistConfig extends Mock implements AlchemistConfig {}

class MockWidgetTester extends Mock implements WidgetTester {}

class FakeGoldenTestAdapter extends Mock implements GoldenTestAdapter {
  @override
  Future<ui.Image> getBlockedTextImage({
    required Finder finder,
    required WidgetTester tester,
  }) {
    return Future.value(MockImage());
  }

  @override
  GoldenFileExpectation get goldenFileExpectation => throw UnimplementedError();

  @override
  Future<void> pumpGoldenTest({
    Key? rootKey,
    required WidgetTester tester,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required ThemeData theme,
    required PumpAction pumpBeforeTest,
    required PumpWidget pumpWidget,
    required Widget widget,
  }) {
    return Future.value();
  }

  @override
  TestLifecycleFn get setUp => (dynamic Function() body) => body();

  @override
  TestLifecycleFn get tearDown => (dynamic Function() body) => body();

  @override
  TestWidgetsFn get testWidgets => (
        String description,
        Future<void> Function(WidgetTester) callback, {
        bool? skip,
        Timeout? timeout,
        Duration? initialTimeout,
        bool semanticsEnabled = true,
        TestVariant<Object?> variant = const DefaultTestVariant(),
        dynamic tags,
      }) async {
        for (final value in variant.values) {
          await variant.setUp(value);
          await callback(MockWidgetTester());
        }
      };

  @override
  Future<T> withForceUpdateGoldenFiles<T>({
    bool forceUpdate = false,
    required MatchesGoldenFileInvocation<T> callback,
  }) async {
    return callback();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockWidgetTester());
    registerFallbackValue(Container());
    registerFallbackValue(const BoxConstraints());
  });

  group('goldenTest', () {
    late GoldenTestAdapter adapter;
    late GoldenTestRunner runner;

    setUp(() {
      adapter = FakeGoldenTestAdapter();
      runner = MockGoldenTestRunner();

      goldenTestAdapter = adapter;
      goldenTestRunner = runner;
      hostPlatform = HostPlatform.linux;

      when(
        () => goldenTestRunner.run(
          tester: any(named: 'tester'),
          goldenPath: any(named: 'goldenPath'),
          widget: any(named: 'widget'),
          forceUpdate: any(named: 'forceUpdate'),
          obscureText: any(named: 'obscureText'),
          renderShadows: any(named: 'renderShadows'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          theme: any(named: 'theme'),
          pumpBeforeTest: any(named: 'pumpBeforeTest'),
          pumpWidget: any(named: 'pumpWidget'),
          whilePerforming: any(named: 'whilePerforming'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      verifyNoMoreInteractions(runner);
    });

    testWidgets('asserts filename does not end in .png', (tester) async {
      await expectLater(
        goldenTest(
          'golden test test',
          fileName: 'test.png',
          builder: () => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('invokes goldenTestRunner correctly', (tester) async {
      var filePathResolverCalled = false;
      final alchemistTheme = ThemeData.light().copyWith(
        primaryColor: Colors.red,
      );
      final ciTheme = ThemeData.light().copyWith(primaryColor: Colors.blue);
      const ciRenderShadows = true;
      final config = AlchemistConfig(
        forceUpdateGoldenFiles: false,
        theme: alchemistTheme,
        ciGoldensConfig: CiGoldensConfig(
          theme: ciTheme,
          renderShadows: ciRenderShadows,
          filePathResolver: (fileName, environmentName) async {
            filePathResolverCalled = true;
            return 'myGoldenFile';
          },
        ),
        platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      );
      final widget = Container();
      await AlchemistConfig.runWithConfig(
        config: config,
        run: () async => goldenTest(
          'test golden test',
          fileName: 'test_golden_test',
          builder: () => widget,
        ),
      );
      expect(filePathResolverCalled, isTrue);
      // Verify [GoldenTestRunner.run] was called for the CI config.
      verify(
        () => runner.run(
          tester: any(named: 'tester'),
          goldenPath: 'myGoldenFile',
          widget: widget,
          forceUpdate: any(named: 'forceUpdate'),
          obscureText: any(named: 'obscureText'),
          renderShadows: ciRenderShadows,
          textScaleFactor: any(named: 'textScaleFactor'),
          theme: ciTheme,
          pumpBeforeTest: any(named: 'pumpBeforeTest'),
          pumpWidget: any(named: 'pumpWidget'),
          whilePerforming: any(named: 'whilePerforming'),
        ),
      ).called(1);
      // Verify [GoldenTestRunner.run] was not called for the platform config.
      verifyNever(
        () => runner.run(
          tester: any(named: 'tester'),
          goldenPath: 'goldens/linux/test_golden_test.png',
          widget: widget,
          forceUpdate: any(named: 'forceUpdate'),
          obscureText: any(named: 'obscureText'),
          renderShadows: any(named: 'renderShadows'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
          theme: alchemistTheme,
          pumpBeforeTest: any(named: 'pumpBeforeTest'),
          pumpWidget: any(named: 'pumpWidget'),
          whilePerforming: any(named: 'whilePerforming'),
        ),
      );
    });

    tearDownAll(() {
      goldenTestAdapter = defaultGoldenTestAdapter;
      goldenTestRunner = defaultGoldenTestRunner;
      hostPlatform = defaultHostPlatform;
    });
  });
}
