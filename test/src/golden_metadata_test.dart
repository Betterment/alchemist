import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState, Rect, SemanticsFlags, SemanticsInputType, SemanticsRole, SemanticsValidationResult, Size, TextDirection, Tristate;

import 'package:alchemist/src/golden_metadata.dart';
import 'package:flutter/semantics.dart';
import 'package:test/test.dart';

/// Helper to create SemanticsData with sensible defaults for testing.
SemanticsData _makeSemanticsData({
  SemanticsFlags? flagsCollection,
  int actions = 0,
  String label = '',
  String value = '',
  String hint = '',
  String tooltip = '',
}) {
  // textDirection is required when label/value/hint/tooltip are non-empty.
  final needsDirection =
      label.isNotEmpty ||
      value.isNotEmpty ||
      hint.isNotEmpty ||
      tooltip.isNotEmpty;

  return SemanticsData(
    flagsCollection: flagsCollection ?? SemanticsFlags(),
    actions: actions,
    identifier: '',
    attributedLabel: AttributedString(label),
    attributedValue: AttributedString(value),
    attributedHint: AttributedString(hint),
    attributedIncreasedValue: AttributedString(''),
    attributedDecreasedValue: AttributedString(''),
    tooltip: tooltip,
    textDirection: needsDirection ? TextDirection.ltr : null,
    rect: Rect.zero,
    textSelection: null,
    scrollIndex: null,
    scrollChildCount: null,
    scrollPosition: null,
    scrollExtentMax: null,
    scrollExtentMin: null,
    platformViewId: -1,
    maxValueLength: -1,
    currentValueLength: -1,
    headingLevel: 0,
    linkUrl: null,
    role: SemanticsRole.none,
    controlsNodes: null,
    validationResult: SemanticsValidationResult.none,
    inputType: SemanticsInputType.none,
    locale: null,
  );
}

void main() {
  group('ScenarioMetadata', () {
    test('toJson() serializes name and flat bounds', () {
      final metadata = ScenarioMetadata(
        name: 'Card - active',
        bounds: const Rect.fromLTWH(10, 20, 400, 300),
      );

      expect(metadata.toJson(), {
        'name': 'Card - active',
        'x': 10,
        'y': 20,
        'w': 400,
        'h': 300,
      });
    });

    test('toJson() truncates fractional bounds to integers', () {
      final metadata = ScenarioMetadata(
        name: 'Fractional',
        bounds: const Rect.fromLTWH(10.7, 20.9, 400.3, 300.1),
      );

      final json = metadata.toJson();
      expect(json['x'], 10);
      expect(json['y'], 20);
      expect(json['w'], 400);
      expect(json['h'], 300);
    });

    test('toJson() omits semantics when null', () {
      final metadata = ScenarioMetadata(
        name: 'No semantics',
        bounds: Rect.zero,
      );

      expect(metadata.toJson().containsKey('semantics'), isFalse);
    });

    test('toJson() omits semantics when empty list', () {
      final metadata = ScenarioMetadata(
        name: 'Empty semantics',
        bounds: Rect.zero,
        semantics: const [],
      );

      expect(metadata.toJson().containsKey('semantics'), isFalse);
    });

    test('toJson() includes semantics when present', () {
      final metadata = ScenarioMetadata(
        name: 'With semantics',
        bounds: Rect.zero,
        semantics: const [
          SemanticsNodeData(label: 'Buy', role: 'button', actions: ['tap']),
        ],
      );

      final json = metadata.toJson();
      expect(json['semantics'], isList);
      expect(json['semantics'], hasLength(1));
      expect(json['semantics'][0]['label'], 'Buy');
    });
  });

  group('GoldenMetadata', () {
    test('creates from String path', () {
      final metadata = GoldenMetadata(goldenPath: 'goldens/ci/card.png');
      expect(metadata.jsonPath, 'goldens/ci/card.json');
    });

    test('creates from Uri path', () {
      final metadata = GoldenMetadata(
        goldenPath: Uri.file('/tmp/goldens/ci/card.png'),
      );
      expect(metadata.jsonPath, '/tmp/goldens/ci/card.json');
    });

    test('addScenario() preserves insertion order', () {
      final metadata = GoldenMetadata(goldenPath: 'test.png');
      metadata.addScenario(
        name: 'First',
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      metadata.addScenario(
        name: 'Second',
        bounds: const Rect.fromLTWH(100, 0, 100, 100),
      );

      expect(metadata.scenarios, hasLength(2));
      expect(metadata.scenarios[0].name, 'First');
      expect(metadata.scenarios[1].name, 'Second');
    });

    test('toJson() includes version, image, and scenarios', () {
      final metadata = GoldenMetadata(goldenPath: 'test.png');
      metadata.imageSize = const Size(1600, 1200);
      metadata.addScenario(
        name: 'Card',
        bounds: const Rect.fromLTWH(0, 0, 400, 398),
      );

      final json = metadata.toJson();
      expect(json['version'], 1);
      expect(json['image'], {'w': 1600, 'h': 1200});
      expect(json['scenarios'], hasLength(1));
      expect(json['scenarios'][0]['name'], 'Card');
    });

    test('writeToFile() creates JSON file with correct content', () async {
      final tempDir = Directory.systemTemp.createTempSync('alchemist_test_');
      try {
        final goldenPath = '${tempDir.path}/goldens/ci/test.png';
        final metadata = GoldenMetadata(goldenPath: goldenPath);
        metadata.imageSize = const Size(800, 600);
        metadata.addScenario(
          name: 'Button',
          bounds: const Rect.fromLTWH(0, 0, 200, 150),
        );

        await metadata.writeToFile();

        final jsonFile = File('${tempDir.path}/goldens/ci/test.json');
        expect(jsonFile.existsSync(), isTrue);

        final content = json.decode(jsonFile.readAsStringSync())
            as Map<String, dynamic>;
        expect(content['version'], 1);
        expect(content['image']['w'], 800);
        expect(content['scenarios'], hasLength(1));
        expect(content['scenarios'][0]['name'], 'Button');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writeToFile() creates parent directories', () async {
      final tempDir = Directory.systemTemp.createTempSync('alchemist_test_');
      try {
        final goldenPath = '${tempDir.path}/deep/nested/path/test.png';
        final metadata = GoldenMetadata(goldenPath: goldenPath);
        metadata.imageSize = Size.zero;

        await metadata.writeToFile();

        final jsonFile = File('${tempDir.path}/deep/nested/path/test.json');
        expect(jsonFile.existsSync(), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('SemanticsNodeData', () {
    test('toJson() includes only non-null fields', () {
      const data = SemanticsNodeData(label: 'Submit', role: 'button');

      expect(data.toJson(), {'label': 'Submit', 'role': 'button'});
    });

    test('toJson() includes all fields when present', () {
      const data = SemanticsNodeData(
        label: 'Volume',
        value: '50%',
        hint: 'Adjust volume',
        tooltip: 'Volume control',
        role: 'slider',
        actions: ['increase', 'decrease'],
      );

      expect(data.toJson(), {
        'label': 'Volume',
        'value': '50%',
        'hint': 'Adjust volume',
        'tooltip': 'Volume control',
        'role': 'slider',
        'actions': ['increase', 'decrease'],
      });
    });

    test('toJson() excludes empty actions list', () {
      const data = SemanticsNodeData(label: 'Text', actions: []);

      expect(data.toJson().containsKey('actions'), isFalse);
    });

    test('toJson() returns empty map when all fields are null', () {
      const data = SemanticsNodeData();

      expect(data.toJson(), isEmpty);
    });

    test('fromSemanticsData() extracts label and value', () {
      final semData = _makeSemanticsData(label: 'Hello', value: 'World');

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.label, 'Hello');
      expect(result.value, 'World');
      expect(result.hint, isNull);
      expect(result.role, isNull);
    });

    test('fromSemanticsData() detects button role', () {
      final semData = _makeSemanticsData(
        label: 'Submit',
        flagsCollection: SemanticsFlags(isButton: true),
        actions: SemanticsAction.tap.index,
      );

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.label, 'Submit');
      expect(result.role, 'button');
      expect(result.actions, contains('tap'));
    });

    test('fromSemanticsData() detects checkbox role', () {
      final semData = _makeSemanticsData(
        label: 'Accept terms',
        flagsCollection: SemanticsFlags(isChecked: CheckedState.isTrue),
      );

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.role, 'checkbox');
    });

    test('fromSemanticsData() detects switch role', () {
      final semData = _makeSemanticsData(
        label: 'Dark mode',
        flagsCollection: SemanticsFlags(isToggled: Tristate.isTrue),
      );

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.role, 'switch');
    });

    test('fromSemanticsData() detects header role', () {
      final semData = _makeSemanticsData(
        label: 'Section Title',
        flagsCollection: SemanticsFlags(isHeader: true),
      );

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.role, 'header');
    });

    test('fromSemanticsData() extracts tooltip', () {
      final semData = _makeSemanticsData(
        label: 'Info',
        tooltip: 'More information',
      );

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.tooltip, 'More information');
    });

    test('fromSemanticsData() extracts hint', () {
      final semData = _makeSemanticsData(
        label: 'Search',
        hint: 'Enter search term',
      );

      final result = SemanticsNodeData.fromSemanticsData(semData);
      expect(result.hint, 'Enter search term');
    });
  });
}
