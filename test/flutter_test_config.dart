import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final enablePlatformTests =
      !Platform.environment.containsKey('GITHUB_ACTIONS');

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: ThemeData(
        textTheme: const TextTheme().apply(fontFamily: 'Roboto'),
      ),
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: enablePlatformTests,
      ),
    ),
    run: testMain,
  );
}
