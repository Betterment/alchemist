import 'dart:async';

import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TimerButton extends StatelessWidget {
  const TimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Button'),
      onPressed: () {
        Timer(Duration.zero, () {});
      },
    );
  }
}

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds after tapping button with timer',
      fileName: 'timer_button_smoke_test',
      pumpBeforeTest: (tester) async {
        await tester.tap(find.byType(TimerButton));
        await tester.pumpAndSettle();
      },
      builder: () => const TimerButton(),
    );
  });
}
