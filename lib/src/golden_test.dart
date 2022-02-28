import 'dart:convert';

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// An internal function that executes all necessary setup steps required to run
/// golden tests.
Future<void> _setUpGoldenTests() async {
  await loadFontsForTesting();
}

/// Loads a font for use in golden tests.
///
/// Do not use this method directly. This method is used internally by the
/// [goldenTest] method in its setup phase.
@protected
@visibleForTesting
Future<void> loadFontsForTesting() async {
  final bundle = rootBundle;
  final fontManifestString = await bundle.loadString('FontManifest.json');
  final fontManifest = (json.decode(fontManifestString) as List<dynamic>)
      .map((dynamic x) => x as Map<String, dynamic>);

  for (final entry in fontManifest) {
    final family = entry['family'] as String;

    final fontAssets = [
      for (final fontAssetEntry in entry['fonts'] as List<dynamic>)
        (fontAssetEntry as Map<String, dynamic>)['asset'] as String,
    ];

    final loader = FontLoader(family);
    for (final fontAsset in fontAssets) {
      loader.addFont(bundle.load(fontAsset));
    }

    await loader.load();
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
/// The provided [widget] describes the scenarios and layout of the widgets that
/// are included in the test. A child must be provided. Alchemist provides two
/// widgets to make creating a golden test scenario. See [GoldenTestGroup] and
/// [GoldenTestScenario] for more details.
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
/// The [constraints] tell the builder how large the total surface of the
/// widget should be. Commonly set to
/// `BoxConstraints.loose(Size(maxWidth, maxHeight))` to limit the maximum
/// size of the widget, while allowing it to be smaller if the content allows
/// for it.
///
/// By default, no constraints are passed, but this can be
/// adjusted to allow for more precise rendering of golden files. If the
/// max width is unbounded, a default width value will be used as initial
/// surface size. The same applies to the max height.
///
/// The [pumpBeforeTest] function will be called with the [WidgetTester] to
/// prime the widget tree before golden evaluation. By default, it is set to
/// [onlyPumpAndSettle], which will pump the widget tree and wait for all
/// scheduled frames to be completed, but can be overridden to customize the
/// pump behavior. For example, a button tap can be simulated using
/// `tester.tap(finder)`, after which the tester can be pumped and settled.
/// See [pumpOnce], [pumpNTimes] and [onlyPumpAndSettle] for more details.
///
/// The [whilePerforming] interaction, if provided, will be called with the
/// [WidgetTester] to perform a desired interaction during the golden test.
/// Built-in actions, such as [press] and [longPress] are available, which
/// press and long press the appropriate buttons, respectively. Each
/// built-in interaction receives a finder indicating all of the widgets
/// that should be interacted with.
///
/// **Note**: If a built-in [whilePerforming] interaction is provided, the
/// widget tree is **always** pumped at least once before the assertion phase
/// of the test.
///
/// **Note:** If any matched widget does not respond to a press or long
/// press interaction, all other gestures will fail, rendering the
/// [whilePerforming] argument useless.
@isTest
void goldenTest(
  String description, {
  required String fileName,
  bool skip = false,
  List<String> tags = const ['golden'],
  double textScaleFactor = 1.0,
  BoxConstraints constraints = const BoxConstraints(),
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
  Interaction? whilePerforming,
  required Widget widget,
}) {
  assert(
    !fileName.endsWith('.png'),
    '''
Golden tests file names should not include file type extension.

This logic should be handled in the [filePathResolver] function of the
[PlatformGoldensConfig] and [CiGoldensConfig] classes in [AlchemistConfig].''',
  );

  final config = AlchemistConfig.current();

  if (!skip) {
    config.adapter.setUp(_setUpGoldenTests);
  }

  final currentPlatform = HostPlatform.current();
  final variant = AlchemistTestVariant(
    config: config,
    currentPlatform: currentPlatform,
  );
  final goldensConfig = variant.currentConfig;

  testWidgetsFn(
    description,
    (tester) async => runGoldenTest(
      tester: tester,
      adapter: config.adapter,
      forceUpdate: config.forceUpdateGoldenFiles,
      shouldCompare: await goldensConfig.comparePredicate(fileName),
      obscureText: goldensConfig.obscureText,
      goldenKey: await goldensConfig.filePathResolver(fileName),
      textScaleFactor: textScaleFactor,
      constraints: constraints,
      theme: goldensConfig.theme ?? config.theme ?? ThemeData.light(),
      pumpBeforeTest: pumpBeforeTest,
      whilePerforming: whilePerforming,
      widget: widget,
    ),
    skip: skip,
    tags: tags,
    variant: variant,
  );
}

/// Runs a single golden test expectation.
@protected
@visibleForTesting
Future<void> runGoldenTest({
  required WidgetTester tester,
  required GoldenTestAdapter adapter,
  required Object goldenKey,
  required Widget widget,
  bool forceUpdate = false,
  bool shouldCompare = true,
  bool obscureText = false,
  double textScaleFactor = 1.0,
  BoxConstraints constraints = const BoxConstraints(),
  ThemeData? theme,
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
  Interaction? whilePerforming,
}) async {
  assert(
    goldenKey is String || goldenKey is Uri,
    'Golden key must be a String or Uri.',
  );

  final themeData = theme ?? ThemeData.light();
  const rootKey = Key('golden-test-root');

  await tester.pumpGoldenTest(
    rootKey: rootKey,
    textScaleFactor: textScaleFactor,
    constraints: constraints,
    theme: themeData.copyWith(
      textTheme: obscureText
          ? themeData.textTheme.apply(
              fontFamily: 'Ahem',
            )
          : themeData.textTheme,
    ),
    widget: widget,
  );

  await pumpBeforeTest(tester);

  AsyncCallback? cleanup;
  if (whilePerforming != null) {
    cleanup = await whilePerforming(tester);
  }

  final root = find.byKey(rootKey);
  final toMatch = !obscureText ? root : tester.getBlockedTextImage(root);

  try {
    await adapter.withForceUpdateGoldenFiles(
      forceUpdate: forceUpdate,
      callback: adapter.goldenFileExpectation(toMatch, goldenKey),
    );
    await cleanup?.call();
  } on TestFailure {
    if (shouldCompare) {
      rethrow;
    }
  }
}
