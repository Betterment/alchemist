import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds with an unconstrained widget',
      fileName: 'unconstrained_smoke_test',
      constraints: const BoxConstraints(maxWidth: 3000, maxHeight: 3000),
      builder: () =>
          const SizedBox.expand(child: ColoredBox(color: Colors.red)),
    );

    goldenTest(
      'succeeds with a big constrained widget',
      fileName: 'constrained_big_smoke_test',
      builder: () => const SizedBox(
        width: 3000,
        height: 3000,
        child: ColoredBox(color: Colors.red),
      ),
    );
  });
}
