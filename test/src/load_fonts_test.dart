import 'package:alchemist/src/golden_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // goldenTest calls loadFonts in each test body. The tests share one isolate,
  // so the second test must not await a future from the first test's
  // fake-async zone. If it does, the test never continues and the timeout
  // fails it.
  group('loadFonts in consecutive widget tests', () {
    for (final name in ['first', 'second', 'third']) {
      testWidgets(
        'completes in the $name test',
        (tester) => loadFonts(),
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }
  });
}
