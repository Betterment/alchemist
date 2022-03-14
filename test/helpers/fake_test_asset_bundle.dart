import 'dart:convert';
import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';

final redPixelImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAApElEQVR42u3RAQ0AAAjD'
  'MO5fNCCDkC5z0HTVrisFCBABASIgQAQEiIAAAQJEQIAICBABASIgQAREQIAICBABASIg'
  'QAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQARE'
  'QIAICBABASIgQAREQIAICBABASIgQAREQIAICBABASIgQAQECBAgAgJEQIAIyPcGFY7H'
  'nV2aPXoAAAAASUVORK5CYII=',
);

class FakeTestAssetBundle extends TestAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('png')) {
      return ByteData.view(redPixelImage.buffer);
    }
    return super.load(key);
  }
}
