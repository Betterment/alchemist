import 'dart:convert';
import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/alchemist_test_variant.dart';
import 'package:alchemist/src/golden_test_runner.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

final Set<String> _loadedFontFamilies = {};

/// Default golden test runner which uses the flutter test framework.
const defaultGoldenTestRunner = FlutterGoldenTestRunner();
GoldenTestRunner _goldenTestRunner = defaultGoldenTestRunner;

/// Golden test runner. Overriding this makes it easier to unit-test Alchemist.
GoldenTestRunner get goldenTestRunner => _goldenTestRunner;
set goldenTestRunner(GoldenTestRunner value) => _goldenTestRunner = value;

/// An internal function that executes all necessary setup steps required to run
/// golden tests.
Future<void> _setUpGoldenTests() async {
  await loadFonts();

  RenderErrorBox.textStyle = ui.TextStyle(fontFamily: 'Roboto');
}

/// Loads a font for use in golden tests.
///
/// Do not use this method directly. This method is used internally by the
/// [goldenTest] method in its setup phase.
@protected
@visibleForTesting
Future<void> loadFonts() async {
  final bundle = rootBundle;
  final fontManifestString = await bundle.loadString('FontManifest.json');
  final fontManifest = (json.decode(fontManifestString) as List<dynamic>).map(
    (dynamic x) => x as Map<String, dynamic>,
  );

  for (final entry in fontManifest) {
    final family = (entry['family'] as String)
        .stripFontFamilyAlchemistPackageName();

    // Skip if font family is already loaded
    if (_loadedFontFamilies.contains(family)) {
      continue;
    }

    final fontAssets = [
      for (final fontAssetEntry in entry['fonts'] as List<dynamic>)
        (fontAssetEntry as Map<String, dynamic>)['asset'] as String,
    ];

    final loader = FontLoader(family);
    for (final fontAsset in fontAssets) {
      loader.addFont(bundle.load(fontAsset));
    }

    await loader.load();
    _loadedFontFamilies.add(family);
  }
}

/// Performs a Flutter widget test that compares against golden image.
///
/// This function will perform the required setup and tear down for golden
/// tests. On all platforms, the golden test images will have their text
/// converted to black boxes in order to ensure compatibility between all
/// platforms. However, when running golden tests on macOS, a second set of
/// test images will be generated and compared that contain the raw text as-is.
/// This is because macOS renders text differently than other platforms, which
/// results in inconsistencies in generated golden files between macOS and other
/// platforms.
///
/// Golden tests are run alongside other tests, and can be run using
/// `flutter test`. To update the golden files, after changing the look of a
/// particular widget for example, use `flutter test --update-goldens`.
///
/// The [fileName] is the name of the file that will be used to store the
/// golden image under the `goldens` directory. This name should be unique, and
/// may not contain an extension (such as `.png`).
///
/// The provided [builder] builds the widget under test.
/// Usually, it creates multiple scenarios using [GoldenTestGroup]
/// and [GoldenTestScenario].
///
/// The [description] must be a unique description for the test.
///
/// The [skip] argument is used to determine if the test should be skipped.
///
/// A list of [tags] can be provided to help identify the test and
/// programmatically filter it when running `flutter test`. By default, a single
/// `'golden'` tag is added to the test (meaning these tests can be excluded by
/// running `flutter test --exclude-tags golden`, or
/// `flutter test --tags golden` to *only* run golden tests).
///
/// The [textScaleFactor], if provided, sets the text scale size (usually in
/// a range from 1 to 3).
///
/// The [constraints] tell the builder how large the rendered widget should be.
/// Commonly set to `BoxConstraints.loose(Size(maxWidth, maxHeight))` to limit
/// the maximum size of the widget, while allowing it to be smaller if the
/// content allows for it.
///
/// By default, no constraints are passed, but this can be
/// adjusted to allow for more precise rendering of golden files.
///
/// The [pumpBeforeTest] function will be called with the [WidgetTester] to
/// prime the widget tree before golden evaluation. By default, it is set to
/// [onlyPumpAndSettle], which will pump the widget tree and wait for all
/// scheduled frames to be completed, but can be overridden to customize the
/// pump behavior.
/// See [pumpOnce], [pumpNTimes], [onlyPumpAndSettle], and [precacheImages] for
/// more details.
///
/// A custom [pumpWidget] function can be provided, which will override the
/// default behavior and allow the widget being tested to be wrapped in any
/// number of widgets, and then pumped. By default, it is set to simply pump the
/// provided widget once. See [onlyPumpWidget] for more details.
///
/// The [whilePerforming] interaction, if provided, will be called with the
/// [WidgetTester] to perform a desired interaction during the golden test.
/// Built-in actions, such as [press] and [longPress] are available, which
/// press and long press the appropriate buttons, respectively. Each
/// built-in interaction receives a finder indicating all of the widgets
/// that should be interacted with.
///
/// The [testWrapper] is needed to wrap the test zone to another during the test
/// For example, when you need to use `runWithClock` inside goldens
/// ```dart
/// goldenTest(
///   ...
///   wrapper: (callback) async => withClock<void>(
///     Clock.fixed(DateTime(2025, 12, 10)),
///     callback,
///   )
/// ```
///
/// **Note**: If a built-in [whilePerforming] interaction is provided, the
/// widget tree is **always** pumped at least once before the assertion phase
/// of the test.
///
/// **Note:** If any matched widget does not respond to a press or long
/// press interaction, all other gestures will fail, rendering the
/// [whilePerforming] argument useless.
@isTest
Future<void> goldenTest(
  String description, {
  required String fileName,
  required ValueGetter<Widget> builder,
  bool skip = false,
  List<String> tags = const ['golden'],
  double textScaleFactor = 1.0,
  BoxConstraints constraints = const BoxConstraints(),
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
  PumpWidget pumpWidget = onlyPumpWidget,
  Interaction? whilePerforming,
  Future<void> Function(Future<void> Function() callback)? testWrapper,
}) async {
  if (skip) return;

  assert(
    !fileName.endsWith('.png'),
    'Golden tests file names should not include file type extension.\n\n'
    'This logic should be handled in the [filePathResolver] function of the '
    '[PlatformGoldensConfig] and [CiGoldensConfig] classes in '
    '[AlchemistConfig].',
  );

  final config = AlchemistConfig.current();

  final currentPlatform = HostPlatform.current();
  final variant = AlchemistTestVariant(
    config: config,
    currentPlatform: currentPlatform,
  );

  goldenTestAdapter.setUp(_setUpGoldenTests);

  await goldenTestAdapter.testWidgets(
    description,
    (tester) async {
      Future<void> callback() async {
        final variantConfig = variant.currentConfig;
        await goldenTestRunner.run(
          tester: tester,
          goldenPath: await variantConfig.filePathResolver(
          fileName,
          variantConfig.environmentName,
        ),
        widget: builder(),
        globalConfigTheme: config.theme,
        variantConfigTheme: variantConfig.theme,
        goldenTestTheme: config.goldenTestTheme,
        forceUpdate: config.forceUpdateGoldenFiles,
        obscureText: variantConfig.obscureText,
        renderShadows: variantConfig.renderShadows,
        textScaleFactor: textScaleFactor,
        constraints: constraints,
        pumpBeforeTest: pumpBeforeTest,
        pumpWidget: pumpWidget,
        whilePerforming: whilePerforming,
        );
      }

      if (testWrapper != null) {
        await testWrapper(callback);
      } else {
        await callback();
      }

    },
    tags: tags,
    variant: variant,
  );
}
