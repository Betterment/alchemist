import 'dart:ui' as ui;

import 'package:alchemist/src/blocked_text_image.dart';
import 'package:alchemist/src/golden_test_adapter.dart';
import 'package:alchemist/src/golden_test_group.dart';
import 'package:alchemist/src/golden_test_scenario.dart';
import 'package:alchemist/src/golden_test_theme.dart';
import 'package:alchemist/src/pumps.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

class FakeWidgetsLocalizations extends DefaultWidgetsLocalizations {}

class FakeLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  @override
  Future<WidgetsLocalizations> load(ui.Locale locale) {
    return SynchronousFuture(FakeWidgetsLocalizations());
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) {
    return false;
  }

  @override
  bool isSupported(ui.Locale locale) => true;
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockRenderObject());
  });

  ThemeData createIdentifiableTheme(String key) {
    final base = ThemeData.fallback();
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyMedium: base.textTheme.bodyMedium!.copyWith(debugLabel: '<!$key!>'),
      ),
    );
  }

  String? identifyTheme(ThemeData theme) {
    final label = theme.textTheme.bodyMedium!.debugLabel!;
    final keyStartIndex = label.indexOf('<!');
    if (keyStartIndex == -1) {
      return null;
    }
    final keyEndIndex = label.indexOf('!>');
    return label.substring(keyStartIndex + 2, keyEndIndex);
  }

  final variantConfigTheme = createIdentifiableTheme('variantTheme');
  final globalConfigTheme = createIdentifiableTheme('globalTheme');
  final contextProvidedTheme = createIdentifiableTheme('contextTheme');

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
        } on TestFailure catch (e) {
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
        bool semanticsEnabled = false,
        TestVariant<Object?> variant = const DefaultTestVariant(),
        dynamic tags,
        int? retry,
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
          () =>
              paintingContext.paintSingleChild(any(that: isA<RenderObject>())),
        ).thenReturn(null);
        paintingContextBuilder = (_, __) => paintingContext;
      });

      testWidgets('draws on painting context', (tester) async {
        const key = ValueKey('Root');
        await tester.pumpWidget(const SizedBox.square(key: key, dimension: 50));
        final finder = find.byKey(key);

        final uiImage = await adapter.getBlockedTextImage(
          finder: finder,
          tester: tester,
        );

        verify(
          () =>
              paintingContext.paintSingleChild(any(that: isA<RenderObject>())),
        );

        expect(uiImage, isA<ui.Image>());
      });

      tearDown(() {
        paintingContextBuilder = defaultPaintingContextBuilder;
      });
    });

    group('pumpGoldenTest', () {
      const adapter = FlutterGoldenTestAdapter();
      GoldenTestGroup buildGroup({Widget? child}) {
        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'scenario',
              child:
                  child ??
                  const SizedBox(width: 100, height: 100, child: Placeholder()),
            ),
          ],
        );
      }

      testWidgets('pumps the provided group', (tester) async {
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 1,
          constraints: const BoxConstraints(),
          obscureFont: false,
          globalConfigTheme: null,
          variantConfigTheme: null,
          goldenTestTheme: null,
          pumpBeforeTest: onlyPumpAndSettle,
          pumpWidget: onlyPumpWidget,
          widget: buildGroup(),
        );

        expect(find.byType(GoldenTestGroup), findsOneWidget);
      });

      testWidgets('resizes surface to fit the tested widget', (tester) async {
        final groupKey = FlutterGoldenTestAdapter.childKey;

        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 1,
          constraints: const BoxConstraints(),
          obscureFont: false,
          globalConfigTheme: null,
          variantConfigTheme: null,
          goldenTestTheme: null,
          pumpBeforeTest: onlyPumpAndSettle,
          pumpWidget: onlyPumpWidget,
          widget: buildGroup(),
        );

        final targetSize = tester.getSize(find.byKey(groupKey));

        expect(tester.view.physicalSize, targetSize);
      });

      testWidgets('sets text scale factor to provided value', (tester) async {
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 2,
          constraints: const BoxConstraints(),
          obscureFont: false,
          globalConfigTheme: null,
          variantConfigTheme: null,
          goldenTestTheme: null,
          pumpBeforeTest: onlyPumpAndSettle,
          pumpWidget: onlyPumpWidget,
          widget: buildGroup(),
        );

        expect(tester.platformDispatcher.textScaleFactor, 2.0);
      });

      group('padding', () {
        testWidgets('default padding for `GoldenTestTheme`', (tester) async {
          await adapter.pumpGoldenTest(
            tester: tester,
            textScaleFactor: 2,
            constraints: const BoxConstraints(),
            obscureFont: false,
            globalConfigTheme: null,
            variantConfigTheme: null,
            goldenTestTheme: GoldenTestTheme.standard(),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
            widget: buildGroup(),
          );

          final box = find.byType(Padding);

          expect(box, findsNWidgets(2));
          expect(tester.widget<Padding>(box.at(0)).padding, EdgeInsets.zero);
          expect(tester.widget<Padding>(box.at(1)).padding, EdgeInsets.zero);
        });
        testWidgets('custom padding on `GoldenTestTheme`', (tester) async {
          await adapter.pumpGoldenTest(
            tester: tester,
            textScaleFactor: 2,
            constraints: const BoxConstraints(),
            obscureFont: false,
            globalConfigTheme: null,
            variantConfigTheme: null,
            goldenTestTheme: GoldenTestTheme(
              backgroundColor: Colors.white,
              borderColor: Colors.black,
              padding: const EdgeInsets.all(16),
              nameTextStyle: const TextStyle(color: Colors.black),
            ),
            pumpBeforeTest: onlyPumpAndSettle,
            pumpWidget: onlyPumpWidget,
            widget: buildGroup(),
          );

          final box = find.byType(Padding);

          expect(box, findsNWidgets(2));
          expect(
            tester.widget<Padding>(box.at(0)).padding,
            const EdgeInsets.all(16),
          );
          expect(
            tester.widget<Padding>(box.at(1)).padding,
            const EdgeInsets.all(16),
          );
        });
      });

      testWidgets('renders FlutterGoldenTestWrapper with provided '
          'obscure font, themes and child arguments', (tester) async {
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 1,
          constraints: const BoxConstraints(),
          obscureFont: true,
          globalConfigTheme: globalConfigTheme,
          variantConfigTheme: variantConfigTheme,
          goldenTestTheme: null,
          pumpBeforeTest: onlyPumpAndSettle,
          pumpWidget: onlyPumpWidget,
          widget: buildGroup(),
        );

        expect(find.byType(FlutterGoldenTestWrapper), findsOneWidget);
        expect(
          tester.widget(find.byType(FlutterGoldenTestWrapper)),
          isA<FlutterGoldenTestWrapper>()
              .having((w) => w.obscureFont, 'obscureFont', isTrue)
              .having(
                (w) => w.globalConfigTheme,
                'globalConfigTheme',
                isA<ThemeData>().having(
                  identifyTheme,
                  'theme key',
                  equals(identifyTheme(globalConfigTheme)),
                ),
              )
              .having(
                (w) => w.variantConfigTheme,
                'variantConfigTheme',
                isA<ThemeData>().having(
                  identifyTheme,
                  'theme key',
                  equals(identifyTheme(variantConfigTheme)),
                ),
              ),
        );
      });

      testWidgets('calls the provided pumpBeforeTest', (tester) async {
        var pumpBeforeTestCalled = false;
        await adapter.pumpGoldenTest(
          tester: tester,
          textScaleFactor: 2,
          constraints: const BoxConstraints(),
          obscureFont: false,
          globalConfigTheme: null,
          variantConfigTheme: null,
          goldenTestTheme: null,
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
          obscureFont: false,
          globalConfigTheme: null,
          variantConfigTheme: null,
          goldenTestTheme: null,
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

  group('FlutterGoldenTestWrapper', () {
    testWidgets('renders child', (tester) async {
      const key = Key('child');

      await tester.pumpWidget(
        const FlutterGoldenTestWrapper(child: Text('test', key: key)),
      );

      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('renders a MediaQuery '
        'based on the current window', (tester) async {
      await tester.pumpWidget(
        const FlutterGoldenTestWrapper(child: Text('test')),
      );

      final windowMediaQuery = MediaQueryData.fromView(
        tester.binding.platformDispatcher.views.first,
      );

      expect(find.byType(MediaQuery), findsOneWidget);
      expect(
        tester.widget(find.byType(MediaQuery)),
        isA<MediaQuery>().having(
          (m) => m.data,
          'data',
          isA<MediaQueryData>().having(
            (m) => m.size,
            'size',
            windowMediaQuery.size,
          ),
        ),
      );
    });

    group('localizations', () {
      testWidgets(
        'includes default material, widgets, and cupertino localizations',
        (tester) async {
          await tester.pumpWidget(
            FlutterGoldenTestWrapper(
              variantConfigTheme: variantConfigTheme,
              globalConfigTheme: globalConfigTheme,
              child: const Text('test'),
            ),
          );

          final context = tester.element(find.text('test'));
          expect(MaterialLocalizations.of(context), isNotNull);
          expect(WidgetsLocalizations.of(context), isNotNull);
          expect(CupertinoLocalizations.of(context), isNotNull);
        },
      );

      testWidgets('does not override inherited locale or localizations', (
        tester,
      ) async {
        const locale = Locale('en', 'US');

        await tester.pumpWidget(
          Localizations(
            locale: locale,
            delegates: [FakeLocalizationsDelegate()],
            child: FlutterGoldenTestWrapper(
              variantConfigTheme: variantConfigTheme,
              globalConfigTheme: globalConfigTheme,
              child: const Text('test'),
            ),
          ),
        );

        final context = tester.element(find.text('test'));
        expect(
          WidgetsLocalizations.of(context),
          isA<FakeWidgetsLocalizations>(),
        );
        expect(Localizations.localeOf(context), same(locale));
        expect(MaterialLocalizations.of(context), isNotNull);
        expect(CupertinoLocalizations.of(context), isNotNull);
      });
    });

    group('provides theme to child that', () {
      Finder findWrapperTheme() {
        return find.descendant(
          of: find.byType(FlutterGoldenTestWrapper),
          matching: find.byType(Theme),
        );
      }

      testWidgets('is set to variant theme when provided', (tester) async {
        await tester.pumpWidget(
          Theme(
            data: contextProvidedTheme,
            child: FlutterGoldenTestWrapper(
              variantConfigTheme: variantConfigTheme,
              globalConfigTheme: globalConfigTheme,
              child: const Text('test'),
            ),
          ),
        );

        expect(
          tester.widget(findWrapperTheme()),
          isA<Theme>().having(
            (w) => w.data,
            'data',
            isA<ThemeData>().having(
              identifyTheme,
              'theme key',
              equals(identifyTheme(variantConfigTheme)),
            ),
          ),
        );
      });

      testWidgets('is set to inherited theme when provided', (tester) async {
        await tester.pumpWidget(
          Theme(
            data: contextProvidedTheme,
            child: FlutterGoldenTestWrapper(
              // Do not provide a variant theme.
              globalConfigTheme: globalConfigTheme,
              child: const Text('test'),
            ),
          ),
        );

        expect(
          tester.widget(findWrapperTheme()),
          isA<Theme>().having(
            (w) => w.data,
            'data',
            isA<ThemeData>().having(
              identifyTheme,
              'theme key',
              equals(identifyTheme(contextProvidedTheme)),
            ),
          ),
        );
      });

      testWidgets('is set to global theme when provided', (tester) async {
        await tester.pumpWidget(
          // Do not provide an inherited theme.
          FlutterGoldenTestWrapper(
            // Do not provide a variant theme.
            globalConfigTheme: globalConfigTheme,
            child: const Text('test'),
          ),
        );

        expect(
          tester.widget(findWrapperTheme()),
          isA<Theme>().having(
            (w) => w.data,
            'data',
            isA<ThemeData>().having(
              identifyTheme,
              'theme key',
              equals(identifyTheme(globalConfigTheme)),
            ),
          ),
        );
      });

      testWidgets('is set to fallback when no theme is provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          // Do not provide an inherited theme.
          const FlutterGoldenTestWrapper(
            // Do not provide a variant theme.
            // Do not provide a global theme.
            child: Text('test'),
          ),
        );

        expect(
          tester.widget(findWrapperTheme()),
          isA<Theme>().having(
            (w) => w.data,
            'data',
            equals(ThemeData.fallback()),
          ),
        );
      });

      testWidgets('has its text obscured '
          'when obscureFont is true', (tester) async {
        const providedFontFamily = 'providedFontFamily';
        const expectedFontFamily =
            GoldenTestThemeDataExtensions.obscuredTextFontFamily;

        await tester.pumpWidget(
          Theme(
            data: ThemeData(fontFamily: providedFontFamily),
            child: const FlutterGoldenTestWrapper(
              obscureFont: true,
              child: Text('test'),
            ),
          ),
        );

        expect(
          tester.widget(findWrapperTheme()),
          isA<Theme>().having(
            (w) => w.data,
            'data',
            isA<ThemeData>().having(
              (theme) => theme.textTheme.bodyMedium!.fontFamily,
              'textTheme.bodyMedium.fontFamily',
              equals(expectedFontFamily),
            ),
          ),
        );
      });

      testWidgets('has alchemist text packages stripped', (tester) async {
        const fontFamilyName = 'fontFamilyName';
        const providedFontFamily = 'packages/alchemist/$fontFamilyName';

        await tester.pumpWidget(
          Theme(
            data: ThemeData(fontFamily: providedFontFamily),
            child: const FlutterGoldenTestWrapper(child: Text('test')),
          ),
        );

        expect(
          tester.widget(findWrapperTheme()),
          isA<Theme>().having(
            (w) => w.data,
            'data',
            isA<ThemeData>().having(
              (theme) => theme.textTheme.bodyMedium!.fontFamily,
              'textTheme.bodyMedium.fontFamily',
              equals(fontFamilyName),
            ),
          ),
        );
      });
    });
  });
}
