import 'package:alchemist/src/alchemist_file_comparator.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/interactions.dart';
import 'package:alchemist/src/pumps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default golden test adapter used to interface with Flutter's testing
/// framework.
GoldenTestAdapter defaultGoldenTestAdapter = const FlutterGoldenTestAdapter();
GoldenTestAdapter _goldenTestAdapter = defaultGoldenTestAdapter;

/// Golden test adapter used to interface with Flutter's test framework.
/// Overriding this makes it easier to unit-test Alchemist.
GoldenTestAdapter get goldenTestAdapter => _goldenTestAdapter;
set goldenTestAdapter(GoldenTestAdapter value) => _goldenTestAdapter = value;

/// {@template golden_test_runner}
/// A utility class for running an individual golden test.
/// {@endtemplate}
abstract class GoldenTestRunner {
  /// {@macro golden_test_runner}
  const GoldenTestRunner();

  /// Runs a single golden test expectation.
  Future<void> run({
    required WidgetTester tester,
    required Object goldenPath,
    required Widget widget,
    required ThemeData? globalConfigTheme,
    required ThemeData? variantConfigTheme,
    bool forceUpdate = false,
    bool obscureText = false,
    bool renderShadows = false,
    double tolerance = 0.0,
    double textScaleFactor = 1.0,
    BoxConstraints constraints = const BoxConstraints(),
    PumpAction pumpBeforeTest = onlyPumpAndSettle,
    PumpWidget pumpWidget = onlyPumpWidget,
    Interaction? whilePerforming,
  });
}

/// {@template flutter_golden_test_runner}
/// A [GoldenTestRunner] which uses the Flutter test framework to execute
/// a golden test.
/// {@endtemplate}
class FlutterGoldenTestRunner extends GoldenTestRunner {
  /// {@macro flutter_golden_test_runner}
  const FlutterGoldenTestRunner() : super();

  @override
  Future<void> run({
    required WidgetTester tester,
    required Object goldenPath,
    required Widget widget,
    ThemeData? globalConfigTheme,
    ThemeData? variantConfigTheme,
    bool forceUpdate = false,
    bool obscureText = false,
    bool renderShadows = false,
    double tolerance = 0.0,
    double textScaleFactor = 1.0,
    BoxConstraints constraints = const BoxConstraints(),
    PumpAction pumpBeforeTest = onlyPumpAndSettle,
    PumpWidget pumpWidget = onlyPumpWidget,
    Interaction? whilePerforming,
  }) async {
    assert(
      goldenPath is String || goldenPath is Uri,
      'Golden path must be a String or Uri.',
    );

    final rootKey = FlutterGoldenTestAdapter.rootKey;

    final mementoDebugDisableShadows = debugDisableShadows;
    debugDisableShadows = !renderShadows;

    try {
      await goldenTestAdapter.pumpGoldenTest(
        tester: tester,
        rootKey: rootKey,
        textScaleFactor: textScaleFactor,
        constraints: constraints,
        obscureFont: obscureText,
        globalConfigTheme: globalConfigTheme,
        variantConfigTheme: variantConfigTheme,
        pumpBeforeTest: pumpBeforeTest,
        pumpWidget: pumpWidget,
        widget: widget,
      );

      AsyncCallback? cleanup;
      if (whilePerforming != null) {
        cleanup = await whilePerforming(tester);
      }

      final finder = find.byKey(rootKey);

      final toMatch = obscureText
          ? goldenTestAdapter.getBlockedTextImage(
              finder: finder,
              tester: tester,
            )
          : finder;

      try {
        _attemptSetComparator(tolerance);

        await goldenTestAdapter.withForceUpdateGoldenFiles(
          forceUpdate: forceUpdate,
          callback:
              goldenTestAdapter.goldenFileExpectation(toMatch, goldenPath),
        );
        await cleanup?.call();
      } on TestFailure {
        rethrow;
      }
    } finally {
      debugDisableShadows = mementoDebugDisableShadows;

      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }

  void _attemptSetComparator(double tolerance) {
    if (goldenFileComparator is LocalFileComparator) {
      goldenFileComparator = AlchemistFileComparator.fromLocalFileComparator(
        goldenFileComparator as LocalFileComparator,
        tolerance: tolerance,
      );
    } else if (goldenFileComparator is AlchemistFileComparator) {
      goldenFileComparator = AlchemistFileComparator(
        basedir: (goldenFileComparator as AlchemistFileComparator).basedir,
        tolerance: tolerance,
      );
    } else {
      throw Exception(
        '''
Failed to set AlchemistFileComparator as the goldenFileComparator.

Since this test has a tolerance value above 0.0, Alchemist must set a custom
comparator to allow for matching goldens with a tolerance value.
However, the current goldenFileComparator is not a LocalFileComparator or
AlchemistFileComparator. Instead, it is a ${goldenFileComparator.runtimeType}.

Alchemist can only set a custom comparator if the current comparator is a
LocalFileComparator or AlchemistFileComparator. User-provided comparators
are currently not supported.

If you believe this is a bug, please file an issue at
  https://github.com/Betterment/alchemist/issues
''',
      );
    }
  }
}
