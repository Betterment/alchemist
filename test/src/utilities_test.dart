import 'dart:async';
import 'dart:convert';

import 'package:alchemist/src/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTestGesture extends Mock implements TestGesture {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoldenTestWidgetTesterExtensions', () {
    group('pressAll', () {
      Widget buildBoilerplate({
        required Widget child,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: child,
          ),
        );
      }

      testWidgets(
          'print warning message '
          'when no widget matches the given finder', (tester) async {
        final printLogs = <String>[];

        await tester.pumpWidget(
          buildBoilerplate(
            child: const Text('target'),
          ),
        );

        await runZoned(
          () async {
            await tester.pressAll(find.text('does not exist'));
          },
          zoneSpecification: ZoneSpecification(
            print: (_, __, ___, line) {
              printLogs.add(line);
            },
          ),
        );

        expect(
          printLogs,
          [
            '''
No widgets found that match finder: zero widgets with text "does not exist" (ignoring offstage widgets).
No gestures will be performed.

If this is intentional, consider not calling this method
to avoid unnecessary overhead.''',
          ],
        );
      });

      testWidgets(
        'keeps button pressed while calling provided function '
        'and releases it afterwards',
        (tester) async {
          final pointerDownEvents = <PointerDownEvent>[];
          final pointerUpEvents = <PointerUpEvent>[];

          await tester.pumpWidget(
            buildBoilerplate(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: pointerDownEvents.add,
                onPointerUp: pointerUpEvents.add,
                child: const Text('target'),
              ),
            ),
          );

          final gestures = await tester.pressAll(find.text('target'));
          expect(pointerDownEvents.length, 1);
          expect(pointerUpEvents.length, 0);

          for (final gesture in gestures) {
            await gesture.up();
          }

          expect(pointerDownEvents.length, 1);
          expect(pointerUpEvents.length, 1);
        },
      );
    });
  });

  group('GoldenTestThemeDataExtensions', () {
    test('stripTextPackages remove package prefix from all textTheme styles',
        () {
      const fontFamilyBefore = 'packages/package_name/dir1/dir2';
      const fontFamilyAfter = 'dir1/dir2';

      final base = ThemeData();
      final themeBefore = base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: fontFamilyBefore,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          extendedTextStyle: TextStyle(
            fontFamily: fontFamilyBefore,
          ),
        ),
      );
      final themeAfter = themeBefore.stripTextPackages();

      final allStylesAfter = [
        themeAfter.textTheme.headline1,
        themeAfter.textTheme.headline2,
        themeAfter.textTheme.headline3,
        themeAfter.textTheme.headline4,
        themeAfter.textTheme.headline5,
        themeAfter.textTheme.headline6,
        themeAfter.textTheme.subtitle1,
        themeAfter.textTheme.subtitle2,
        themeAfter.textTheme.bodyText1,
        themeAfter.textTheme.bodyText2,
        themeAfter.textTheme.caption,
        themeAfter.textTheme.button,
        themeAfter.textTheme.overline,
        themeAfter.floatingActionButtonTheme.extendedTextStyle,
      ];

      expect(
        allStylesAfter,
        everyElement(
          isA<TextStyle>().having(
            (style) => style.fontFamily,
            'fontFamily',
            fontFamilyAfter,
          ),
        ),
      );
    });
  });

  group('GoldenTestTextStyleExtensions', () {
    test('stripPackage removes package prefix from style', () {
      const fontFamilyBefore = 'packages/package_name/dir1/dir2';
      const fontFamilyAfter = 'dir1/dir2';

      const styleBefore = TextStyle(fontFamily: fontFamilyBefore);
      final styleAfter = styleBefore.stripPackage();

      expect(
        styleAfter,
        isA<TextStyle>().having(
          (style) => style.fontFamily,
          'fontFamily',
          fontFamilyAfter,
        ),
      );
    });
  });

  group('TestAssetBundle', () {
    setUp(() {
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async => message,
      );
    });

    tearDown(() {
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      );
    });

    test('load method attempts to load asset from root bundle', () async {
      const key = 'some/path/asset.png';
      final encoded = utf8.encoder.convert(Uri(path: Uri.encodeFull(key)).path);

      expect(
        TestAssetBundle().load(key),
        completion(
          isA<ByteData>().having(
            (b) => b.buffer.asUint8List(),
            'buffer.asUint8List()',
            equals(encoded),
          ),
        ),
      );
    });

    test('loadString method attempts to load asset from root bundle', () async {
      const key = 'some/path/asset.png';

      expect(
        TestAssetBundle().loadString(key),
        completion(equals(key)),
      );
    });
  });

  group('GoldenTestGestureIterableExtensions', () {
    late TestGesture gesture1;
    late TestGesture gesture2;
    late TestGesture gesture3;

    late List<TestGesture> gestures;

    setUp(() {
      gesture1 = MockTestGesture();
      gesture2 = MockTestGesture();
      gesture3 = MockTestGesture();

      gestures = [gesture1, gesture2, gesture3]..forEach((gesture) {
          when(() => gesture.up()).thenAnswer((_) async {});
        });
    });

    test('releaseAll releases all gestures in list', () async {
      await gestures.releaseAll();

      verify(() => gesture1.up()).called(1);
      verify(() => gesture2.up()).called(1);
      verify(() => gesture3.up()).called(1);
    });
  });
}
