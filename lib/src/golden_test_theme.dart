import 'package:alchemist/src/golden_test_group.dart';
import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:flutter/material.dart';

/// {@template golden_test_theme}
/// A theme that dictates the behavior and appearance of elements created
/// by Alchemist during golden testing. This theme is used to ensure that
/// parts of golden tests controlled by Alchemist are consistent across
/// Flutter SDK versions.
/// {@endtemplate}
class GoldenTestTheme extends ThemeExtension<GoldenTestTheme> {
  /// {@macro golden_test_theme}
  GoldenTestTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.nameTextStyle,
    this.padding = EdgeInsets.zero,
  });

  /// The standard theme for golden tests, used when no other theme is provided.
  factory GoldenTestTheme.standard() {
    return GoldenTestTheme(
      // These colors are not tied to any implementation so they won't
      // change out from under us, which would cause golden tests to fail.
      backgroundColor: const Color(0xFF2b54a1),
      borderColor: const Color(0xFF3d394a),
      nameTextStyle: const TextStyle(fontSize: 18),
    );
  }

  /// The background color of the golden test.
  final Color backgroundColor;

  /// The border color used to separate scenarios in a [GoldenTestGroup].
  final Color borderColor;

  /// The padding that is used to wrap around:
  /// - the whole image
  /// - each individual [GoldenTestScenario]
  final EdgeInsetsGeometry padding;

  /// The text style that is used to show the name in a [GoldenTestScenario]
  final TextStyle nameTextStyle;

  @override
  ThemeExtension<GoldenTestTheme> copyWith({
    Color? backgroundColor,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    TextStyle? nameTextStyle,
  }) {
    return GoldenTestTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      padding: padding ?? this.padding,
      nameTextStyle: nameTextStyle ?? this.nameTextStyle,
    );
  }

  @override
  ThemeExtension<GoldenTestTheme> lerp(
    covariant ThemeExtension<GoldenTestTheme>? other,
    double t,
  ) {
    if (other is! GoldenTestTheme) {
      return this;
    }
    return GoldenTestTheme(
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t) ??
          backgroundColor,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t) ?? padding,
      nameTextStyle: nameTextStyle.copyWith(
        color:
            Color.lerp(nameTextStyle.color, other.nameTextStyle.color, t) ??
            nameTextStyle.color,
      ),
    );
  }
}
