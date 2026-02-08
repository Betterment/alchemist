import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState, Rect, Size, Tristate;

import 'package:flutter/semantics.dart';

/// Metadata for a single scenario within a golden test.
///
/// Contains the scenario name, pixel bounds, and optionally
/// semantics tree data.
class ScenarioMetadata {
  /// Creates a [ScenarioMetadata] with the given [name] and [bounds].
  ScenarioMetadata({
    required this.name,
    required this.bounds,
    this.semantics,
  });

  /// The name of the scenario (matches `GoldenTestScenario.name`).
  final String name;

  /// The pixel bounds of the scenario in the golden image.
  final Rect bounds;

  /// Optional semantics tree data for this scenario.
  final List<SemanticsNodeData>? semantics;

  /// Serializes this metadata to a JSON-compatible map.
  ///
  /// Bounds are truncated to integers since they represent pixels.
  /// The `semantics` key is only included when non-null and non-empty.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'x': bounds.left.truncate(),
      'y': bounds.top.truncate(),
      'w': bounds.width.truncate(),
      'h': bounds.height.truncate(),
    };

    if (semantics != null && semantics!.isNotEmpty) {
      json['semantics'] = semantics!.map((s) => s.toJson()).toList();
    }

    return json;
  }
}

/// Metadata for a complete golden test image.
///
/// Contains the golden file path, image dimensions, and a list of
/// [ScenarioMetadata] entries for each scenario in the image.
class GoldenMetadata {
  /// Creates a [GoldenMetadata] for the given [goldenPath].
  GoldenMetadata({required this.goldenPath});

  /// The golden file path (String or Uri).
  final Object goldenPath;

  /// Image dimensions, set after capture.
  Size imageSize = Size.zero;

  /// The scenarios in this golden test.
  final List<ScenarioMetadata> scenarios = [];

  /// Adds a scenario with the given [name], [bounds], and optional
  /// [semantics].
  void addScenario({
    required String name,
    required Rect bounds,
    List<SemanticsNodeData>? semantics,
  }) {
    scenarios.add(
      ScenarioMetadata(name: name, bounds: bounds, semantics: semantics),
    );
  }

  /// Serializes this metadata to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'image': {
        'w': imageSize.width.truncate(),
        'h': imageSize.height.truncate(),
      },
      'scenarios': scenarios.map((s) => s.toJson()).toList(),
    };
  }

  /// Derives the JSON file path from [goldenPath].
  String get jsonPath {
    final path =
        goldenPath is Uri
            ? (goldenPath as Uri).toFilePath()
            : goldenPath as String;
    return path.replaceAll(RegExp(r'\.png$'), '.json');
  }

  /// Writes this metadata to a JSON file alongside the golden image.
  Future<void> writeToFile() async {
    final file = File(jsonPath);
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(toJson()));
  }
}

/// Data extracted from a single [SemanticsNode].
///
/// This is a pure data class that does not depend on Flutter's
/// widget or rendering layer.
class SemanticsNodeData {
  /// Creates a [SemanticsNodeData] with the given fields.
  const SemanticsNodeData({
    this.label,
    this.value,
    this.hint,
    this.tooltip,
    this.role,
    this.actions,
  });

  /// Creates a [SemanticsNodeData] from Flutter's [SemanticsData].
  factory SemanticsNodeData.fromSemanticsData(SemanticsData data) {
    return SemanticsNodeData(
      label: data.label.isNotEmpty ? data.label : null,
      value: data.value.isNotEmpty ? data.value : null,
      hint: data.hint.isNotEmpty ? data.hint : null,
      tooltip: data.tooltip.isNotEmpty ? data.tooltip : null,
      role: _detectRole(data),
      actions: _detectActions(data),
    );
  }

  /// The accessibility label.
  final String? label;

  /// The current value.
  final String? value;

  /// The usage hint for screen readers.
  final String? hint;

  /// The tooltip text.
  final String? tooltip;

  /// The semantic role derived from [SemanticsFlag]s.
  final String? role;

  /// Available actions (tap, longPress, etc.).
  final List<String>? actions;

  /// Serializes to JSON, omitting null fields and empty action lists.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (label != null) json['label'] = label;
    if (value != null) json['value'] = value;
    if (hint != null) json['hint'] = hint;
    if (tooltip != null) json['tooltip'] = tooltip;
    if (role != null) json['role'] = role;
    if (actions != null && actions!.isNotEmpty) json['actions'] = actions;
    return json;
  }

  static String? _detectRole(SemanticsData data) {
    final flags = data.flagsCollection;
    if (flags.isButton) return 'button';
    if (flags.isTextField) return 'textField';
    if (flags.isHeader) return 'header';
    if (flags.isLink) return 'link';
    if (flags.isSlider) return 'slider';
    if (flags.isImage) return 'image';
    if (flags.isChecked != CheckedState.none) return 'checkbox';
    if (flags.isToggled != Tristate.none) return 'switch';
    return null;
  }

  static List<String>? _detectActions(SemanticsData data) {
    final result = <String>[];
    if (data.hasAction(SemanticsAction.tap)) result.add('tap');
    if (data.hasAction(SemanticsAction.longPress)) result.add('longPress');
    if (data.hasAction(SemanticsAction.scrollLeft)) result.add('scrollLeft');
    if (data.hasAction(SemanticsAction.scrollRight)) result.add('scrollRight');
    if (data.hasAction(SemanticsAction.scrollUp)) result.add('scrollUp');
    if (data.hasAction(SemanticsAction.scrollDown)) result.add('scrollDown');
    if (data.hasAction(SemanticsAction.increase)) result.add('increase');
    if (data.hasAction(SemanticsAction.decrease)) result.add('decrease');
    if (data.hasAction(SemanticsAction.copy)) result.add('copy');
    if (data.hasAction(SemanticsAction.cut)) result.add('cut');
    if (data.hasAction(SemanticsAction.paste)) result.add('paste');
    return result.isEmpty ? null : result;
  }
}
