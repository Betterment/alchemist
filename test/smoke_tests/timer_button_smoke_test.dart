import 'dart:async';

import 'package:alchemist/src/golden_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class TimerButton extends StatelessWidget {
  const TimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    // A fixed size: the golden must not depend on the text width. Linux
    // measures the 6 Ahem glyphs as 83.9996 px, macOS as 84 px. A button
    // sized by its text is then a fraction of a pixel narrower on Linux, and
    // its antialiased right edge is a 30 px diff in this small image.
    return SizedBox(
      width: 120,
      height: 48,
      child: ElevatedButton(
        child: const Text('Button'),
        onPressed: () {
          Timer(Duration.zero, () {});
        },
      ),
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
