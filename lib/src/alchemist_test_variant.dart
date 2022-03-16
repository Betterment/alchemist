import 'package:alchemist/src/alchemist_config.dart';
import 'package:alchemist/src/host_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// {@template alchemist_test_variant}
/// A [TestVariant] used to run both CI and platform golden tests with one
/// [testWidgets] function.
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
  ) async {
    imageCache?.clear();
  }

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
