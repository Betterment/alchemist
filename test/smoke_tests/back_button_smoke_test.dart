import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds with a BackButton widget',
      fileName: 'back_button_smoke_test',
      builder: () => const BackButton(),
    );
  });
}
