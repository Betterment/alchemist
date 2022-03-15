import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

class NetworkImageAssetBundleThatDoesNothing extends TestAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return ByteData(0);
  }
}

final imageCache = ImageCache();

class CustomWidgetsBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  ImageCache createImageCache() {
    return imageCache;
  }

  static WidgetsBinding ensureInitialized() => CustomWidgetsBinding();
}

void main() {
  // We need to clear out images from the cache, which requires us to
  // initialize a custom widgets binding.
  CustomWidgetsBinding.ensureInitialized();

  group('smoke test', () {
    goldenTest(
      'succeeds with a network image',
      fileName: 'network_image_smoke_test',
      pumpWidget: (tester, widget) async {
        imageCache.clear();
        await mockNetworkImages(
          () => tester.pumpWidget(
            DefaultAssetBundle(
              bundle: NetworkImageAssetBundleThatDoesNothing(),
              child: widget,
            ),
          ),
        );
      },
      builder: () => Image.network('https://fakeurl.com/image.png'),
    );
  });
}
