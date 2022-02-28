import 'dart:async';

import 'package:alchemist/src/alchemist_config.dart';
import 'package:alchemist/src/host_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// The function signature of Flutter test's `testWidgets` function.
typedef TestWidgetsFn = void Function(
  String description,
  Future<void> Function(WidgetTester) callback, {
  bool? skip,
  Timeout? timeout,
  Duration? initialTimeout,
  bool semanticsEnabled,
  TestVariant<Object?> variant,
  dynamic tags,
});

/// Function used to invoke an AsyncMatcher and perform an assertion of its
/// result. Typically, this involves an `expectLater` call that verifies
/// an image matches another via the matcher `matchesGoldenFile`.
typedef MatchesGoldenFileInvocation<T> = FutureOr<T> Function();

/// A function which returns a [MatchesGoldenFileInvocation] to compare two
/// golden finders or images.
typedef GoldenFileExpectation = MatchesGoldenFileInvocation<void> Function(
  Object,
  Object,
);

// ignore: prefer_function_declarations_over_variables
GoldenFileExpectation _goldenFileExpectation =
    (Object a, Object b) => () => expectLater(a, matchesGoldenFile(b));

/// {@template golden_file_expectation}
/// A function which performs a test expectation which invokes an asynchronous
/// matcher (e.g. `matchesGoldenFile`).
/// {@endtemplate}
GoldenFileExpectation get goldenFileExpectation => _goldenFileExpectation;
set goldenFileExpectation(GoldenFileExpectation value) =>
    _goldenFileExpectation = value;

TestWidgetsFn _testWidgetsFn = testWidgets;

/// A function to be used in place of `flutter_test`'s `testWidgets` function.
/// The ability to use a stub method here makes it easier to test Alchemist.
TestWidgetsFn get testWidgetsFn => _testWidgetsFn;
set testWidgetsFn(TestWidgetsFn value) => _testWidgetsFn = value;

/// {@template alchemist_test_variant}
/// A [TestVariant] used to run both CI and platform golden tests with one
/// [testWidgets] function
/// {@endtemplate}
@visibleForTesting
class AlchemistTestVariant extends TestVariant<GoldensConfig> {
  /// {@macro alchemist_test_variant}
  AlchemistTestVariant({
    required AlchemistConfig config,
    required HostPlatform currentPlatform,
  })  : _config = config,
        _currentPlatform = currentPlatform;

  final AlchemistConfig _config;
  final HostPlatform _currentPlatform;

  /// The [GoldensConfig] to use for the current variant
  GoldensConfig get currentConfig => _currentConfig;
  late GoldensConfig _currentConfig;

  @override
  String describeValue(GoldensConfig value) => value.environmentName;

  @override
  Future<void> setUp(GoldensConfig value) async {
    _currentConfig = value;
  }

  @override
  Future<void> tearDown(
    GoldensConfig value,
    covariant AlchemistTestVariant? memento,
  ) async {}

  @override
  Iterable<GoldensConfig> get values {
    final platformConfig = _config.platformGoldensConfig;
    final runPlatformTest = platformConfig.enabled &&
        platformConfig.platforms.contains(_currentPlatform);

    final ciConfig = _config.ciGoldensConfig;
    final runCiTest = ciConfig.enabled;

    return {
      if (runPlatformTest) platformConfig,
      if (runCiTest) ciConfig,
    };
  }
}

/// Golden test adapter interface. Alchemist uses a concrete implementation of
/// this class to perform functions which are tightly coupled to Flutter's test
/// framework, allowing fake implementations to be used for testing Alchemist
/// by itself.
abstract class GoldenTestAdapter {
  /// Create a new [GoldenTestAdapter].
  const GoldenTestAdapter();

  /// A function that forces golden files to be regenerated while
  /// executing the given function [callback]. Afterwards, the flag is reset to
  /// its original value.
  ///
  /// If [forceUpdate] is `true`, the golden files will be regenerated even if
  /// they already exist. Otherwise, the flag is ignored and the function is
  /// executed as usual.
  Future<T> withForceUpdateGoldenFiles<T>({
    bool forceUpdate = false,
    required MatchesGoldenFileInvocation<T> callback,
  });

  /// Adds a setup callback to the test framework.
  void setUp(dynamic Function() body);

  /// Adds a teardown callback to the test framework.
  void tearDown(dynamic Function() body);

  /// {@macro golden_file_expectation}
  MatchesGoldenFileInvocation<void> goldenFileExpectation(
    Object a,
    Object b,
  );
}

/// Default implementation of [GoldenTestAdapter] to allow Alchemist access
/// to the Flutter test framework.
class FlutterGoldenTestAdapter extends GoldenTestAdapter {
  /// Create a new [FlutterGoldenTestAdapter].
  const FlutterGoldenTestAdapter() : super();

  @override
  Future<T> withForceUpdateGoldenFiles<T>({
    bool forceUpdate = false,
    required MatchesGoldenFileInvocation<T> callback,
  }) async {
    if (!forceUpdate) {
      return await callback();
    }

    final originalValue = autoUpdateGoldenFiles;
    autoUpdateGoldenFiles = true;
    try {
      return await callback();
    } finally {
      autoUpdateGoldenFiles = originalValue;
    }
  }

  @override
  void setUp(dynamic Function() body) => setUp(body);

  @override
  void tearDown(dynamic Function() body) => tearDown(body);

  @override
  MatchesGoldenFileInvocation<void> goldenFileExpectation(
    Object a,
    Object b,
  ) =>
      () => expectLater(a, matchesGoldenFile(b));
}
