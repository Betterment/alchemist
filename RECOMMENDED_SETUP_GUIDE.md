# Alchemist -- Recommended Setup Guide

This document outlines the recommended usage for [Alchemist](./README.md), based on how Betterment uses the tool in their internal projects.

## Platform tests vs CI tests

As explained in [the README](./README.md#about-platform-tests-vs-ci-tests), Alchemist knows two kinds of golden tests; platform tests and CI tests. Like many others in the community, we had discovered the unpleasant surprise of how individual platforms render text differently, making golden tests hard to get working consistently between environments. This was the primary reason we built Alchemist.

By having a separation between tests that are readable and tests and that allow us to make valuable assertions about layout, color and structure, we're able to reap the rewards of having both a human and a computer make sure our components stay consistent over time.

## Desired workflow

We use Alchemist to generate golden files for many of our internal projects. The workflow we use in golden testing is as follows:

- Any component that we want to test is placed in a file with the format `test/<widget_name>_golden_test.dart`.
- CI goldens are generated in `test/goldens/ci/<widget_name>.png`. These files are used in CI builds to compare the output of these tests to their golden reference files.
- Platform goldens are also generated, and are placed in `test/goldens/<platform_name>/<widget_name>.png`. These only function as a reference for developers to see how their platform renders the component, and is useful for debugging visual issues when CI golden tests fail.

Generally, CI goldens are tracked in source control to make sure CI processes have access to these files and can run the necessary tests. Platform goldens, however, are not tracked in source control, since their output is inherently unstable and partially dependent on the platform they're run on.

## Configuration

To achieve the desired workflow, we configure our tests using a `flutter_test_config.dart` file. If provided, this file will be executed prior to every test in a Dart or Flutter package. You can learn more about this file [here](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html#per-directory-hierarchy).

An average test config file for Betterment might look like this:

```dart
// flutter_test_config.dart

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:custom_styling_package/custom_styling_package.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // ignore: do_not_use_environment
  const isRunningInCi = bool.fromEnvironment('CI', defaultValue: false);

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: CustomTheme.light(),
      platformGoldensConfig: const PlatformGoldensConfig(
        enabled: !isRunningInCi,
      ),
    ),
    run: testMain,
  );
}
```

## Ignored files

To ignore any non-CI specific test files, including test failures, a `.gitignore` file in the root of our project is made with the following lines:

```
# Ignore non-CI golden files and failures
test/**/goldens/**/*.*
test/**/failures/**/*.*
!test/**/goldens/ci/*.*
```

## CI environment

Since all the necessary setup has been completed in the steps above, no changes in our CI environment are required. On every PR or push to the `main` branch, our CI process runs all tests.

```shell
flutter test # Other arguments...
```

Note that it's important **not** to pass the `--update-goldens` flag to the `test` command. This will cause all golden files to be regenerated, which means all tests will by definition always pass.
