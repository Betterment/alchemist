import 'dart:async';
import 'dart:ui' as ui;

import 'package:alchemist/src/blocked_text_image.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The function signature of Flutter test's `testWidgets` function.
typedef TestWidgetsFn = FutureOr<void> Function(
  String description,
  Future<void> Function(WidgetTester) callback, {
  bool? skip,
  Timeout? timeout,
  Duration? initialTimeout,
  bool semanticsEnabled,
  TestVariant<Object?> variant,
  dynamic tags,
});

/// The signature of the `tearDown` and `setUp` test functions.
typedef TestLifecycleFn = void Function(ValueGetter<dynamic>);

/// Function used to invoke an AsyncMatcher and perform an assertion of its
/// result. Typically, this involves an `expectLater` call that verifies
/// an image matches another via the matcher `matchesGoldenFile`.
typedef MatchesGoldenFileInvocation<T> = FutureOr<T> Function();

/// A function which returns a [MatchesGoldenFileInvocation] to compare two
/// golden finders or images.
typedef GoldenFileExpectation = MatchesGoldenFileInvocation<void> Function(
  Object,
  Object,
);

/// Default golden file expectation function.
// ignore: prefer_function_declarations_over_variables
GoldenFileExpectation defaultGoldenFileExpectation =
    (Object a, Object b) => () => expectLater(a, matchesGoldenFile(b));
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
typedef BlockedTextPaintingContextBuilder = BlockedTextPaintingContext Function(
  OffsetLayer layer,
  Rect bounds,
);

/// Default blocked text painting context builder which returns a real instance
/// of [BlockedTextPaintingContext].
// ignore: prefer_function_declarations_over_variables
BlockedTextPaintingContextBuilder defaultPaintingContextBuilder = (
  OffsetLayer layer,
  Rect bounds,
) =>
    BlockedTextPaintingContext(containerLayer: layer, estimatedBounds: bounds);
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
    bool forceUpdate = false,
    required MatchesGoldenFileInvocation<T> callback,
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
  /// The provided [theme] will be given to the [MaterialApp] at the top of the
  /// widget tree.
  ///
  /// By default, no constraints are passed, but this can be
  /// adjusted to allow for more precise rendering of golden files. If the
  /// max width is unbounded, a default width value will be used as initial
  /// surface size. The same applies to the max height.
  Future<void> pumpGoldenTest({
    Key? rootKey,
    required WidgetTester tester,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required ThemeData theme,
    required Widget widget,
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
    bool forceUpdate = false,
    required MatchesGoldenFileInvocation<T> callback,
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
    Key? rootKey,
    required WidgetTester tester,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required ThemeData theme,
    required Widget widget,
  }) async {
    final initialSize = Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : 2000,
      constraints.hasBoundedHeight ? constraints.maxHeight : 2000,
    );
    await tester.binding.setSurfaceSize(initialSize);
    tester.binding.window.physicalSizeTestValue = initialSize;

    tester.binding.window.devicePixelRatioTestValue = 1.0;
    tester.binding.window.textScaleFactorTestValue = textScaleFactor;

    await tester.pumpWidget(
      MaterialApp(
        key: rootKey,
        theme: theme.stripTextPackages(),
        debugShowCheckedModeBanner: false,
        supportedLocales: const [Locale('en')],
        builder: (context, _) {
          return DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: Material(
              type: MaterialType.transparency,
              child: Align(
                alignment: Alignment.topLeft,
                child: ColoredBox(
                  color: theme.colorScheme.background,
                  child: Padding(
                    key: childKey,
                    padding: const EdgeInsets.all(8),
                    child: widget,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final shouldTryResize = !constraints.isTight;

    if (shouldTryResize) {
      final childSize = tester.getSize(find.byKey(childKey));
      final newSize = Size(
        childSize.width.clamp(constraints.minWidth, constraints.maxWidth),
        childSize.height.clamp(constraints.minHeight, constraints.maxHeight),
      );
      if (newSize != initialSize) {
        await tester.binding.setSurfaceSize(newSize);
        tester.binding.window.physicalSizeTestValue = newSize;
      }
    }

    await tester.pump();
  }

  @override
  Future<ui.Image> getBlockedTextImage({
    required Finder finder,
    required WidgetTester tester,
  }) async {
    var renderObject = tester.renderObject(finder);
    while (!renderObject.isRepaintBoundary) {
      renderObject = renderObject.parent! as RenderObject;
    }
    final layer = renderObject.debugLayer! as OffsetLayer;
    paintingContextBuilder(
      layer,
      renderObject.paintBounds,
    ).paintSingleChild(renderObject);

    return layer.toImage(renderObject.paintBounds);
  }
}
