import 'dart:convert';
import 'dart:typed_data';

import 'package:alchemist/src/golden_test.dart';
import 'package:alchemist/src/pumps.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTestAssetBundle extends TestAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'test.png') {
      return ByteData.view(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAApElEQVR42u3RAQ0AAAjD'
          'MO5fNCCDkC5z0HTVrisFCBABASIgQAQEiIAAAQJEQIAICBABASIgQAREQIAICBABASIg'
          'QAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQARE'
          'QIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAQECBAgAgJEQIAIyPcGFY7H'
          'nV2aPXoAAAAASUVORK5CYII=',
        ).buffer,
      );
    }
    return super.load(key);
  }
}

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds with an asset image',
      fileName: 'asset_image_smoke_test',
      pumpBeforeTest: precacheImages,
      builder: () => DefaultAssetBundle(
        bundle: FakeTestAssetBundle(),
        child: Image.asset('test.png'),
      ),
    );
  });
}
