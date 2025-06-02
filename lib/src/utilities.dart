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
      printToConsole('''
No widgets found that match finder: $finder.
No gestures will be performed.

If this is intentional, consider not calling this method
to avoid unnecessary overhead.''');
    }

    return [
      for (var i = 0; i < elementAmount; i++)
        await startGesture(
          getCenter(finder.at(i), warnIfMissed: true, callee: 'pressAll'),
        ),
    ];
  }
}

/// Extensions on [ThemeData] to help with running golden tests.
///
/// Used internally by [goldenTest].
@protected
extension GoldenTestThemeDataExtensions on ThemeData {
  /// Font family used to render blocked/obscured text.
  ///
  /// Even when replacing text with black rectangles, the same font
  /// must be used across the widget to avoid issues with different fonts
  /// having different character dimensions.
  static const obscuredTextFontFamily = 'Ahem';

  /// Strips all text packages from this theme's [ThemeData.textTheme] for use
  /// in golden tests using
  /// [GoldenTestTextStyleExtensions.stripAlchemistPackage].
  ///
  /// Only used internally and should not be used by consumers.
  @protected
  ThemeData stripTextPackages() {
    return copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.stripAlchemistPackage(),
        displayMedium: textTheme.displayMedium?.stripAlchemistPackage(),
        displaySmall: textTheme.displaySmall?.stripAlchemistPackage(),
        headlineMedium: textTheme.headlineMedium?.stripAlchemistPackage(),
        headlineSmall: textTheme.headlineSmall?.stripAlchemistPackage(),
        titleLarge: textTheme.titleLarge?.stripAlchemistPackage(),
        titleMedium: textTheme.titleMedium?.stripAlchemistPackage(),
        titleSmall: textTheme.titleSmall?.stripAlchemistPackage(),
        bodyLarge: textTheme.bodyLarge?.stripAlchemistPackage(),
        bodyMedium: textTheme.bodyMedium?.stripAlchemistPackage(),
        bodySmall: textTheme.bodySmall?.stripAlchemistPackage(),
        labelLarge: textTheme.labelLarge?.stripAlchemistPackage(),
        labelSmall: textTheme.labelSmall?.stripAlchemistPackage(),
      ),
      floatingActionButtonTheme: floatingActionButtonTheme.copyWith(
        extendedTextStyle: floatingActionButtonTheme.extendedTextStyle
            ?.stripAlchemistPackage(),
      ),
      dialogTheme: dialogTheme.copyWith(
        titleTextStyle: dialogTheme.titleTextStyle?.stripAlchemistPackage(),
        contentTextStyle: dialogTheme.contentTextStyle?.stripAlchemistPackage(),
      ),
    );
  }

  /// Replaces all fonts in the [textTheme] with an obscured font family.
  ///
  /// See [obscuredTextFontFamily] for more details.
  ///
  /// Only used internally and should not be used by consumers.
  @protected
  ThemeData applyObscuredFontFamily() {
    return copyWith(
      textTheme: textTheme.apply(fontFamily: obscuredTextFontFamily),
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
  TextStyle stripAlchemistPackage() {
    return copyWith(
      fontFamily: fontFamily?.stripFontFamilyAlchemistPackageName(),
    );
  }
}

/// Strips the package name from the given font family for use in golden tests.
extension FontFamilyStringExtensions on String {
  /// Strips the package name from this font family for use in golden tests.
  String stripFontFamilyAlchemistPackageName() {
    return replaceAll(RegExp(r'packages\/alchemist\/'), '');
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
