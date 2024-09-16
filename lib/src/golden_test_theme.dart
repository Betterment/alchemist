import 'package:alchemist/src/golden_test_group.dart';
import 'package:flutter/material.dart';

/// {@template golden_test_theme}
/// A theme that dictates the behavior and appearance of elements created
/// by Alchemist during golden testing. This theme is used to ensure that
/// parts of golden tests controlled by Alchemist are consistent across
/// Flutter SDK versions.
/// {@endtemplate}
class GoldenTestTheme {
  /// {@macro golden_test_theme}
  GoldenTestTheme({
    required this.backgroundColor,
    required this.borderColor,
  });

  /// The standard theme for golden tests, used when no other theme is provided.
  factory GoldenTestTheme.standard() {
    return GoldenTestTheme(
      // These colors are not tied to any implementation so they won't
      // change out from under us, which would cause golden tests to fail.
      backgroundColor: const Color(0xFF2b54a1),
      borderColor: const Color(0xFF3d394a),
    );
  }

  /// The background color of the golden test.
  final Color backgroundColor;

  /// The border color used to separate scenarios in a [GoldenTestGroup].
  final Color borderColor;
}
