# Alchemist Example

## Recommended Setup Guide

For a more detailed explanation on how Betterment uses Alchemist, read the included [Recommended Setup Guide][setup-guide].

## Full Example Project

A full project containing an application containing exemplary widgets and golden tests is included in the [example][example_dir] folder.

## Basic usage

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
            child: const ListTile(
              title: Text('ListTile.title'),
            ),
          ),
          GoldenTestScenario(
            name: 'with title and subtitle',
            child: const ListTile(
              title: Text('ListTile.title'),
              subtitle: Text('ListTile.subtitle'),
            ),
          ),
          GoldenTestScenario(
            name: 'with trailing icon',
            child: const ListTile(
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

## gitignore

We recommend adding the following lines to your project's `.gitignore` file to prevent platform-specific artifacts from being included in your git repository.

```gitignore
# Ignore platform-specific goldens
**/goldens/macos
**/goldens/linux
**/goldens/windows
```

[setup-guide]: https://github.com/Betterment/alchemist/blob/main/RECOMMENDED_SETUP_GUIDE.md
[example_dir]: https://github.com/Betterment/alchemist/tree/main/example
