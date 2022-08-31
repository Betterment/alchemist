import 'dart:io';

import 'package:equatable/equatable.dart';

/// Default host platform (the current host machine platform).
final defaultHostPlatform = HostPlatform._realPlatform();
HostPlatform _hostPlatform = defaultHostPlatform;

/// Indicates the current host platform used by Alchemist.
/// Can be overridden for testing. This value is utilized by
/// [HostPlatform.current].
HostPlatform get hostPlatform => _hostPlatform;
set hostPlatform(HostPlatform value) => _hostPlatform = value;

/// A class that represents a host platform that can run golden tests.
///
/// The current platform can be retrieved using [HostPlatform.current], and
/// checks against this value are available using [isMacOS], [isLinux] and so
/// on.
class HostPlatform extends Equatable implements Comparable<HostPlatform> {
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
  factory HostPlatform.current() {
    return hostPlatform;
  }

  /// The internal value used to represent the current platform.
  ///
  /// This value is also returned by [operatingSystem].
  final String _value;

  /// Returns all values [HostPlatform] can represent.
  static final values = {macOS, linux, windows};

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

  @override
  List<Object?> get props => [_value];

  @override
  int compareTo(covariant HostPlatform other) => _value.compareTo(other._value);
}
