import 'package:alchemist/alchemist.dart';
import 'package:example/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contact List Tile Golden Tests', () {
    goldenTest(
      'renders correctly',
      fileName: 'contact_list_tile',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'enabled, one name',
            child: ContactListTile(
              onPressed: () {},
              name: 'Contact',
              email: 'contact@example.com',
            ),
          ),
          GoldenTestScenario(
            name: 'enabled, two names',
            child: ContactListTile(
              onPressed: () {},
              name: 'Contact List',
              email: 'contactlist@example.com',
            ),
          ),
          GoldenTestScenario(
            name: 'enabled, three names',
            child: ContactListTile(
              onPressed: () {},
              name: 'Contact List Tile',
              email: 'contactlisttile@example.com',
            ),
          ),
        ],
      ),
    );
  });
}
