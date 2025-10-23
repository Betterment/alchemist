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
  }) async {
    return MockImage();
  }

  @override
  GoldenFileExpectation get goldenFileExpectation => throw UnimplementedError();

  @override
  Future<void> pumpGoldenTest({
    required WidgetTester tester,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required bool obscureFont,
    required ThemeData? globalConfigTheme,
    required ThemeData? variantConfigTheme,
    required GoldenTestTheme? goldenTestTheme,
    required PumpAction pumpBeforeTest,
    required PumpWidget pumpWidget,
    required Widget widget,
    Key? rootKey,
  }) async {}

  @override
  TestLifecycleFn get setUp =>
      (dynamic Function() body) => body();

  @override
  TestLifecycleFn get tearDown =>
      (dynamic Function() body) => body();

  @override
  TestWidgetsFn get testWidgets =>
      (
        String description,
        Future<void> Function(WidgetTester) callback, {
        bool? skip,
        Timeout? timeout,
        bool semanticsEnabled = true,
        TestVariant<Object?> variant = const DefaultTestVariant(),
        dynamic tags,
        int? retry,
      }) async {
        for (final value in variant.values) {
          await variant.setUp(value);
          await callback(MockWidgetTester());
        }
      };

  @override
  Future<T> withForceUpdateGoldenFiles<T>({
    required MatchesGoldenFileInvocation<T> callback,
    bool forceUpdate = false,
  }) async {
    return callback();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockWidgetTester());
    registerFallbackValue(const SizedBox());
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
      final ciTheme = ThemeData.light().copyWith(primaryColor: Colors.green);
      final platformTheme = ThemeData.light().copyWith(
        primaryColor: Colors.yellow,
      );
      final goldenTestTheme = GoldenTestTheme(
        backgroundColor: Colors.blueGrey,
        borderColor: Colors.orange,
        nameTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: ui.FontWeight.bold,
        ),
      );
      const ciRenderShadows = true;
      final config = AlchemistConfig(
        forceUpdateGoldenFiles: false,
        theme: alchemistTheme,
        goldenTestTheme: goldenTestTheme,
        ciGoldensConfig: CiGoldensConfig(
          theme: ciTheme,
          renderShadows: ciRenderShadows,
          filePathResolver: (fileName, environmentName) async {
            filePathResolverCalled = true;
            return 'myGoldenFile';
          },
        ),
        platformGoldensConfig: PlatformGoldensConfig(
          enabled: false,
          theme: platformTheme,
        ),
      );
      const widget = SizedBox();

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
          globalConfigTheme: alchemistTheme,
          variantConfigTheme: ciTheme,
          goldenTestTheme: goldenTestTheme,
          forceUpdate: any(named: 'forceUpdate'),
          obscureText: any(named: 'obscureText'),
          renderShadows: ciRenderShadows,
          textScaleFactor: any(named: 'textScaleFactor'),
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
          globalConfigTheme: alchemistTheme,
          variantConfigTheme: platformTheme,
          goldenTestTheme: goldenTestTheme,
          forceUpdate: any(named: 'forceUpdate'),
          obscureText: any(named: 'obscureText'),
          renderShadows: any(named: 'renderShadows'),
          textScaleFactor: any(named: 'textScaleFactor'),
          constraints: any(named: 'constraints'),
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
