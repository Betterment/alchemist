import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SmokeTest extends StatelessWidget {
  _SmokeTest({super.key}) : _link = LayerLink();

  final LayerLink _link;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CompositedTransformTarget(link: _link, child: const FlutterLogo()),
        CompositedTransformFollower(link: _link, child: const Text('label')),
      ],
    );
  }
}

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds with CompositedTransformFollower',
      fileName: 'composited_transform_smoke_test',
      builder: _SmokeTest.new,
    );
  });
}
