import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    GoldenTestGroup buildSmokeTestGroup() {
      return GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'scenario_text',
            child: const Text('text'),
          ),
          GoldenTestScenario(
            name: 'scenario_button',
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  const Color(0xFF2196F3),
                ),
                foregroundColor: MaterialStateProperty.all(
                  const Color(0xFFFFFFFF),
                ),
                shadowColor: MaterialStateProperty.all(
                  const Color(0xFFFF0000),
                ),
                surfaceTintColor: MaterialStateProperty.all(
                  const Color(0xFF00FF00),
                ),
                overlayColor: MaterialStateProperty.all(
                  const Color(0xFF0000FF),
                ),
              ),
              onPressed: () {},
              onLongPress: () {},
              child: const Text('button'),
            ),
          ),
        ],
      );
    }

    goldenTest(
      'succeeds in regular state',
      fileName: 'interactions_smoke_test_regular',
      builder: buildSmokeTestGroup,
    );

    goldenTest(
      'succeeds while pressed',
      fileName: 'interactions_smoke_test_pressed',
      whilePerforming: press(find.byType(TextButton)),
      builder: buildSmokeTestGroup,
    );

    goldenTest(
      'succeeds while long pressed',
      fileName: 'interactions_smoke_test_long_pressed',
      whilePerforming: longPress(find.byType(TextButton)),
      builder: buildSmokeTestGroup,
    );
  });
}
