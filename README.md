<h1>🧙🏼 Alchemist</h1>

<a href="https://verygood.ventures" ><img alt="Very Good Ventures" src="https://raw.githubusercontent.com/VGVentures/very_good_brand/main/logos/lockups/lockup.svg" width="400"></a>

<a href="https://betterment.com/" ><img alt="Betterment" src="https://resources.betterment.com/hubfs/Graphics/shared-assets/betterment-wordmark-logo.svg" width="400"></a>

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄 and [Betterment][betterment_link] ☀️.

[![ci][ci_badge]][ci_link]
[![codecov][coverage_badge]][coverage_link]
[![pub package][pub_badge]][pub_link]
[![License: MIT][license_badge]][license_link]

---

<h3>A Flutter tool that makes golden testing easy.</h3>

Alchemist is a Flutter package that provides functions, extensions and documentation to support golden tests.

Heavily inspired by [Ebay Motor's `golden_toolkit` package][golden_toolkit_pub], Alchemist attempts to make writing and running golden tests in Flutter easier.

> A short guide can be found in [example.md][example_markdown] file (or the [example tab on pub.dev][example_pub]). A full example project is available in the [example][example_dir] directory.

### Feature Overview

- 🤖 [Separate local & CI tests](#about-platform-tests-vs-ci-tests)
- 📝 [Declarative & terse testing API](#writing-the-test)
- 📐 [Automatic file sizing](#automaticcustom-image-sizing)
- 🔧 [Advanced configuration](#advanced-usage)
- 🌈 [Easy theme customization](#about-alchemistconfig)
- 🔤 [Custom text scaling](#custom-text-scale-factor)
- 🧪 100% test coverage
- 📖 Extensive documentation

### Table of Contents

- [Feature Overview](#feature-overview)
- [Table of Contents](#table-of-contents)
- [About platform tests vs. CI tests](#about-platform-tests-vs-ci-tests)
- [Basic usage](#basic-usage)
  - [Writing the test](#writing-the-test)
  - [Recommended Setup Guide](#recommended-setup-guide)
  - [Test groups](#test-groups)
  - [Test scenarios](#test-scenarios)
  - [Generating the golden file](#generating-the-golden-file)
  - [Testing and comparing](#testing-and-comparing)
- [Advanced usage](#advanced-usage)
  - [About `AlchemistConfig`](#about-alchemistconfig)
    - [Advanced theming](#advanced-theming)
  - [Using a custom config](#using-a-custom-config)
    - [For all tests](#for-all-tests)
    - [For single tests or groups](#for-single-tests-or-groups)
    - [Merging and copying configs](#merging-and-copying-configs)
  - [Simulating gestures](#simulating-gestures)
  - [Automatic/custom image sizing](#automaticcustom-image-sizing)
  - [Custom pumping behavior](#custom-pumping-behavior)
    - [Before tests](#before-tests)
    - [Pumping widgets](#pumping-widgets)
  - [Custom text scale factor](#custom-text-scale-factor)
- [Resources](#resources)

### About platform tests vs. CI tests

Alchemist can perform two kinds of golden tests.

One is **platform tests**, which generate golden files with human readable text. These can be considered regular golden tests and are usually only run on a local machine.

![Example platform golden test][platform_test_image]

The other is **CI tests**, which look and function the same as platform tests, except that the text blocks are replaced with colored squares.

![Example CI golden test][ci_test_image]

The reason for this distinction is that the output of platform tests is dependent on the platform the test is running on. In particular, individual platforms are known to render text differently than others. This causes readable golden files generated on macOS, for example, to be ever so slightly off from the golden files generated on other platforms, such as Windows or Linux, causing CI systems to fail the test. CI tests, on the other hand, were made to circumvent this, and will always have the same output regardless of the platform.

Additionally, CI tests are always run using the Ahem font family, which is a font that solely renders square characters. This is done to ensure that CI tests are platform agnostic -- their output is always consistent regardless of the host platform.

### Basic usage

#### Writing the test

In your project's `test/` directory, add a file for your widget's tests. Then, write and run golden tests by using the `goldenTest` function.

We recommend putting all golden tests related to the same component into a test `group`.

Every `goldenTest` commonly contains a group of scenarios related to each other (for example, all scenarios that test the same constructor or widget in a particular context).

This example shows a basic golden test for `ListTile`s that makes use of some of the more advanced features of the `goldenTest` API to control the output of the test.

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListTile Golden Tests', () {
    goldenTest(
      'renders correctly',
      fileName: 'list_tile',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 600),
        children: [
          GoldenTestScenario(
            name: 'with title',
            child: ListTile(
              title: Text('ListTile.title'),
            ),
          ),
          GoldenTestScenario(
            name: 'with title and subtitle',
            child: ListTile(
              title: Text('ListTile.title'),
              subtitle: Text('ListTile.subtitle'),
            ),
          ),
          GoldenTestScenario(
            name: 'with trailing icon',
            child: ListTile(
              title: Text('ListTile.title'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  });
}
```

Then, simply run Flutter test and pass the `--update-goldens` flag to generate the golden files.

```shell
flutter test --update-goldens
```

#### Recommended Setup Guide

For a more detailed explanation on how Betterment uses Alchemist, read the included [Recommended Setup Guide][setup_guide].

#### Test groups

While the `goldenTest` function can take in and performs tests on any arbitrary widget, it is most commonly given a `GoldenTestGroup`. This is a widget used for organizing a set of widgets that groups multiple testing scenarios together and arranges them in a table format.

Alongside the `children` parameter, `GoldenTestGroup` contains two additional properties that can be used to customize the resulting table view:

| Field                                    | Default | Description                                                                                                                                                |
| ---------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `int? columns`                           | `null`  | The amount of columns in the grid. If left unset, this will be determined based on the amount of children.                                                 |
| `ColumnWidthBuilder? columnWidthBuilder` | `null`  | A function that returns the width for each column. If left unset, the width of each column is determined by the width of the widest widget in that column. |

#### Test scenarios

Golden test scenarios are typically encapsulated in a `GoldenTestScenario` widget. This widget contains a `name` property that is used to identify the scenario, along with the widget it should display. The regular constructor allows a `name` and `child` to be passed in, but the `.builder` and `.withTextScaleFactor` constructors allow the use of a widget builder and text scale factor to be passed in respectively.

#### Generating the golden file

To run the test and generate the golden file, run `flutter test` with the `--update-goldens` flag.

```shell
# Should always succeed
flutter test --update-goldens
```

After all golden tests have run, the generated golden files will be in the `goldens/ci/` directory relative to the test file. Depending on the platform the test was run on (and the current [`AlchemistConfig`](#configuring-tests)), platform goldens will be in the `goldens/<platform_name>` directory.

```
lib/
test/
├─ goldens/
│  ├─ ci/
│  │  ├─ my_widget.png
│  ├─ macos/
│  │  ├─ my_widget.png
│  ├─ linux/
│  │  ├─ my_widget.png
│  ├─ windows/
│  │  ├─ my_widget.png
├─ my_widget_golden_test.dart
pubspec.yaml
```

#### Testing and comparing

When you want to run golden tests regularly and compare them to the generated golden files (in a CI process for example), simply run `flutter test`.

By default, all golden tests will have a `"golden"` tag, meaning you can select when to run golden tests.

```shell
# Run all tests.
flutter test

# Only run golden tests.
flutter test --tags golden

# Run all tests except golden tests.
flutter test --exclude-tags golden
```

### Advanced usage

Alchemist has several extensions and mechanics to accommodate for more advanced golden testing scenarios.

#### About `AlchemistConfig`

All tests make use of the `AlchemistConfig` class. This configuration object contains various settings that can be used to customize the behavior of the tests.

A default `AlchemistConfig` is provided for you, and contains the following settings:

| Field                                         | Default                         | Description                                                                                        |
| --------------------------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------- |
| `bool forceUpdateGoldenFiles`                 | `false`                         | If `true`, the golden files will always be regenerated, regardless of the `--update-goldens` flag. |
| `ThemeData? theme`                            | `null`                          | The theme to use for all tests. If `null`, the default `ThemeData.light()` will be used.           |
| `PlatformGoldensConfig platformGoldensConfig` | `const PlatformGoldensConfig()` | The configuration to use when running readable golden tests on a non-CI host.                      |
| `CiGoldensConfig ciGoldensConfig`             | `const CiGoldensConfig()`       | The configuration to use when running obscured golden tests in a CI environment.                   |

Both the `PlatformGoldensConfig` and `CiGoldensConfig` classes contain a number of settings that can be used to customize the behavior of the tests. These are the settings both of these objects allow you to customize:

| Field                               | Default                             | Description                                                                                                                                                                                                                                                                                                                                                   |
| ----------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bool enabled`                      | `true`                              | Indicates if this type of test should run. If set to `false`, this type of test is never allowed to run. Defaults to `true`.                                                                                                                                                                                                                                  |
| `bool obscureText`                  | `true` for CI, `false` for platform | Indicates if the text in the rendered widget should be obscured by colored rectangles. This is useful for circumventing issues with Flutter's font rendering between host platforms.                                                                                                                                                                          |
| `bool renderShadows`                | `false` for CI, `true` for platform | Indicates if shadows should actually be rendered, or if they should be replaced by opaque colors. This is useful because shadow rendering can be inconsistent between test runs.                                                                                                                                                                              |
| `FilePathResolver filePathResolver` | `<_defaultFilePathResolver>`        | A function that resolves the path to the golden file, relative to the test that generates it. By default, CI golden test files are placed in `goldens/ci/`, and readable golden test files are placed in `goldens/`.                                                                                                                                          |
| `ThemeData? theme`                  | `null`                              | The theme to use for this type of test. If `null`, the enclosing `AlchemistConfig`'s `theme` will be used, or `ThemeData.light()` if that is also `null`. _Note that CI tests are always run using the Ahem font family, which is a font that solely renders square characters. This is done to ensure that CI tests are always consistent across platforms._ |

Alongside these arguments, the `PlatformGoldensConfig` contains an additional setting:

| Field                         | Default       | Description                                                                                                                                                                                                       |
| ----------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Set<HostPlatform> platforms` | All platforms | The platforms that platform golden tests should run on. By default, this is set to all platforms, meaning that a golden file will be generated if the current platform matches any platforms in the provided set. |

##### Advanced theming

In addition to the `theme` property on the `AlchemistConfig`, `CiGoldensConfig` and `PlatformGoldensConfig` classes, Alchemist also supports inherited theming. This means that any theme provided through a custom `pumpWidget` callback given to `goldenTest` will be used instead of the `theme` property on the `AlchemistConfig`.

The theme resolver works as follows:

1. If a theme is given to the platform-specific test (using `CiGoldensConfig` or `PlatformGoldensConfig`), it is used.
2. Otherwise, if an inherited theme is provided by the `pumpWidget` callback (for example, through a `MaterialApp`), it is used.
3. Otherwise, if a theme is provided in the `AlchemistConfig`, it is used.
4. Otherwise, a default `ThemeData.fallback()` is used.

#### Using a custom config

The current `AlchemistConfig` can be retrieved at any time using `AlchemistConfig.current()`.

A custom can be set by using `AlchemistConfig.runWithConfig`. Any code executed within this function will cause `AlchemistConfig.current()` to return the provided config. This is achieved using Dart's zoning system.

```dart
void main() {
  print(AlchemistConfig.current().forceUpdateGoldenFiles);
  // > false

  AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      forceUpdateGoldenFiles: true,
    ),
    run: () {
      print(AlchemistConfig.current().forceUpdateGoldenFiles);
      // > true
    },
  );
}
```

##### For all tests

A common way to use this mechanic to configure tests for all your tests in a particular package is by using a `flutter_test_config.dart` file.

Create a `flutter_test_config.dart` file in the root of your project's `test/` directory. This file should have the following contents by default:

```dart
import 'dart:async';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
```

This file is executed every time a test file is about to be run. To set a global config, simply wrap the `testMain` function in a `AlchemistConfig.runWithConfig` call, like so:

```dart
import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      // Configure the config here.
    ),
    run: testMain,
  );
}
```

Any test executed in the package will now use the provided config.

##### For single tests or groups

A config can also be set for a single test or test group, which will override the default for those tests. This can be achieved by wrapping that group or test in a `AlchemistConfig.runWithConfig` call, like so:

```dart
void main() {
  group('with default config', () {
    test('test', () {
      expect(
        AlchemistConfig.current().forceUpdateGoldenFiles,
        isFalse,
      );
    });
  });

  AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      forceUpdateGoldenFiles: true,
    ),
    run: () {
      group('with overridden config', () {
        test('test', () {
          expect(
            AlchemistConfig.current().forceUpdateGoldenFiles,
            isTrue,
          );
        });
      });
    },
  );
}
```

##### Merging and copying configs

Additionally, settings for a given code block can be partially overridden by using `AlchemistConfig.copyWith` or, more commonly, `AlchemistConfig.merge`. The `copyWith` method will create a copy of the config it is called on, and then override the settings passed in. The `merge` is slightly more flexible, allowing a second `AlchemistConfig` (or `null`) to be passed in, after which a copy will be created of the instance, and all settings defined on the provided config will replace ones on the instance.

Fortunately, the replacement mechanic of `merge` makes it possible to replace deep/nested values easily, like this:

<details><summary>Click to open <code>AlchemistConfig.merge</code> example</summary>

```dart
void main() {
  // The top level config is defined here.
  AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      forceUpdateGoldenFiles: true,
      platformGoldensConfig: PlatformGoldensConfig(
        renderShadows: false,
        fileNameResolver: (String name) => 'top_level_config/goldens/$name.png',
      ),
    ),
    run: () {
      final currentConfig = AlchemistConfig.current();

      print(currentConfig.forceUpdateGoldenFiles);
      // > true
      print(currentConfig.platformGoldensConfig.renderShadows);
      // > false
      print(currentConfig.platformGoldensConfig.fileNameResolver('my_widget'));
      // > top_level_config/goldens/my_widget.png

      AlchemistConfig.runWithConfig(
        // Here, the current config (defined above) is merged
        // with a new config, where only the defined options are
        // replaced, preserving the rest.
        config: AlchemistConfig.current().merge(
            AlchemistConfig(
              platformGoldensConfig: PlatformGoldensConfig(
                renderShadows: true,
              ),
            ),
          ),
        ),
        run: () {
          // AlchemistConfig.current() will now return the merged config.
          final currentConfig = AlchemistConfig.current();

          print(currentConfig.forceUpdateGoldenFiles);
          // > true (preserved from the top level config)
          print(currentConfig.platformGoldensConfig.renderShadows);
          // > true (changed by the newly merged config)
          print(currentConfig.platformGoldensConfig.fileNameResolver('my_widget'));
          // > top_level_config/goldens/my_widget.png (preserved from the top level config)
        },
      );
    },
  );
}
```

</details>

#### Simulating gestures

Some golden tests may require some form of user input to be performed. For example, to make sure a button shows the right color when being pressed, a test may require a tap gesture to be performed while the golden test image is being generated.

These kinds of gestures can be performed by providing the `goldenTest` function with a `whilePerforming` argument. This parameter takes a function that will be used to find the widget that should be pressed. There are some default interactions already provided, such as `press` and `longPress`.

```dart
void main() {
  goldenTest(
    'ElevatedButton renders tap indicator when pressed',
    fileName: 'elevated_button_pressed',
    whilePerforming: press(find.byType(ElevatedButton)),
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'pressed',
          child: ElevatedButton(
            onPressed: () {},
            child: Text('Pressed'),
          ),
        ),
      ],
    ),
  );
}
```

#### Automatic/custom image sizing

By default, Alchemist will automatically find the smallest possible size for the generated golden image and the widgets it contains, and will resize the image accordingly.

The default size and this scaling behavior are configurable, and fully encapsulated in the `constraints` argument to the `goldenTest` function.

The constraints are set to `const BoxConstraints()` by default, meaning no minimum or maximum size will be enforced.

If a minimum width or height is set, the image will be resized to that size as long as it would not clip the widgets it contains. The same is true for a maximum width or height.

If the passed in constraints are tight, meaning the minimum width and height are equal to the maximum width and height, no resizing will be performed and the image will be generated at the exact size specified.

#### Custom pumping behavior

##### Before tests

Before running every golden test, the `goldenTest` function will call its `pumpBeforeTest` function. This function is used to prime the widget tree prior to generating the golden test image. By default, the tree is pumped and settled (using `tester.pumpAndSettle()`), but in some scenarios, custom pumping behavior may be required.

In these cases, a different `pumpBeforeTest` function can be provided to the `goldenTest` function. A set of predefined functions are included in this package, including `pumpOnce`, `pumpNTimes(n)`, and `onlyPumpAndSettle`, but custom functions can be created as well.

Additionally, there is a `precacheImages` function, which can be passed to `pumpBeforeTest` in order to preload all images in the tree, so that they will appear in the generated golden files.

##### Pumping widgets

If desired, a custom `pumpWidget` function can be provided to any `goldenTest` call. This will override the default behavior and allow the widget being tested to be wrapped in any number of widgets, and then pumped.

By default, Alchemist will simply pump the widget being tested using `tester.pumpWidget`. Note that the widget under test will always be wrapped in a set of bootstrapping widgets, regardless of the `pumpWidget` callback provided.

#### Custom text scale factor

The `GoldenTestScenario.withTextScaleFactor` constructor allows a custom text scale factor value to be provided for a single scenario. This can be used to test text rendering at different sizes.

To set a default scale factor for all scenarios within a test, the `goldenTest` function allows a default `textScaler` to be provided, which defaults to `TextScaler.linear(1.0)`.

### Resources

- Visit the [GitHub repository][alchemist_repo] to view the source code.
- For bug reports and feature requests, visit the [GitHub issues][alchemist_issues].
- Feel free to submit a pull request! If you're a developer, you can fork the repository and [submit your pull request][alchemist_pull_request].

[very_good_ventures_link]: https://verygood.ventures
[betterment_link]: https://betterment.com/
[ci_badge]: https://github.com/Betterment/alchemist/workflows/alchemist/badge.svg
[ci_link]: https://github.com/Betterment/alchemist/actions
[coverage_badge]: https://codecov.io/gh/Betterment/alchemist/branch/main/graph/badge.svg?token=M04EG8H8V9
[coverage_link]: https://codecov.io/gh/Betterment/alchemist
[pub_badge]: https://img.shields.io/pub/v/alchemist.svg
[pub_link]: https://pub.dev/packages/alchemist
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[golden_toolkit_pub]: https://pub.dev/packages/golden_toolkit
[alchemist_repo]: https://github.com/Betterment/alchemist
[alchemist_issues]: https://github.com/Betterment/alchemist/issues
[alchemist_pull_request]: https://github.com/Betterment/alchemist/compare
[platform_test_image]: https://raw.githubusercontent.com/Betterment/alchemist/main/assets/readme/macos_list_tile_golden_file.png
[ci_test_image]: https://raw.githubusercontent.com/Betterment/alchemist/main/assets/readme/ci_list_tile_golden_file.png
[example_markdown]: ./example/example.md
[example_pub]: https://pub.dev/packages/alchemist/example
[example_dir]: ./example/
[setup_guide]: ./RECOMMENDED_SETUP_GUIDE.md
