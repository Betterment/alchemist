import 'package:flutter/material.dart';

class GoldenTestTheme {
  GoldenTestTheme({
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color backgroundColor;
  final Color borderColor;

  factory GoldenTestTheme.standard() {
    return GoldenTestTheme(
      // These colors are not tied to any implementation so they won't
      // change out from under us, which would cause golden tests to fail.
      backgroundColor: const Color(0xFF2b54a1),
      borderColor: const Color(0xFF3d394a),
    );
  }
}
