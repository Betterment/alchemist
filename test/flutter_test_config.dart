import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:version/version.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final runningOnCi = Platform.environment.containsKey('GITHUB_ACTIONS');

  // Grab the flutter version from the current environment.
  final versionResult = await Process.run(
    'flutter',
    ['--version', '--machine'],
  );

  if (versionResult.exitCode != 0) {
    throw const ProcessException(
      'flutter',
      ['--version', '--machine'],
      'Failed to get flutter version',
    );
  }

  final versionJson = versionResult.stdout.toString().trim();
  final flutterData = json.decode(versionJson) as Map<String, dynamic>;
  final version = flutterData['flutterVersion'] as String;

  /// Returns the goldens directory for the provided flutter version.
  ///
  /// In order, this attempts to find:
  /// - A directory that matches the provided flutter version exactly.
  /// - If no exact match is found, the highest version directory that is less
  /// than or equal to the provided flutter version.
  /// - If no directories are found, an error is thrown.
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

    // If we're updating golden files, always return the associated directory.
    if (autoUpdateGoldenFiles) {
      return Directory(path.join('goldens', flutterVersion));
    }

    if (candidates.isEmpty) {
      throw ArgumentError(
        'No valid directories found in `goldens` for the current '
        'flutter version: $flutterVersion',
      );
    }

    // If we have multiple candidates, we want to find the highest version
    // directory that is less than or equal to the provided flutter version.
    return candidates.reduce((a, b) {
      final aVersion = Version.parse(path.basename(a.path));
      final bVersion = Version.parse(path.basename(b.path));
      return aVersion > bVersion ? a : b;
    });
  }

  if (!version.isValidVersion()) {
    throw FormatException(
      'Invalid flutter version provided: $version',
    );
  }

  Future<String> filePathResolver(
    String fileName,
    String environmentName,
  ) async {
    final directory = goldensDirectory(version);

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
