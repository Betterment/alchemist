import 'package:alchemist/alchemist.dart';
import 'package:example/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Red Button Golden Tests', () {
    goldenTest(
      'renders correctly',
      fileName: 'red_button',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'enabled',
            child: RedButton(
              onPressed: () {},
              child: const Text('Red Button'),
            ),
          ),
          GoldenTestScenario(
            name: 'enabled with a custom textstyle name label',
            nameTextStyle: const TextStyle(
              color: Colors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            child: RedButton(
              onPressed: () {},
              child: const Text('Red Button'),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: const RedButton(
              onPressed: null,
              child: Text('Red Button'),
            ),
          ),
          GoldenTestScenario(
            name: 'with icon',
            child: RedButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
              child: const Text('Red Button'),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled with icon',
            child: const RedButton(
              onPressed: null,
              icon: Icon(Icons.add),
              child: Text('Red Button'),
            ),
          ),
        ],
      ),
    );
  });
}
