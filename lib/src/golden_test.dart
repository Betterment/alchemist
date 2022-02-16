import 'dart:async';
import 'dart:convert';

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// When set to `true`, the [goldenTest] method will skip setup.
///
/// Only used internally for testing.
@protected
@visibleForTesting
bool debugSkipGoldenTestSetup = false;

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

/// An internal function that forces golden files to be regenerated while
/// executing the given function [fn]. Afterwards, the flag is reset to its
/// original value.
///
/// If [forceUpdate] is `true`, the golden files will be regenerated even if
/// they already exist. Otherwise, the flag is ignored and the function is
/// executed as usual.
///
/// Used by [goldenTest] to force golden files to be regenerated.
Future<T> _withForceUpdateGoldenFiles<T>(
  bool forceUpdate,
  FutureOr<T> Function() fn,
) async {
  if (!forceUpdate) {
    return await fn();
  }

  final originalValue = autoUpdateGoldenFiles;
  autoUpdateGoldenFiles = true;
  try {
    return await fn();
  } finally {
    autoUpdateGoldenFiles = originalValue;
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
/// The [whilePressing] finder, if provided, will be used to press all widgets
/// that match the finder during the generation and assertion phase of the test.
/// This is useful for tests that require a widget to be pressed before it can
/// be properly tested, such as when in tests that check if a button has the
/// right color or animation while being pressed. See
/// [GoldenTestWidgetTesterExtensions.pressAll] for more details.
///
/// **Note**: If a [whilePressing] finder is provided, the widget tree is
/// **always** pumped and settled before the assertion phase of the test.
///
/// **Note:** if more than one widget needs to be pressed at the same time,
/// the given finder may match multiple widgets. However, if any matched
/// widget does not respond to the press, all other gestures will fail,
/// rendering the use of this argument useless.
@isTest
void goldenTest(
  String description, {
  required String fileName,
  bool? skip,
  List<String> tags = const ['golden'],
  double textScaleFactor = 1.0,
  BoxConstraints constraints = const BoxConstraints(),
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
  Finder? whilePressing,
  required Widget widget,
}) {
  assert(
    !fileName.endsWith('.png'),
    '''
Golden tests file names should not include file type extension.

This logic should be handled in the [filePathResolver] function of the
[PlatformGoldensConfig] and [CiGoldensConfig] classes in [AlchemistConfig].''',
  );

  if (!debugSkipGoldenTestSetup || (skip ?? false)) {
    setUp(_setUpGoldenTests);
  }

  final config = AlchemistConfig.current();

  testWidgets(
    description,
    (tester) => runGoldenTest(
      tester: tester,
      config: config,
      fileName: fileName,
      textScaleFactor: textScaleFactor,
      constraints: constraints,
      pumpBeforeTest: pumpBeforeTest,
      whilePressing: whilePressing,
      widget: widget,
    ),
    skip: skip,
    tags: tags,
  );
}

/// Internal method that runs a golden test for each enabled test type (platform
/// and CI).
///
/// Do not use this method directly. Instead, use [goldenTest] to run a golden
/// test.
@protected
@visibleForTesting
Future<void> runGoldenTest({
  required WidgetTester tester,
  required AlchemistConfig config,
  required String fileName,
  double textScaleFactor = 1.0,
  BoxConstraints constraints = const BoxConstraints(),
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
  Finder? whilePressing,
  Finder? whileLongPressing,
  required Widget widget,
}) async {
  final defaultTheme = config.theme ?? ThemeData.light();

  final currentPlatform = HostPlatform.current();

  final platformConfig = config.platformGoldensConfig;
  final runPlatformTest = platformConfig.enabled &&
      platformConfig.platforms.contains(currentPlatform);

  final ciConfig = config.ciGoldensConfig;
  final runCiTest = ciConfig.enabled;

  final failures = <TestFailure>[];

  if (runPlatformTest) {
    final shouldCompare = platformConfig.comparePredicate(fileName);
    final theme = config.platformGoldensConfig.theme ?? defaultTheme;
    final goldenKey = config.platformGoldensConfig.filePathResolver(fileName);

    try {
      await _generateAndCompare(
        tester: tester,
        forceUpdate: config.forceUpdateGoldenFiles,
        shouldCompare: shouldCompare,
        obscureText: false,
        goldenKey: goldenKey,
        textScaleFactor: textScaleFactor,
        constraints: constraints,
        theme: theme,
        pumpBeforeTest: pumpBeforeTest,
        whilePressing: whilePressing,
        whileLongPressing: whileLongPressing,
        widget: widget,
      );
    } on TestFailure catch (e) {
      failures.add(e);
    }
  }

  if (runPlatformTest && runCiTest) {
    await tester.cleanPump();
  }

  if (runCiTest) {
    final shouldCompare = ciConfig.comparePredicate(fileName);

    final baseTheme = config.ciGoldensConfig.theme ?? defaultTheme;
    final theme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Ahem',
      ),
    );

    final goldenKey = config.ciGoldensConfig.filePathResolver(fileName);

    try {
      await _generateAndCompare(
        tester: tester,
        forceUpdate: config.forceUpdateGoldenFiles,
        shouldCompare: shouldCompare,
        obscureText: true,
        goldenKey: goldenKey,
        textScaleFactor: textScaleFactor,
        constraints: constraints,
        theme: theme,
        pumpBeforeTest: pumpBeforeTest,
        whilePressing: whilePressing,
        whileLongPressing: whileLongPressing,
        widget: widget,
      );
    } on TestFailure catch (e) {
      failures.add(e);
    }
  }

  if (failures.length == 1) {
    // ignore: only_throw_errors
    throw failures.first;
  } else if (failures.isNotEmpty) {
    const messagePrefix =
        'Multiple test failures occurred while running golden tests.';

    final indentedFailureMessages = <String>[];
    for (final failure in failures) {
      final indentedMessage = failure.message
          ?.splitMapJoin('\n', onNonMatch: (match) => '  $match');
      indentedFailureMessages.add(indentedMessage ?? '<No message given>');
    }

    final message = '$messagePrefix\n\n${indentedFailureMessages.join('\n\n')}';

    // ignore: only_throw_errors
    throw TestFailure(message);
  }
}

/// Runs a single golden test expectation.
///
/// Used internally by [runGoldenTest] for each type of golden test.
Future<void> _generateAndCompare({
  required WidgetTester tester,
  required bool forceUpdate,
  required bool shouldCompare,
  required bool obscureText,
  required Object goldenKey,
  required double textScaleFactor,
  required BoxConstraints constraints,
  required ThemeData theme,
  required PumpAction pumpBeforeTest,
  required Finder? whilePressing,
  required Finder? whileLongPressing,
  required Widget widget,
}) async {
  assert(
    whilePressing == null || whileLongPressing == null,
    'Cannot provide both whilePressing and whileLongPressing.',
  );

  const rootKey = Key('golden-test-root');

  await tester.pumpGoldenTest(
    rootKey: rootKey,
    textScaleFactor: textScaleFactor,
    constraints: constraints,
    theme: theme,
    widget: widget,
  );

  if (whilePressing != null) {
    final gestures = await tester.pressAll(whilePressing);
    await tester.pumpAndSettle();
    addTearDown(gestures.releaseAll);
  } else if (whileLongPressing != null) {
    final gestures = await tester.pressAll(whileLongPressing);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    addTearDown(gestures.releaseAll);
  }

  await pumpBeforeTest(tester);

  final root = find.byKey(rootKey);
  final toMatch = !obscureText ? root : tester.getBlockedTextImage(root);

  try {
    await _withForceUpdateGoldenFiles(
      forceUpdate,
      () => expectLater(toMatch, matchesGoldenFile(goldenKey)),
    );
  } on TestFailure {
    if (shouldCompare) {
      rethrow;
    }
  }
}
