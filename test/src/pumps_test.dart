import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

import '../helpers/helpers.dart';

class MockWidgetTester extends Mock implements WidgetTester {}

Future<bool> _isCached(ImageProvider<Object> image, Finder findImage) async {
  final cacheStatus = await image.obtainCacheStatus(
    configuration: createLocalImageConfiguration(findImage.evaluate().first),
  );
  return cacheStatus?.keepAlive ?? false;
}

extension on CommonFinders {
  Finder fadeInImage(ImageProvider<Object> image) => byWidgetPredicate(
    (widget) => widget is FadeInImage && widget.image == image,
  );

  Finder decorationImage(ImageProvider<Object> image) =>
      byWidgetPredicate((widget) {
        if (widget is DecoratedBox) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration && decoration.image?.image == image) {
            return true;
          }
        }
        return false;
      });
}

void main() {
  group('Custom pump functions', () {
    late WidgetTester tester;

    setUpAll(() {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(EnginePhase.sendSemanticsUpdate);
    });

    setUp(() {
      tester = MockWidgetTester();
      when(() => tester.pump(any(), any())).thenAnswer((_) async {});
      when(
        () => tester.pumpAndSettle(any(), any(), any()),
      ).thenAnswer((_) async => 1);
    });

    group('pumpNTimes', () {
      test('calls pump the given amount of times', () async {
        final pump = pumpNTimes(3);
        await pump(tester);

        verify(() => tester.pump()).called(3);
      });

      test('provides the given duration to the pump call', () async {
        const duration = Duration(milliseconds: 123);
        final pump = pumpNTimes(3, duration);
        await pump(tester);

        verify(() => tester.pump(duration)).called(3);
      });
    });

    group('pumpOnce', () {
      test('calls pump once', () async {
        await pumpOnce(tester);

        verify(() => tester.pump()).called(1);
      });
    });

    group('onlyPumpAndSettle', () {
      test('calls pumpAndSettle', () async {
        await onlyPumpAndSettle(tester);

        verify(() => tester.pumpAndSettle()).called(1);
      });
    });

    group('precacheImages', () {
      const networkImage = NetworkImage('https://fakeurl.com/image.png');
      const assetImage = AssetImage('path.png');
      final memoryImage = MemoryImage(redPixelImage);

      testWidgets(
        'caches all Image widgets',
        (tester) => mockNetworkImages(() async {
          await tester.pumpWidget(
            DefaultAssetBundle(
              bundle: FakeTestAssetBundle(),
              child: Column(
                children: [
                  const Image(image: networkImage),
                  const Image(image: assetImage),
                  Image(image: memoryImage),
                ],
              ),
            ),
          );
          await precacheImages(tester);

          await expectLater(
            _isCached(networkImage, find.image(networkImage)),
            completion(isTrue),
          );
          await expectLater(
            _isCached(assetImage, find.image(assetImage)),
            completion(isTrue),
          );
          await expectLater(
            _isCached(memoryImage, find.image(memoryImage)),
            completion(isTrue),
          );
        }),
      );

      testWidgets(
        'caches all FadeInImage widgets',
        (tester) => mockNetworkImages(() async {
          await tester.pumpWidget(
            DefaultAssetBundle(
              bundle: FakeTestAssetBundle(),
              child: Column(
                children: [
                  FadeInImage(
                    image: networkImage,
                    placeholder: MemoryImage(redPixelImage),
                  ),
                  FadeInImage(
                    image: assetImage,
                    placeholder: MemoryImage(redPixelImage),
                  ),
                  FadeInImage(
                    image: memoryImage,
                    placeholder: MemoryImage(redPixelImage),
                  ),
                ],
              ),
            ),
          );
          await precacheImages(tester);

          await expectLater(
            _isCached(networkImage, find.fadeInImage(networkImage)),
            completion(isTrue),
          );
          await expectLater(
            _isCached(assetImage, find.fadeInImage(assetImage)),
            completion(isTrue),
          );
          await expectLater(
            _isCached(memoryImage, find.fadeInImage(memoryImage)),
            completion(isTrue),
          );
        }),
      );

      testWidgets(
        'caches all DecoratedBox widgets',
        (tester) => mockNetworkImages(() async {
          await tester.pumpWidget(
            DefaultAssetBundle(
              bundle: FakeTestAssetBundle(),
              child: Column(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: networkImage),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: assetImage),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: memoryImage),
                    ),
                  ),
                ],
              ),
            ),
          );
          await precacheImages(tester);

          await expectLater(
            _isCached(networkImage, find.decorationImage(networkImage)),
            completion(isTrue),
          );
          await expectLater(
            _isCached(assetImage, find.decorationImage(assetImage)),
            completion(isTrue),
          );
          await expectLater(
            _isCached(memoryImage, find.decorationImage(memoryImage)),
            completion(isTrue),
          );
        }),
      );
    });
  });
}
