import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A function that returns the path of a golden test file for a given test's
/// [fileName]. This function's return value should include the `.png`
/// extension.
typedef FilePathResolver = String Function(String fileName);

/// A function that returns boolean indicating whether or not a
/// golden file with the given [fileName] should be compared.
typedef TestComparisonPredicate = bool Function(String fileName);

/// {@template alchemist_config}
/// A configuration object that contains settings used by Alchemist for
/// customizing the behavior of all golden tests.
///
/// Alchemist uses this configuration object to determine when and how to run
/// any given test. The default configuration is used when no custom
/// configuration is provided. The current instance can be retrieved using
/// [AlchemistConfig.current].
///
/// To override the current configuration, use [AlchemistConfig.runWithConfig].
/// The function passed to this method will receive the provided config
/// whenever [AlchemistConfig.current] is called. See
/// [AlchemistConfig.runWithConfig] for more details.
///
/// Set [forceUpdateGoldenFiles] to `true` to force all tests to update their
/// golden files. Otherwise, the golden tests will only update the golden file
/// if the `--update-goldens` flag is passed when running `flutter test`.
/// This defaults to `false`.
///
/// If a [theme] is provided, it will be assigned to the [MaterialApp] created
/// by Alchemist that wraps the golden test groups and scenarios when a test is
/// run. If no [theme] is provided, the default [ThemeData.light] will be used,
/// unless [PlatformGoldensConfig.theme] or [CiGoldensConfig.theme] is provided.
///
/// A [platformGoldensConfig] and [ciGoldensConfig] can be provided to configure
/// the behavior of platform and CI golden tests respectively. Each of these
/// also contains a [theme] property that can be used to override the theme used
/// for each type of golden test.
///
/// ### Platform tests vs. CI tests
///
/// Alchemist can perform two kinds of golden tests. One is **platform tests**,
/// which generate golden files with human readable text. These can be
/// considered regular golden tests. The other is **CI tests**, which look and
/// function the same as readable text, except that the text blocks are replaced
/// with colored squares. The reason for this distinction is that the output of
/// platform tests is dependent on the platform the test is running on. For
/// example, macOS is known to render text differently than other platforms.
/// This causes readable golden files generated on macOS to be ever so slightly
/// off from the golden files generated on other platforms, causing CI systems
/// to fail the test. CI tests, on the other hand, were made to circumvent this,
/// and will always have the same output regardless of the platform.
///
/// By default, CI tests will always be generated and compared, whereas platform
/// tests will be generated but are never compared.
///
/// Note that CI tests are always rendered in the "Ahem" font family to ensure
/// consistent results across platforms. In other words, the font family of the
/// [theme] (and [CiGoldensConfig.theme]) will be ignored.
/// {@endtemplate}
class AlchemistConfig extends Equatable {
  /// {@macro alchemist_config}
  const AlchemistConfig({
    bool? forceUpdateGoldenFiles,
    ThemeData? theme,
    PlatformGoldensConfig? platformGoldensConfig,
    CiGoldensConfig? ciGoldensConfig,
  })  : _forceUpdateGoldenFiles = forceUpdateGoldenFiles,
        _theme = theme,
        _platformGoldensConfig = platformGoldensConfig,
        _ciGoldensConfig = ciGoldensConfig;

  /// The instance of the [AlchemistConfig] in the current zone used by the
  /// `alchemist` package.
  ///
  /// If no [AlchemistConfig] is set, the default config is returned.
  factory AlchemistConfig.current() {
    final zoneValue = Zone.current[currentConfigKey] as AlchemistConfig?;
    return zoneValue ?? const AlchemistConfig();
  }

  /// The [Symbol] used to look up and assign the default [AlchemistConfig] in
  /// a [Zone].
  ///
  /// Exposed for internal testing. Do not use this explicitly.
  @protected
  @visibleForTesting
  static const currentConfigKey = #alchemist.config;

  /// Runs the given function [run] in a [Zone] where the default
  /// [AlchemistConfig] is set to [config].
  ///
  /// This method is commonly used to override the default [AlchemistConfig]
  /// within a block of code, such as a test or a group of tests.
  ///
  /// In particular, it's common for packages to define a
  /// `flutter_test_config.dart` file in the root of the project's `test/`
  /// directory, which can be used to override the default [AlchemistConfig]
  /// for all tests in the package.
  ///
  /// Additionally, settings for a given code block can be partially overridden
  /// by using [copyWith] or, more commonly, [merge].
  ///
  /// ### Example using `copyWith`
  ///
  /// ```dart
  /// void main() {
  ///   AlchemistConfig.runWithConfig(
  ///     // This example uses AlchemistConfig.copyWith to override the
  ///     // forceUpdateGoldenFiles and theme properties.
  ///     config: AlchemistConfig.current().copyWith(
  ///       forceUpdateGoldenFiles: true,
  ///       theme: ThemeData.dark(),
  ///     ),
  ///     run: () {
  ///       test('some test', () {
  ///         expect(AlchemistConfig.current().forceUpdateGoldenFiles, isTrue);
  ///         expect(AlchemistConfig.current().theme, equals(ThemeData.dark()));
  ///       });
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// ### Example using `merge`
  ///
  /// ```dart
  /// void main() {
  ///   AlchemistConfig.runWithConfig(
  ///     // This example uses AlchemistConfig.merge to override nested settings
  ///     // for the platformGoldensConfig.
  ///     // All other properties, including ones that may have been set by a
  ///     // previous call to [runWithConfig], will be preserved.
  ///     config: AlchemistConfig.current().merge(
  ///       AlchemistConfig(
  ///         platformGoldensConfig: PlatformGoldensConfig(
  ///           theme: ThemeData.dark(),
  ///         ),
  ///       ),
  ///     ),
  ///     run: () {
  ///       test('some test', () {
  ///         expect(
  ///           AlchemistConfig.current().platformGoldensConfig.theme,
  ///           equals(ThemeData.dark()),
  ///         );
  ///       });
  ///     },
  ///   );
  /// }
  /// ```
  ///
  static T runWithConfig<T>({
    required AlchemistConfig config,
    required T Function() run,
  }) {
    return runZoned<T>(
      run,
      zoneValues: {
        currentConfigKey: config,
      },
    );
  }

  /// Whether to force the golden tests to update the golden file.
  ///
  /// If set to `true`, the golden tests will always update the golden file.
  /// Otherwise, the golden tests will only update the golden file if the
  /// `--update-goldens` flag is passed when running `flutter test`.
  bool get forceUpdateGoldenFiles => _forceUpdateGoldenFiles ?? false;
  final bool? _forceUpdateGoldenFiles;

  /// The [ThemeData] to use when generating golden tests.
  ///
  /// If no [ThemeData] is provided, the default [ThemeData.light] will be used.
  ThemeData? get theme => _theme;
  final ThemeData? _theme;

  /// The configuration for human readable golden tests running in non-CI
  /// environments.
  ///
  /// This contains various settings used by [goldenTest] to determine whether
  /// and how to run golden tests intended to be run locally.
  PlatformGoldensConfig get platformGoldensConfig =>
      _platformGoldensConfig ?? const PlatformGoldensConfig();
  final PlatformGoldensConfig? _platformGoldensConfig;

  /// The configuration for golden tests intended to be run in CI.
  ///
  /// This contains various settings used by [goldenTest] to determine whether
  /// and how to run golden tests intended to be run in a CI environment.
  CiGoldensConfig get ciGoldensConfig =>
      _ciGoldensConfig ?? const CiGoldensConfig();
  final CiGoldensConfig? _ciGoldensConfig;

  /// Creates a copy of this [AlchemistConfig] and replaces the given fields.
  AlchemistConfig copyWith({
    bool? forceUpdateGoldenFiles,
    ThemeData? theme,
    PlatformGoldensConfig? platformGoldensConfig,
    CiGoldensConfig? ciGoldensConfig,
  }) {
    return AlchemistConfig(
      forceUpdateGoldenFiles: forceUpdateGoldenFiles ?? _forceUpdateGoldenFiles,
      theme: theme ?? _theme,
      platformGoldensConfig: platformGoldensConfig ?? _platformGoldensConfig,
      ciGoldensConfig: ciGoldensConfig ?? _ciGoldensConfig,
    );
  }

  /// Creates a copy and merges this [AlchemistConfig] with the given config,
  /// replacing all set fields of the copy with the given config's fields.
  ///
  /// Note that this method also merged the [other]'s [platformGoldensConfig]
  /// and [ciGoldensConfig] (i.e., nested merging). See
  /// [PlatformGoldensConfig.merge] and [CiGoldensConfig.merge] for more
  /// details.
  AlchemistConfig merge(AlchemistConfig? other) {
    return copyWith(
      forceUpdateGoldenFiles: other?._forceUpdateGoldenFiles,
      theme: other?._theme,
      platformGoldensConfig:
          platformGoldensConfig.merge(other?._platformGoldensConfig),
      ciGoldensConfig: ciGoldensConfig.merge(other?._ciGoldensConfig),
    );
  }

  @override
  List<Object?> get props => [
        forceUpdateGoldenFiles,
        theme,
        platformGoldensConfig,
        ciGoldensConfig,
      ];
}

/// {@template readable_goldens_config}
/// The configuration for human readable golden tests.
///
/// This contains various settings used by [goldenTest] to determine whether
/// and how to run golden tests intended to be run locally.
///
/// The [enabled] flag determines whether or not platform golden tests are
/// enabled. If set to `false`, these tests will not be generated or compared.
/// Otherwise the tests will function as normal.
///
/// A [comparePredicate] can be provided to indicate if the output of a
/// golden test should be compared to its golden file. By default, this is set
/// to `false`, meaning the golden file may be generated but will never be used
/// in a comparison test.
///
/// Note that this predicate is ignored if the test is being run on a platform
/// not included in the set of [platforms] -- in these cases the test will never
/// be generated or compared.
///
/// The [filePathResolver] can be used to customize the name and of the golden
/// file. By default, the golden file is located in the
/// `goldens/<platform_name>` directory relative to the test file.
///
/// If a [theme] is provided, it will be assigned to the [MaterialApp] created
/// by Alchemist that wraps the golden test groups and scenarios when a test of
/// this type is run. If no [theme] is provided, the enclosing
/// [AlchemistConfig]'s theme will be used. If that is also `null`, the default
/// [ThemeData.light] will be used.
/// {@endtemplate}
class PlatformGoldensConfig extends Equatable {
  /// {@macro readable_goldens_config}
  const PlatformGoldensConfig({
    Set<HostPlatform>? platforms,
    bool? enabled,
    TestComparisonPredicate? comparePredicate,
    FilePathResolver? filePathResolver,
    ThemeData? theme,
  })  : _enabled = enabled,
        _platforms = platforms,
        _comparePredicate = comparePredicate,
        _filePathResolver = filePathResolver,
        _theme = theme;

  /// The default set of [platforms] that golden tests will run on.
  ///
  /// See [platforms] for more details.
  static const _defaultPlatforms = HostPlatform.values;

  /// The default value for the [enabled] field.
  ///
  /// This is set to `true`, meaning golden tests will always run.
  static const _defaultEnabled = true;

  /// The default value for the [comparePredicate] field.
  ///
  /// This always returns `false`, meaning golden files will never be compared
  /// in any test.
  ///
  /// See [comparePredicate] for more details.
  static bool _defaultComparePredicate(String _) => false;

  /// The default [FilePathResolver] for the [filePathResolver] field.
  ///
  /// See [filePathResolver] for more details.
  static String _defaultFilePathResolver(String fileName) {
    final platform = HostPlatform.current().operatingSystem;
    return 'goldens/$platform/$fileName.png';
  }

  /// The set of [HostPlatform]s that readable golden tests will run on.
  ///
  /// This set determines whether a golden test should run on a given platform.
  /// Platforms not included in this set will ensure that golden tests are never
  /// run or checked on that platform. In other words, a golden test will only
  /// run if the current platform is included in this set.
  ///
  /// By default, this set is the set of all [HostPlatform]s.
  ///
  /// See [HostPlatform] for more details.
  Set<HostPlatform> get platforms => _platforms ?? _defaultPlatforms;
  final Set<HostPlatform>? _platforms;

  /// Whether or not platform golden tests should run.
  ///
  /// If this is set to `false`, platform golden tests will never run and the
  /// output of the [comparePredicate] is ignored.
  bool get enabled => _enabled ?? _defaultEnabled;
  final bool? _enabled;

  /// A function that returns whether the given test should be run.
  ///
  /// This function is used by [goldenTest] to determine how a given test should
  /// be run. If no function is provided, no golden files will be compared for
  /// platform tests.
  ///
  /// Note that this predicate is ignored if the test is being run on a platform
  /// not included in the set of [platforms] -- in these cases the test will
  /// never run.
  TestComparisonPredicate get comparePredicate =>
      _comparePredicate ?? _defaultComparePredicate;
  final TestComparisonPredicate? _comparePredicate;

  /// A function that returns the path of the golden file for a given test's
  /// file name. This function's return value should include the `.png`
  /// extension.
  ///
  /// This function is used by [goldenTest] to determine where the golden file
  /// should be located. By default, the golden file is located in the
  /// `goldens/<platform_name>` directory relative to the test file.
  FilePathResolver get filePathResolver =>
      _filePathResolver ?? _defaultFilePathResolver;
  final FilePathResolver? _filePathResolver;

  /// The [ThemeData] to use when generating golden tests.
  ///
  /// If no [ThemeData] is provided, the enclosing [AlchemistConfig]'s theme
  /// will be used. If that is also `null`, the default [ThemeData.light] will
  /// be used.
  ThemeData? get theme => _theme;
  final ThemeData? _theme;

  /// Creates a copy of this [PlatformGoldensConfig] and replaces the given
  /// fields.
  PlatformGoldensConfig copyWith({
    Set<HostPlatform>? platforms,
    bool? enabled,
    TestComparisonPredicate? comparePredicate,
    FilePathResolver? filePathResolver,
    ThemeData? theme,
  }) {
    return PlatformGoldensConfig(
      platforms: platforms ?? _platforms,
      enabled: enabled ?? _enabled,
      comparePredicate: comparePredicate ?? _comparePredicate,
      filePathResolver: filePathResolver ?? _filePathResolver,
      theme: theme ?? _theme,
    );
  }

  /// Creates a copy and merges this [PlatformGoldensConfig] with the given
  /// config, replacing all set fields of the copy with the given config's
  /// fields.
  PlatformGoldensConfig merge(PlatformGoldensConfig? other) {
    return copyWith(
      platforms: other?._platforms,
      enabled: other?._enabled,
      comparePredicate: other?._comparePredicate,
      filePathResolver: other?._filePathResolver,
      theme: other?._theme,
    );
  }

  @override
  List<Object?> get props => [
        platforms,
        enabled,
        comparePredicate,
        filePathResolver,
        theme,
      ];
}

/// {@template ci_goldens_config}
/// The configuration for golden tests intended to be run in CI.
///
/// This contains various settings used by [goldenTest] to determine whether
/// and how to run golden tests intended to be run in a CI environment.
///
/// The [enabled] flag determines whether or not platform golden tests are
/// enabled. If set to `false`, these tests will not be generated or compared.
/// Otherwise the tests will function as normal.
///
/// A [comparePredicate] can be provided to determine how a given test should
/// should be run. If no function is provided, all golden files will be
/// compared.
///
/// The [filePathResolver] can be used to customize the name and of the golden
/// file. By default, the golden file is located in the `goldens/ci/` directory
/// relative to the test file.
///
/// If a [theme] is provided, it will be assigned to the [MaterialApp] created
/// by Alchemist that wraps the golden test groups and scenarios when a test of
/// this type is run. If no [theme] is provided, the enclosing
/// [AlchemistConfig]'s theme will be used. If that is also `null`, the default
/// [ThemeData.light] will be used.
///
/// **Note:** CI tests are always rendered in the "Ahem" font family to ensure
/// consistent results across platforms. In other words, the font family of the
/// [theme] will be ignored.
/// {@endtemplate}
class CiGoldensConfig extends Equatable {
  /// {@macro ci_goldens_config}
  const CiGoldensConfig({
    bool? enabled,
    TestComparisonPredicate? comparePredicate,
    FilePathResolver? filePathResolver,
    ThemeData? theme,
  })  : _enabled = enabled,
        _comparePredicate = comparePredicate,
        _filePathResolver = filePathResolver,
        _theme = theme;

  /// The default value for the [enabled] field.
  ///
  /// This is `true` by default, meaning that CI golden tests will always run.
  static const _defaultEnabled = true;

  /// The default value for the [comparePredicate] field.
  ///
  /// This always returns `true`, meaning golden files will be compared in any
  /// test.
  ///
  /// See [comparePredicate] for more details.
  static bool _defaultComparePredicate(String _) => true;

  /// The default [FilePathResolver] for the [filePathResolver] field.
  ///
  /// See [filePathResolver] for more details.
  static String _defaultFilePathResolver(String fileName) {
    return 'goldens/ci/$fileName.png';
  }

  /// Whether or not CI golden tests should run.
  ///
  /// If this is set to `false`, CI golden tests will never run and the output
  /// of the [comparePredicate] is ignored.
  bool get enabled => _enabled ?? _defaultEnabled;
  final bool? _enabled;

  /// A function that returns whether the given test should be run.
  ///
  /// This function is used by [goldenTest] to determine whether the given test
  /// should be run. If no function is provided, all golden files will be
  /// compared.
  TestComparisonPredicate get comparePredicate =>
      _comparePredicate ?? _defaultComparePredicate;
  final TestComparisonPredicate? _comparePredicate;

  /// A function that returns the path of the golden file for a given test's
  /// file name. This function's return value should include the `.png`
  /// extension.
  ///
  /// This function is used by [goldenTest] to determine where the golden file
  /// should be located. By default, the golden file is located in the
  /// `goldens/ci/` directory relative to the test file.
  FilePathResolver get filePathResolver =>
      _filePathResolver ?? _defaultFilePathResolver;
  final FilePathResolver? _filePathResolver;

  /// The [ThemeData] to use when generating golden tests.
  ///
  /// If no [ThemeData] is provided, the enclosing [AlchemistConfig]'s theme
  /// will be used. If that is also `null`, the default [ThemeData.light] will
  /// be used.
  ///
  /// **Note:** CI tests are always rendered in the "Ahem" font family to ensure
  /// consistent results across platforms. In other words, the font family of
  /// the [theme] will be ignored.
  ThemeData? get theme => _theme;
  final ThemeData? _theme;

  /// Creates a copy of this [CiGoldensConfig] and replaces the given fields.
  CiGoldensConfig copyWith({
    bool? enabled,
    TestComparisonPredicate? comparePredicate,
    FilePathResolver? filePathResolver,
    ThemeData? theme,
  }) {
    return CiGoldensConfig(
      enabled: enabled ?? _enabled,
      comparePredicate: comparePredicate ?? _comparePredicate,
      filePathResolver: filePathResolver ?? _filePathResolver,
      theme: theme ?? _theme,
    );
  }

  /// Creates a copy and merges this [CiGoldensConfig] with the given config,
  /// replacing all set fields of the copy with the given config's fields.
  CiGoldensConfig merge(CiGoldensConfig? other) {
    return copyWith(
      enabled: other?._enabled,
      comparePredicate: other?._comparePredicate,
      filePathResolver: other?._filePathResolver,
      theme: other?._theme,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        comparePredicate,
        filePathResolver,
        theme,
      ];
}
