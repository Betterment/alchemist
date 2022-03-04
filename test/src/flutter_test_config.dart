import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final enablePlatformTests =
      !Platform.environment.containsKey('GITHUB_ACTIONS');
  // ignore: avoid_print
  print('Enable platform tests: $enablePlatformTests');

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: ThemeData(
        textTheme: const TextTheme().apply(fontFamily: 'Roboto'),
      ),
      platformGoldensConfig:
          AlchemistConfig.current().platformGoldensConfig.copyWith(
                enabled: enablePlatformTests,
              ),
    ),
    run: testMain,
  );
}
