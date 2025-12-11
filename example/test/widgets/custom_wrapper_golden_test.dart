import 'package:alchemist/alchemist.dart';
import 'package:clock/clock.dart';
import 'package:example/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Custom Wrapper Golden Tests', () {
    goldenTest(
      'renders correctly',
      fileName: 'custom_wrapper',
      testWrapper: (test) async => withClock<void>(
        Clock.fixed(DateTime.utc(2025, 9, 10)),
        test,
      ),
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'now',
            child: const DateText(),
          ),
        ],
      ),
    );
  });
}
