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
            child: ElevatedButton(
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
      whilePerforming: press(find.byType(ElevatedButton)),
      builder: buildSmokeTestGroup,
    );

    goldenTest(
      'succeeds while long pressed',
      fileName: 'interactions_smoke_test_long_pressed',
      whilePerforming: longPress(find.byType(ElevatedButton)),
      builder: buildSmokeTestGroup,
    );
  });
}
