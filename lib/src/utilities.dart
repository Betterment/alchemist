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
        await startGesture(
          getCenter(
            finder.at(i),
            warnIfMissed: true,
            callee: 'pressAll',
          ),
        ),
    ];
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

/// An [AssetBundle] class used in golden testing.
///
/// This bundle is required in order to avoid issues with large assets when
/// running golden tests.
///
/// For more details, read [this Medium article](https://medium.com/@sardox/flutter-test-and-randomly-missing-assets-in-goldens-ea959cdd336a).
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
