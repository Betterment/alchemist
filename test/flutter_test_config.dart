import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:version/version.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final runningOnCi = Platform.environment.containsKey('GITHUB_ACTIONS');

  final flutterVersionVariable = Platform.environment['ALCHEMIST_FLUTTER_VERSION'];

  /// Returns the goldens directory for the provided flutter version.
  ///
  /// In order, this attempts to find:
  /// - A directory that matches the provided flutter version exactly.
  /// - If no exact match is found, the highest version directory that is less
  /// than or equal to the provided flutter version.
  /// - If no directories are found, the default `goldens` directory is used.
  ///
  /// If `autoUpdateGoldenFiles` is true (meaning we've passed
  /// --update-goldens), a directory matching the provided flutter version will
  /// be created if it does not already exist.
  ///
  /// Doing this supports running our smoke tests against specific versions of
  /// Flutter, allowing us to maintain goldens for each version when necessary.
  Directory goldensDirectory(String flutterVersion) {
    final inputVersion = Version.parse(flutterVersion);
    final subDirectories = Directory(
      path.join(
        Directory.current.path,
        'test',
        'smoke_tests',
        'goldens',
      ),
    ).listSync().whereType<Directory>().toList();

    final candidates = subDirectories.where((dir) {
      try {
        final parsedVersion = Version.parse(path.basename(dir.path));
        return parsedVersion <= inputVersion;
      } on FormatException {
        return false;
      }
    });

    if (candidates.isEmpty) {
      if (autoUpdateGoldenFiles) {
        return Directory(path.join('goldens', flutterVersion));
      }
      return Directory('goldens');
    }

    // If we have multiple candidates, we want to find the highest version
    // directory that is less than or equal to the provided flutter version.
    return candidates.reduce((a, b) {
      final aVersion = Version.parse(path.basename(a.path));
      final bVersion = Version.parse(path.basename(b.path));
      return aVersion > bVersion ? a : b;
    });
  }

  if (flutterVersionVariable != null && !flutterVersionVariable.isValidVersion()) {
    throw FormatException(
      'Invalid flutter version provided: $flutterVersionVariable',
    );
  }

  Future<String> filePathResolver(
    String fileName,
    String environmentName,
  ) async {
    final defaultFilePath = path.join(
      'goldens',
      environmentName.toLowerCase(),
      '$fileName.png',
    );

    if (flutterVersionVariable == null) {
      return defaultFilePath;
    }

    // Check all subdirectories of `goldens` for a directory we can use for
    // the provided flutter version, falling back on `defaultFilePath` if none
    // exist.
    final directory = goldensDirectory(flutterVersionVariable);
    return path.join(
      directory.path,
      environmentName.toLowerCase(),
      '$fileName.png',
    );
  }

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: ThemeData(
        useMaterial3: false,
        textTheme: const TextTheme().apply(fontFamily: 'Roboto'),
      ),
      ciGoldensConfig: AlchemistConfig.current()
          .ciGoldensConfig //
          .copyWith(
            filePathResolver: filePathResolver,
            enabled: runningOnCi,
          ),
      platformGoldensConfig: AlchemistConfig.current()
          .platformGoldensConfig //
          .copyWith(
            filePathResolver: filePathResolver,
            enabled: !runningOnCi,
          ),
    ),
    run: testMain,
  );
}

extension on String {
  bool isValidVersion() {
    try {
      Version.parse(this);
      return true;
    } on FormatException {
      return false;
    }
  }
}
