import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds without a package name',
      fileName: 'text_package_smoke_test_no_package',
      builder: () => const Text(
        'Hello, world!',
        style: TextStyle(
          fontFamily: 'Roboto',
        ),
      ),
    );

    goldenTest(
      'succeeds with a package name',
      fileName: 'text_package_smoke_test_specified',
      builder: () => const Text(
        'Hello, world!',
        style: TextStyle(
          fontFamily: 'Roboto',
          package: 'alchemist',
        ),
      ),
    );
  });
}
