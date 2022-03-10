import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ShadowWidget extends StatelessWidget {
  const ShadowWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.red,
            spreadRadius: 10,
            blurRadius: 10,
          )
        ],
      ),
      child: const Text('text'),
    );
  }
}

void main() {
  final ciConfigRenderShadowsEnabled =
      AlchemistConfig.current().ciGoldensConfig.copyWith(renderShadows: true);

  AlchemistConfig.runWithConfig(
    config: AlchemistConfig.current()
        .copyWith(ciGoldensConfig: ciConfigRenderShadowsEnabled),
    run: () {
      goldenTest(
        'renders shadows',
        fileName: 'shadows_smoke_test_with_shadows_config',
        widget: const ShadowWidget(),
      );
    },
  );
  goldenTest(
    'does not render shadows',
    fileName: 'shadows_smoke_test_default_ci_config',
    widget: const ShadowWidget(),
  );
}
