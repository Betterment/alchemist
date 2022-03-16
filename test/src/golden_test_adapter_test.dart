import 'dart:ui' as ui;

import 'package:alchemist/src/blocked_text_image.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_group.dart';
import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:alchemist/src/pumps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBlockedPaintingContext extends Mock
    implements BlockedTextPaintingContext {}

class MockRenderObject extends Mock implements RenderObject {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FakeRenderObject';
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockRenderObject());
  });
  group('overrides', () {
    group('goldenFileExpectationFn', () {
      MatchesGoldenFileInvocation<void> customExpectation(Object a, Object b) =>
          () => null;

      test('overrides value', () {
        goldenFileExpectationFn = customExpectation;
        expect(goldenFileExpectationFn, customExpectation);
        goldenFileExpectationFn = defaultGoldenFileExpectation;
      });

      test('original value invokes matchesGoldenFile', () async {
        try {
          goldenFileExpectationFn(1, 2);
          fail('expected matchesGoldenFile to be invoked');
        } catch (e) {
          expect(
            e,
            isA<TestFailure>().having(
              (testFailure) => testFailure.message,
              'message',
              contains('matchesGoldenFile'),
            ),
          );
        }
      });
    });

    group('testWidgetsFn', () {
      void customTestWidgets(
        String description,
        Future<void> Function(WidgetTester) callback, {
        bool? skip,
        Timeout? timeout,
        Duration? initialTimeout,
        bool semanticsEnabled = false,
        TestVariant<Object?> variant = const DefaultTestVariant(),
        dynamic tags,
      }) {}

      test('overrides value', () {
        testWidgetsFn = customTestWidgets;
        expect(testWidgetsFn, customTestWidgets);
        testWidgetsFn = defaultTestWidgetsFn;
      });
    });

    group('setUpFn', () {
      void customSetUp(dynamic Function() body) {}

      test('overrides value', () {
        setUpFn = customSetUp;
        expect(setUpFn, customSetUp);
        setUpFn = defaultSetUpFn;
      });
    });

    group('tearDownFn', () {
      void customTearDown(dynamic Function() body) {}

      test('overrides value', () {
        tearDownFn = customTearDown;
        expect(tearDownFn, customTearDown);
        tearDownFn = defaultTearDownFn;
      });
    });
  });

  group('FlutterGoldenTestAdapter', () {
    group('withForceUpdateGoldenFiles', () {
      const adapter = FlutterGoldenTestAdapter();
      final originalAutoUpdateGoldenFiles = autoUpdateGoldenFiles;

      test("doesn't change autoUpdateGoldenFiles when false", () async {
        var called = false;
        autoUpdateGoldenFiles = false;
        await adapter.withForceUpdateGoldenFiles(
          callback: () {
            expect(autoUpdateGoldenFiles, false);
            called = true;
          },
        );
        expect(called, isTrue);
        expect(autoUpdateGoldenFiles, false);
      });

      test('calls callback with value when true', () async {
        var called = false;
        autoUpdateGoldenFiles = false;
        await adapter.withForceUpdateGoldenFiles(
          forceUpdate: true,
          callback: () {
            expect(autoUpdateGoldenFiles, true);
            called = true;
          },
        );
        expect(called, isTrue);
        expect(autoUpdateGoldenFiles, false);
      });

      tearDownAll(() {
        autoUpdateGoldenFiles = originalAutoUpdateGoldenFiles;
      });
    });

    group('test framework functions are exposed', () {
      const adapter = FlutterGoldenTestAdapter();

      test('testWidgets', () {
        expect(adapter.testWidgets, testWidgetsFn);
      });

      test('setUp', () {
        expect(adapter.setUp, setUpFn);
      });

      test('tearDown', () {
        expect(adapter.tearDown, tearDownFn);
      });

      test('goldenFileExpectation', () {
        expect(adapter.goldenFileExpectation, goldenFileExpectationFn);
      });
    });

    group('getBlockedTextImage', () {
      const adapter = FlutterGoldenTestAdapter();
      late final BlockedTextPaintingContext paintingContext;

      setUp(() {
        paintingContext = MockBlockedPaintingContext();
        when(
          () => paintingContext.paintSingleChild(
            any(that: isA<RenderObject>()),
          ),
        ).thenReturn(null);
        paintingContextBuilder = (_, __) => paintingContext;
      });

      testWidgets('draws on painting context', (tester) async {
        const key = ValueKey('Root');
        await tester.pumpWidget(
          const SizedBox.square(key: key, dimension: 50),
        );
        final finder = find.byKey(key);

        final uiImage =
            await adapter.getBlockedTextImage(finder: finder, tester: tester);

        verify(
          () => paintingContext.paintSingleChild(
            any(that: isA<RenderObject>()),
          ),
        );

        expect(uiImage, isA<ui.Image>());
      });

      tearDown(() {
        paintingContextBuilder = defaultPaintingContextBuilder;
      });
    });

    group('pumpGoldenTest', () {
      const adapter = FlutterGoldenTestAdapter();
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
          await adapter.pumpGoldenTest(
            tester: tester,
            textScaleFactor: 1,
            constraints: const BoxConstraints(),
            theme: ThemeData.light(),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
            widget: buildGroup(),
          );

          expect(find.byType(GoldenTestGroup), findsOneWidget);
        },
      );

      testWidgets(
        'sets surface size to constraints '
        'when constraints are tight',
        (tester) async {
          final rootKey = FlutterGoldenTestAdapter.rootKey;
          const providedSize = Size(1000, 1000);

          await adapter.pumpGoldenTest(
            tester: tester,
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: BoxConstraints.tight(providedSize),
            theme: ThemeData.light(),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
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
          final rootKey = FlutterGoldenTestAdapter.rootKey;
          final groupKey = FlutterGoldenTestAdapter.childKey;

          await adapter.pumpGoldenTest(
            tester: tester,
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: const BoxConstraints(),
            theme: ThemeData.light(),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
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
          final rootKey = FlutterGoldenTestAdapter.rootKey;
          final groupKey = FlutterGoldenTestAdapter.childKey;

          const minSize = Size(1000, 1000);

          await adapter.pumpGoldenTest(
            tester: tester,
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: BoxConstraints(
              minWidth: minSize.width,
              minHeight: minSize.height,
            ),
            theme: ThemeData.light(),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
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
          final rootKey = FlutterGoldenTestAdapter.rootKey;

          const maxSize = Size(150, 150);

          await adapter.pumpGoldenTest(
            tester: tester,
            rootKey: rootKey,
            textScaleFactor: 1,
            constraints: BoxConstraints(
              maxWidth: maxSize.width,
              maxHeight: maxSize.height,
            ),
            theme: ThemeData.light(),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
            widget: buildGroup(),
          );

          expect(tester.binding.window.physicalSize, maxSize);

          final rootWidgetSize = tester.getSize(find.byKey(rootKey));
          expect(rootWidgetSize, maxSize);
        },
      );

      testWidgets('sets text scale factor to provided value', (tester) async {
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 2,
          constraints: const BoxConstraints(),
          theme: ThemeData.light(),
          pumpBeforeTest: onlyPumpAndSettle,
          pumpWidget: onlyPumpWidget,
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

          await adapter.pumpGoldenTest(
            tester: tester,
            textScaleFactor: 1,
            constraints: const BoxConstraints(),
            theme: theme,
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
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

      testWidgets('calls the provided pumpBeforeTest', (tester) async {
        var pumpBeforeTestCalled = false;
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 2,
          constraints: const BoxConstraints(),
          theme: ThemeData.light(),
          pumpBeforeTest: (_) async => pumpBeforeTestCalled = true,
          pumpWidget: onlyPumpWidget,
          widget: buildGroup(),
        );

        expect(pumpBeforeTestCalled, isTrue);
      });

      testWidgets('calls the provided pumpWidget', (tester) async {
        var pumpWidgetCalled = false;
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 2,
          constraints: const BoxConstraints(),
          theme: ThemeData.light(),
          pumpBeforeTest: onlyPumpAndSettle,
          pumpWidget: (tester, widget) async {
            await onlyPumpWidget(tester, widget);
            pumpWidgetCalled = true;
          },
          widget: buildGroup(),
        );

        expect(pumpWidgetCalled, isTrue);
      });
    });
  });
}
