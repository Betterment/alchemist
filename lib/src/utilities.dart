import 'dart:convert';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extensions on an [Iterable] of [TestGesture] for convenience.
///
/// Used internally by [goldenTest].
@protected
extension GoldenTestGestureIterableExtensions on Iterable<TestGesture> {
  /// Releases all gestures in this list by calling [TestGesture.up] one by one
  /// in order.
  Future<void> releaseAll() async {
    for (final gesture in this) {
      await gesture.up();
    }
  }
}

/// Extensions on [WidgetTester] to help with running golden tests.
///
/// Used internally by [goldenTest].
@protected
extension GoldenTestWidgetTesterExtensions on WidgetTester {
  /// Starts a pressing gesture on all widgets that match the given [finder] and
  /// returns the resulting gesture objects.
  ///
  /// Consider releasing all gestures when done with testing by calling
  /// `await allGestures.releaseAll()`, courtesy of
  /// [GoldenTestGestureIterableExtensions].
  ///
  /// **Note:** if more than one widget needs to be pressed at the same time,
  /// the given finder may match multiple widgets. However, if any matched
  /// widget does not respond to the press, all other gestures will fail,
  /// rendering the use of this method useless.
  ///
  /// If no widgets match the [finder], a warning will be given. In this case,
  /// consider removing this method call from your test.
  ///
  /// Only used internally and should not be used by consumers.
  Future<List<TestGesture>> pressAll(Finder finder) async {
    final elementAmount = finder.evaluate().length;

    if (elementAmount == 0) {
      printToConsole(
        '''
No widgets found that match finder: $finder.
No gestures will be performed.

If this is intentional, consider not calling this method
to avoid unnecessary overhead.''',
      );
    }

    return [
      for (var i = 0; i < elementAmount; i++)
        await startGesture(getCenter(finder.at(i)))
    ];
  }

  /// Pumps an empty widget to the screen and waits for the next frame.
  ///
  /// This can be used to completely reset the state of the widget tree when a
  /// new widget needs to be pumped after a test.
  Future<void> cleanPump() async {
    await pumpWidget(Container(key: UniqueKey()));
    await pump();
  }

  /// Pumps the given [widget] to this [WidgetTester] for use in golden tests.
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
  ///
  /// Only used internally and should not be used by consumers.
  @protected
  Future<void> pumpGoldenTest({
    Key? rootKey,
    required double textScaleFactor,
    required BoxConstraints constraints,
    required ThemeData theme,
    required Widget widget,
  }) async {
    final initialSize = Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : 2000,
      constraints.hasBoundedHeight ? constraints.maxHeight : 2000,
    );
    await binding.setSurfaceSize(initialSize);
    binding.window.physicalSizeTestValue = initialSize;

    binding.window.devicePixelRatioTestValue = 1.0;
    binding.window.textScaleFactorTestValue = textScaleFactor;

    await pumpWidget(
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
                    key: const Key('golden-test-child-parent'),
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
      final childSize =
          getSize(find.byKey(const Key('golden-test-child-parent')));
      final newSize = Size(
        childSize.width.clamp(constraints.minWidth, constraints.maxWidth),
        childSize.height.clamp(constraints.minHeight, constraints.maxHeight),
      );
      if (newSize != initialSize) {
        await binding.setSurfaceSize(newSize);
        binding.window.physicalSizeTestValue = newSize;
      }
    }

    await pump();
  }
}

/// Extensions on [ThemeData] to help with running golden tests.
///
/// Used internally by [goldenTest].
@protected
extension GoldenTestThemeDataExtensions on ThemeData {
  /// Strips all text packages from this theme's [ThemeData.textTheme] for use
  /// in golden tests using [GoldenTestTextStyleExtensions.stripPackage].
  ///
  /// Only used internally and should not be used by consumers.
  @protected
  ThemeData stripTextPackages() {
    return copyWith(
      textTheme: textTheme.copyWith(
        headline1: textTheme.headline1?.stripPackage(),
        headline2: textTheme.headline2?.stripPackage(),
        headline3: textTheme.headline3?.stripPackage(),
        headline4: textTheme.headline4?.stripPackage(),
        headline5: textTheme.headline5?.stripPackage(),
        headline6: textTheme.headline6?.stripPackage(),
        subtitle1: textTheme.subtitle1?.stripPackage(),
        subtitle2: textTheme.subtitle2?.stripPackage(),
        bodyText1: textTheme.bodyText1?.stripPackage(),
        bodyText2: textTheme.bodyText2?.stripPackage(),
        caption: textTheme.caption?.stripPackage(),
        button: textTheme.button?.stripPackage(),
        overline: textTheme.overline?.stripPackage(),
      ),
      floatingActionButtonTheme: floatingActionButtonTheme.copyWith(
        extendedTextStyle:
            floatingActionButtonTheme.extendedTextStyle?.stripPackage(),
      ),
    );
  }
}

/// Extensions on [TextStyle] to help with running golden tests.
///
/// Used internally by [GoldenTestThemeDataExtensions.stripTextPackages].
@protected
extension GoldenTestTextStyleExtensions on TextStyle {
  /// Strips the package name from this text style's [TextStyle.fontFamily] for
  /// use in golden tests.
  @protected
  TextStyle stripPackage() {
    return TextStyle(
      inherit: inherit,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily?.replaceAll(RegExp(r'packages\/[^\/]*\/'), ''),
      fontFamilyFallback: fontFamilyFallback,
      overflow: overflow,
    );
  }
}

/// An asset bundle class used in golden testing.
///
/// This bundle is required in order to avoid issues with large assets when
/// running golden tests. For more details, read [this Medium article](https://medium.com/@sardox/flutter-test-and-randomly-missing-assets-in-goldens-ea959cdd336a).
@protected
class TestAssetBundle extends CachingAssetBundle {
  // This method is overridden to avoid the inherent limit of 50KB per asset.
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(data.buffer.asUint8List());
  }

  @override
  Future<ByteData> load(String key) async => rootBundle.load(key);
}
