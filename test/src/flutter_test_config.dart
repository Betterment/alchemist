import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: ThemeData(
        textTheme: const TextTheme().apply(fontFamily: 'Roboto'),
      ),
    ),
    run: testMain,
  );
}
