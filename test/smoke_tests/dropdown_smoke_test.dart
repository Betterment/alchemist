import 'package:alchemist/src/golden_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestDropdownButton extends StatelessWidget {
  const TestDropdownButton({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: DropdownButton<String>(
      value: '0',
      items: const [
        DropdownMenuItem<String>(value: '0', child: Text('0')),
        DropdownMenuItem<String>(value: '1', child: Text('1')),
        DropdownMenuItem<String>(value: '2', child: Text('2')),
      ],
      onChanged: (_) {},
    ),
  );
}

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds after tapping dropdown',
      fileName: 'dropdown_smoke_test',
      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 250),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
      },
      builder: () {
        return const TestDropdownButton();
      },
    );
  });
}
