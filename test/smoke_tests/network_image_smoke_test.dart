import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds with a network image',
      fileName: 'network_image_smoke_test',
      pumpWidget: (tester, widget) async {
        await mockNetworkImages(() => tester.pumpWidget(widget));
      },
      builder: () => Padding(
        padding: const EdgeInsets.all(8),
        child: Image.network('https://fakeurl.com/image.png'),
      ),
    );
  });
}
