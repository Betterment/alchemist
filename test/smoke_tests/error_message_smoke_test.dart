import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds with an error message',
      fileName: 'error_message_smoke_test',
      builder: () => SizedBox(
        width: 200,
        height: 200,
        child: ErrorWidget(FlutterError('This is an error message.')),
      ),
    );
  });
}
