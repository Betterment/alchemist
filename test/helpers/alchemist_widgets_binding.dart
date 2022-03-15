import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class AlchemistWidgetsBinding extends AutomatedTestWidgetsFlutterBinding {
  AlchemistWidgetsBinding({
    ImageCache? imageCache,
  }) : _imageCache = imageCache ?? ImageCache();

  final ImageCache _imageCache;

  static WidgetsBinding ensureInitialized() => AlchemistWidgetsBinding();

  @override
  ImageCache createImageCache() => _imageCache;
}
