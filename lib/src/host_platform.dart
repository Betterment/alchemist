import 'dart:io';

/// A class that represents a host platform that can run golden tests.
///
/// The current platform can be retrieved using [HostPlatform.current], and
/// checks against this value are available using [isMacOS], [isLinux] and so
/// on.
class HostPlatform {
  const HostPlatform._(this._value);

  /// An internal factory used to retrieve a [HostPlatform] based on the current
  /// real platform this program is running on.
  factory HostPlatform._realPlatform() {
    final hostByPlatform = {
      Platform.isMacOS: HostPlatform.macOS,
      Platform.isLinux: HostPlatform.linux,
      Platform.isWindows: HostPlatform.windows,
    };

    return hostByPlatform[true]!;
  }

  /// The current host platform.
  ///
  /// This value can be overridden in tests using [overrideTestValue].
  factory HostPlatform.current() {
    return _overrideTestValue ?? HostPlatform._realPlatform();
  }

  /// {@macro host_platform.override_test_value}
  static HostPlatform? _overrideTestValue;

  /// {@template host_platform.override_test_value}
  /// Provides an override for the current platform for use in testing.
  ///
  /// Can be cleared using [clearOverrideTestValue].
  ///
  /// If set to a non-null value, all platform checks will use this value. This
  /// is useful for simulating a platform in tests that is not the same as the
  /// actual platform the test is running on.
  ///
  /// This is intended for use in testing only. Do not set this in production
  /// code.
  ///
  /// ```dart
  /// test('isLinux function works properly', () {
  ///   // Set the override value to simulate a platform.
  ///   HostPlatform.overrideTestValue = HostPlatform.macOS;
  ///   // Don't forget to reset the override value when done.
  ///   addTearDown(HostPlatform.clearOverrideTestValue);
  ///
  ///   expect(HostPlatform.current().isLinux, isFalse); // ✅
  ///
  ///   HostPlatform.overrideTestValue = HostPlatform.linux;
  ///
  ///   expect(HostPlatform.current().isLinux, isTrue); // ✅
  /// });
  /// ```
  ///
  /// See also:
  /// * [clearOverrideTestValue], which clears this value and returns it to
  ///   the actual platform.
  /// {@endtemplate}
  // ignore: avoid_setters_without_getters
  static set overrideTestValue(HostPlatform value) {
    _overrideTestValue = value;
  }

  /// Clears the testing override for the current platform.
  ///
  /// See [overrideTestValue] for more details.
  static void clearOverrideTestValue() {
    _overrideTestValue = null;
  }

  /// The internal value used to represent the current platform.
  ///
  /// This value is also returned by [operatingSystem].
  final String _value;

  /// Returns all values [HostPlatform] can represent.
  static const values = {macOS, linux, windows};

  /// The Apple macOS platform (`"macOS"`).
  ///
  /// See [HostPlatform] for more information.
  static const macOS = HostPlatform._('macOS');

  /// The Linux platform (`"Linux"`).
  ///
  /// See [HostPlatform] for more information.
  static const linux = HostPlatform._('Linux');

  /// The Microsoft Windows platform (`"Windows"`).
  ///
  /// See [HostPlatform] for more information.
  static const windows = HostPlatform._('Windows');

  /// The name of the current platform.
  ///
  /// This will return the name of this [HostPlatform].
  ///
  /// ```dart
  /// HostPlatform.macOS.operatingSystem; // "macOS"
  /// HostPlatform.linux.operatingSystem; // "Linux"
  /// HostPlatform.windows.operatingSystem; // "Windows"
  /// ```
  String get operatingSystem => _value;

  /// Indicates whether this platform is Apple's macOS.
  bool get isMacOS => this == HostPlatform.macOS;

  /// Indicates whether this platform is Linux.
  bool get isLinux => this == HostPlatform.linux;

  /// Indicates whether this platform is Microsoft's Windows.
  bool get isWindows => this == HostPlatform.windows;

  @override
  String toString() {
    return 'HostPlatform($_value)';
  }
}
