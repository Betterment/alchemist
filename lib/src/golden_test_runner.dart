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

/// Font family used to render blocked/obscured text.
///
/// Even when replacing text with black rectangles, the same font
/// must be used across the widget to avoid issues with different fonts
/// having different character dimensions.
const obscuredTextFontFamily = 'Ahem';

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
    bool forceUpdate = false,
    bool obscureText = false,
    bool renderShadows = false,
    double textScaleFactor = 1.0,
    BoxConstraints constraints = const BoxConstraints(),
    ThemeData? theme,
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
    bool forceUpdate = false,
    bool obscureText = false,
    bool renderShadows = false,
    double textScaleFactor = 1.0,
    BoxConstraints constraints = const BoxConstraints(),
    ThemeData? theme,
    PumpAction pumpBeforeTest = onlyPumpAndSettle,
    PumpWidget pumpWidget = onlyPumpWidget,
    Interaction? whilePerforming,
  }) async {
    assert(
      goldenPath is String || goldenPath is Uri,
      'Golden path must be a String or Uri.',
    );

    final themeData = theme ?? ThemeData.light();
    final rootKey = FlutterGoldenTestAdapter.rootKey;

    final mementoDebugDisableShadows = debugDisableShadows;
    debugDisableShadows = !renderShadows;

    try {
      await goldenTestAdapter.pumpGoldenTest(
        tester: tester,
        rootKey: rootKey,
        textScaleFactor: textScaleFactor,
        constraints: constraints,
        pumpBeforeTest: pumpBeforeTest,
        pumpWidget: pumpWidget,
        widget: widget,
        theme: themeData.copyWith(
          textTheme: obscureText
              ? themeData.textTheme.apply(
                  fontFamily: obscuredTextFontFamily,
                )
              : themeData.textTheme,
        ),
      );

      AsyncCallback? cleanup;
      if (whilePerforming != null) {
        cleanup = await whilePerforming(tester);
      }

      final root = find.byKey(rootKey);

      final toMatch = obscureText
          ? goldenTestAdapter.getBlockedTextImage(
              finder: root,
              tester: tester,
            )
          : root;

      try {
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
    }
  }
}
