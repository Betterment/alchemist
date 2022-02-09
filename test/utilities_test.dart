import 'dart:async';
import 'dart:convert';

import 'package:alchemist/src/golden_test_group.dart';
import 'package:alchemist/src/golden_test_scenario.dart';
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

    group('pumpGoldenTest', () {
      GoldenTestGroup buildGroup({
        Widget? child,
      }) {
        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'scenario',
              child: child ??
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: Placeholder(),
                  ),
            ),
          ],
        );
      }

      testWidgets(
        'pumps the provided group',
        (tester) async {
          await tester.pumpGoldenTest(
            textScaleFactor: 1,
            constraints: const BoxConstraints(),
            theme: ThemeData.light(),
            widget: buildGroup(),
          );

          expect(find.byType(GoldenTestGroup), findsOneWidget);
        },
      );

      testWidgets(
        'sets surface size to constraints '
        'when constraints are tight',
        (tester) async {
          const rootKey = Key('root');
          const providedSize = Size(1000, 1000);

          await tester.pumpGoldenTest(
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: BoxConstraints.tight(providedSize),
            theme: ThemeData.light(),
            widget: buildGroup(),
          );

          expect(tester.binding.window.physicalSize, providedSize);

          final rootWidgetSize = tester.getSize(find.byKey(rootKey));
          expect(rootWidgetSize, providedSize);
        },
      );

      testWidgets(
        'attempts to resize surface to fit '
        'the group when constraints are loose',
        (tester) async {
          const rootKey = Key('root');
          const groupKey = Key('golden-test-child-parent');

          await tester.pumpGoldenTest(
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: const BoxConstraints(),
            theme: ThemeData.light(),
            widget: buildGroup(),
          );

          final targetSize = tester.getSize(find.byKey(groupKey));

          expect(tester.binding.window.physicalSize, targetSize);

          final rootWidgetSize = tester.getSize(find.byKey(rootKey));
          expect(rootWidgetSize, targetSize);
        },
      );

      testWidgets(
        'does not resize surface to a '
        'smaller size than the minimum size',
        (tester) async {
          const rootKey = Key('root');
          const groupKey = Key('golden-test-child-parent');

          const minSize = Size(1000, 1000);

          await tester.pumpGoldenTest(
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: BoxConstraints(
              minWidth: minSize.width,
              minHeight: minSize.height,
            ),
            theme: ThemeData.light(),
            widget: buildGroup(),
          );

          final groupSize = tester.getSize(find.byKey(groupKey));
          // Make sure the test is set up properly so that the logic can be
          // asserted correctly. This test is useless if the group's size is
          // larger than the minimum size.
          if (groupSize.width > minSize.width ||
              groupSize.height > minSize.height) {
            fail(
              'The size of the rendered group is larger than the minimum '
              'size constraint passed to the pumpGoldenTest function, '
              'making this test useless.',
            );
          }

          expect(tester.binding.window.physicalSize, minSize);

          final rootWidgetSize = tester.getSize(find.byKey(rootKey));
          expect(rootWidgetSize, minSize);
        },
      );

      testWidgets(
        'does not resize surface to a '
        'larger size than the maximum size',
        (tester) async {
          const rootKey = Key('root');

          const maxSize = Size(150, 150);

          await tester.pumpGoldenTest(
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: BoxConstraints(
              maxWidth: maxSize.width,
              maxHeight: maxSize.height,
            ),
            theme: ThemeData.light(),
            widget: buildGroup(),
          );

          expect(tester.binding.window.physicalSize, maxSize);

          final rootWidgetSize = tester.getSize(find.byKey(rootKey));
          expect(rootWidgetSize, maxSize);
        },
      );

      testWidgets('sets text scale factor to provided value', (tester) async {
        await tester.pumpGoldenTest(
          textScaleFactor: 2,
          constraints: const BoxConstraints(),
          theme: ThemeData.light(),
          widget: buildGroup(),
        );

        expect(tester.binding.window.textScaleFactor, 2.0);
      });

      testWidgets(
        'sets theme to provided value '
        'with package names stripped',
        (tester) async {
          final theme = ThemeData(
            primaryColor: Colors.blue,
            textTheme: const TextTheme(
              bodyText2: TextStyle(
                fontFamily: 'packages/some_package/Roboto',
              ),
            ),
          );

          await tester.pumpGoldenTest(
            textScaleFactor: 1,
            constraints: const BoxConstraints(),
            theme: theme,
            widget: buildGroup(),
          );

          expect(
            tester.widget(find.byType(MaterialApp)),
            isA<MaterialApp>().having(
              (w) => w.theme,
              'theme',
              isA<ThemeData>()
                  .having(
                    (t) => t.primaryColor,
                    'primaryColor',
                    Colors.blue,
                  )
                  .having(
                    (t) => t.textTheme,
                    'textTheme',
                    isA<TextTheme>().having(
                      (t) => t.bodyText2,
                      'bodyText2',
                      isA<TextStyle>().having(
                        (t) => t.fontFamily,
                        'fontFamily',
                        'Roboto',
                      ),
                    ),
                  ),
            ),
          );
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
      ServicesBinding.instance!.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async => message,
      );
    });

    tearDown(() {
      ServicesBinding.instance!.defaultBinaryMessenger.setMockMessageHandler(
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
