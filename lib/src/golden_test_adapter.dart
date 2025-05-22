import 'dart:async';
import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The function signature of Flutter test's `testWidgets` function.
typedef TestWidgetsFn =
    FutureOr<void> Function(
      String description,
      Future<void> Function(WidgetTester) callback, {
      bool? skip,
      Timeout? timeout,
      bool semanticsEnabled,
      TestVariant<Object?> variant,
      dynamic tags,
      int? retry,
    });

/// The signature of the `tearDown` and `setUp` test functions.
typedef TestLifecycleFn = void Function(ValueGetter<dynamic>);

/// Function used to invoke an AsyncMatcher and perform an assertion of its
/// result. Typically, this involves an `expectLater` call that verifies
/// an image matches another via the matcher `matchesGoldenFile`.
typedef MatchesGoldenFileInvocation<T> = FutureOr<T> Function();

/// A function which returns a [MatchesGoldenFileInvocation] to compare two
/// golden finders or images.
typedef GoldenFileExpectation =
    MatchesGoldenFileInvocation<void> Function(Object, Object);

/// Default golden file expectation function.
// ignore: prefer_function_declarations_over_variables
GoldenFileExpectation defaultGoldenFileExpectation = (Object a, Object b) =>
    () => expectLater(a, matchesGoldenFile(b));
GoldenFileExpectation _goldenFileExpectationFn = defaultGoldenFileExpectation;

/// {@template golden_file_expectation}
/// A function which performs a test expectation which invokes an asynchronous
/// matcher (e.g. `matchesGoldenFile`).
/// {@endtemplate}
GoldenFileExpectation get goldenFileExpectationFn => _goldenFileExpectationFn;
set goldenFileExpectationFn(GoldenFileExpectation value) =>
    _goldenFileExpectationFn = value;

/// Default testWidgets function that simply points to Flutter's [testWidgets].
TestWidgetsFn defaultTestWidgetsFn = testWidgets;
TestWidgetsFn _testWidgetsFn = defaultTestWidgetsFn;

/// A function to be used in place of `flutter_test`'s `testWidgets` function.
/// The ability to use a stub method here makes it easier to test Alchemist.
TestWidgetsFn get testWidgetsFn => _testWidgetsFn;
set testWidgetsFn(TestWidgetsFn value) => _testWidgetsFn = value;

/// Default setUp function which simply points to Flutter's [setUp].
TestLifecycleFn defaultSetUpFn = setUp;
TestLifecycleFn _setUpFn = defaultSetUpFn;

/// A function to be used in place of `flutter_test`'s `setUp` function.
TestLifecycleFn get setUpFn => _setUpFn;
set setUpFn(TestLifecycleFn value) => _setUpFn = value;

/// Default setUp function which simply points to Flutter's [setUp].
TestLifecycleFn defaultTearDownFn = tearDown;
TestLifecycleFn _tearDownFn = defaultTearDownFn;

/// A function to be used in place of `flutter_test`'s `tearDown` function.
TestLifecycleFn get tearDownFn => _tearDownFn;
set tearDownFn(TestLifecycleFn value) => _tearDownFn = value;

/// A builder function which returns a blocked text painting context, given the
/// [OffsetLayer] layer and [Rect] bounds.
typedef BlockedTextPaintingContextBuilder =
    BlockedTextPaintingContext Function(OffsetLayer layer, Rect bounds);

/// Default blocked text painting context builder which returns a real instance
/// of [BlockedTextPaintingContext].
// ignore: prefer_function_declarations_over_variables
BlockedTextPaintingContextBuilder defaultPaintingContextBuilder =
    (OffsetLayer layer, Rect bounds) => BlockedTextPaintingContext(
      containerLayer: layer,
      estimatedBounds: bounds,
    );
BlockedTextPaintingContextBuilder _paintingContextBuilder =
    defaultPaintingContextBuilder;

/// A function to be used as the [BlockedTextPaintingContextBuilder] for drawing
/// blocked text.
BlockedTextPaintingContextBuilder get paintingContextBuilder =>
    _paintingContextBuilder;
set paintingContextBuilder(BlockedTextPaintingContextBuilder value) =>
    _paintingContextBuilder = value;

/// Golden test adapter interface. Alchemist uses a concrete implementation of
/// this class to perform functions which are tightly coupled to Flutter's test
/// framework, allowing fake implementations to be used for testing Alchemist
/// by itself.
abstract class GoldenTestAdapter {
  /// Create a new [GoldenTestAdapter].
  const GoldenTestAdapter();

  /// A function that forces golden files to be regenerated while
  /// executing the given function [callback]. Afterwards, the flag is reset to
  /// its original value.
  ///
  /// If [forceUpdate] is `true`, the golden files will be regenerated even if
  /// they already exist. Otherwise, the flag is ignored and the function is
  /// executed as usual.
  Future<T> withForceUpdateGoldenFiles<T>({
    required MatchesGoldenFileInvocation<T> callback,
    bool forceUpdate = false,
  });

  /// The function to use for `setUp` calls. By default, this is Flutter's
  /// `tearDown` function.
  TestLifecycleFn get setUp;

  /// The function to use for `tearDown` calls. By default, this is Flutter's
  /// `tearDown` function.
  TestLifecycleFn get tearDown;

  /// A function to use for `testWidgets` calls. By default, this is Flutter's
  /// `testWidgets` function.
  TestWidgetsFn get testWidgets;

  /// {@macro golden_file_expectation}
  GoldenFileExpectation get goldenFileExpectation;

  /// Pumps the given [widget] with the given [tester] for use in golden tests.
  ///
  /// The [rootKey], if provided, will be attached to the top-most [Widget] in
  /// the tree.
  ///
  /// The [textScaleFactor], if provided, sets the text scale size (usually in
  /// a range from 1 to 3).
  ///
  /// The [constraints] tell the builder how large the total surface of the
  /// widget should be. Commonly set to
  /// `BoxConstraints.loose(Size(maxWidth, maxHeight))` to limit the maximum
  /// size of the widget, while allowing it to be smaller if the content allows
  /// for it.
  ///
  /// The provided [globalConfigTheme] and [variantConfigTheme] are used to
  /// determine the appropriate [Theme] to set for the widget being tested. See
  /// [FlutterGoldenTestWrapper] for more details.
  ///
  /// By default, no constraints are passed, but this can be
  /// adjusted to allow for more precise rendering of golden files. If the
  /// max width is unbounded, a default width value will be used as initial
  /// surface size. The same applies to the max height.
  Future<void> pumpGoldenTest({
    required WidgetTester tester,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required bool obscureFont,
    required ThemeData? globalConfigTheme,
    required ThemeData? variantConfigTheme,
    required GoldenTestTheme? goldenTestTheme,
    required PumpAction pumpBeforeTest,
    required PumpWidget pumpWidget,
    required Widget widget,
    Key? rootKey,
  });

  /// Generates an image of the widget at the given [finder] with all text
  /// represented as colored rectangles.
  ///
  /// See [BlockedTextPaintingContext] for more details.
  Future<ui.Image> getBlockedTextImage({
    required Finder finder,
    required WidgetTester tester,
  });
}

/// Default implementation of [GoldenTestAdapter] to allow Alchemist access
/// to the Flutter test framework.
class FlutterGoldenTestAdapter extends GoldenTestAdapter {
  /// Create a new [FlutterGoldenTestAdapter].
  const FlutterGoldenTestAdapter() : super();

  /// Key for the root of the golden test.
  static final rootKey = UniqueKey();

  /// Key for the child container in the golden test.
  static final childKey = UniqueKey();

  @override
  Future<T> withForceUpdateGoldenFiles<T>({
    required MatchesGoldenFileInvocation<T> callback,
    bool forceUpdate = false,
  }) async {
    if (!forceUpdate) {
      return await callback();
    }

    final originalValue = autoUpdateGoldenFiles;
    autoUpdateGoldenFiles = true;
    try {
      return await callback();
    } finally {
      autoUpdateGoldenFiles = originalValue;
    }
  }

  @override
  TestLifecycleFn get setUp => setUpFn;
  @override
  TestLifecycleFn get tearDown => tearDownFn;
  @override
  TestWidgetsFn get testWidgets => testWidgetsFn;
  @override
  GoldenFileExpectation get goldenFileExpectation => goldenFileExpectationFn;

  @override
  Future<void> pumpGoldenTest({
    required WidgetTester tester,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required bool obscureFont,
    required ThemeData? globalConfigTheme,
    required ThemeData? variantConfigTheme,
    required GoldenTestTheme? goldenTestTheme,
    required PumpAction pumpBeforeTest,
    required PumpWidget pumpWidget,
    required Widget widget,
    Key? rootKey,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;

    goldenTestTheme ??= GoldenTestTheme.standard();

    await pumpWidget(
      tester,
      FlutterGoldenTestWrapper(
        key: rootKey,
        obscureFont: obscureFont,
        globalConfigTheme: globalConfigTheme,
        variantConfigTheme: variantConfigTheme,
        goldenTestTheme: goldenTestTheme,
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: Alignment.topLeft,
              child: Builder(
                builder: (context) {
                  return ColoredBox(
                    color: goldenTestTheme!.backgroundColor,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: constraints.minWidth,
                      minHeight: constraints.minHeight,
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                      child: Center(
                        key: childKey,
                        child: Padding(
                          padding: goldenTestTheme.padding,
                          child: widget,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await pumpBeforeTest(tester);

    final childSize = tester.getSize(find.byKey(childKey));

    await tester.binding.setSurfaceSize(childSize);
    tester.view.physicalSize = childSize;

    await tester.pump();
  }

  @override
  Future<ui.Image> getBlockedTextImage({
    required Finder finder,
    required WidgetTester tester,
  }) async {
    var renderObject = tester.renderObject(finder);
    while (!renderObject.isRepaintBoundary) {
      renderObject = renderObject.parent!;
    }
    final layer = renderObject.debugLayer! as OffsetLayer;
    paintingContextBuilder(
      layer,
      renderObject.paintBounds,
    ).paintSingleChild(renderObject);

    return layer.toImage(renderObject.paintBounds);
  }
}

/// {@template _flutter_golden_test_wrapper}
/// Similar to [MaterialApp], this widget is used to bootstrap a basic Flutter
/// application for use in golden tests.
///
/// Using [MaterialApp] may introduce unexpected behavior in tests, and can
/// cause localizations to not be loaded properly. This widget sets up the bare
/// minimum to get the test to run.
///
/// Exposed for internal testing. Do not use this explicitly.
/// {@endtemplate}
@protected
@visibleForTesting
class FlutterGoldenTestWrapper extends StatelessWidget {
  /// {@macro _flutter_golden_test_wrapper}
  const FlutterGoldenTestWrapper({
    required this.child,
    super.key,
    this.globalConfigTheme,
    this.variantConfigTheme,
    this.goldenTestTheme,
    this.obscureFont = false,
  });

  /// The theme provided by the global [AlchemistConfig], if any.
  ///
  /// See [MaterialApp.theme] for more details.
  final ThemeData? globalConfigTheme;

  /// The theme provided by the current variant's [GoldensConfig], if any.
  ///
  /// See [MaterialApp.theme] for more details.
  final ThemeData? variantConfigTheme;

  /// The [GoldenTestTheme] to use when generating golden tests.
  ///
  /// If no [GoldenTestTheme] is provided, the default
  /// [GoldenTestTheme.standard] will be used.
  final GoldenTestTheme? goldenTestTheme;

  /// Whether the default font family of the resolved theme should be set to an
  /// obscured font.
  ///
  /// See [GoldenTestThemeDataExtensions.applyObscuredFontFamily] for more
  /// details.
  final bool obscureFont;

  /// The root widget to wrap.
  ///
  /// See [MaterialApp.home] for more details.
  final Widget child;

  /// Resolves the appropriate theme to use for the current test.
  ///
  /// If [obscureFont] is true, the default font family of the resolved theme
  /// will be set to an obscured font. (See
  /// [GoldenTestThemeDataExtensions.applyObscuredFontFamily] for more details.)
  ///
  /// The returned theme will have its text packages stripped. (See
  /// [GoldenTestThemeDataExtensions.stripTextPackages] for more details.)
  ///
  /// The algorithm is as follows:
  /// - If a [variantConfigTheme] is provided (through a [GoldensConfig]), use
  ///   it.
  /// - Otherwise, if a theme is provided through an [InheritedTheme] (such as
  ///   through an ancestor [MaterialApp] or [Theme] widget), use it.
  /// - Otherwise, if a [globalConfigTheme] is provided through an
  ///   [AlchemistConfig], use it.
  /// - Otherwise, use the [ThemeData.fallback].
  ThemeData _resolveThemeOf(BuildContext context) {
    final hasInheritedTheme =
        context.findAncestorWidgetOfExactType<Theme>() != null;
    final inheritedTheme = hasInheritedTheme ? Theme.of(context) : null;

    var resolvedTheme =
        variantConfigTheme ??
        inheritedTheme ??
        globalConfigTheme ??
        ThemeData.fallback();

    if (obscureFont) {
      resolvedTheme = resolvedTheme.applyObscuredFontFamily();
    }

    if (goldenTestTheme != null) {
      resolvedTheme = resolvedTheme.copyWith(
        extensions: [...resolvedTheme.extensions.values, goldenTestTheme!],
      );
    }

    return resolvedTheme.stripTextPackages();
  }

  @override
  Widget build(BuildContext context) {
    return _LocalizationWrapper(
      child: Theme(
        data: _resolveThemeOf(context),
        child: _NavigatorWrapper(child: child),
      ),
    );
  }
}

class _LocalizationWrapper extends StatelessWidget {
  const _LocalizationWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    final widgetsLocalizations = Localizations.of<WidgetsLocalizations>(
      context,
      WidgetsLocalizations,
    );
    final materialLocalizations = Localizations.of<MaterialLocalizations>(
      context,
      MaterialLocalizations,
    );
    final cupertinoLocalizations = Localizations.of<CupertinoLocalizations>(
      context,
      CupertinoLocalizations,
    );
    final delegates = [
      if (widgetsLocalizations == null) DefaultWidgetsLocalizations.delegate,
      if (materialLocalizations == null) DefaultMaterialLocalizations.delegate,
      if (cupertinoLocalizations == null)
        DefaultCupertinoLocalizations.delegate,
    ];

    if (locale != null) {
      return Localizations.override(
        context: context,
        delegates: delegates,
        child: child,
      );
    } else {
      return Localizations(
        locale: const Locale('en', 'US'),
        delegates: delegates,
        child: child,
      );
    }
  }
}

class _NavigatorWrapper extends StatelessWidget {
  const _NavigatorWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateInitialRoutes: (_, __) => [
        MaterialPageRoute<void>(builder: (context) => child),
      ],
    );
  }
}
