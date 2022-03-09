import 'package:alchemist/src/golden_test.dart';
import 'package:alchemist/src/pumps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

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
