import 'package:alchemist/src/alchemist_file_comparator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockLocalFileComparator extends Mock implements LocalFileComparator {}

void main() {
  group('AlchemistFileComparator', () {
    test('can be constructed', () {
      expect(
        () => AlchemistFileComparator(
          basedir: Uri.parse('./'),
          tolerance: 0,
        ),
        returnsNormally,
      );
    });

    test('.fromLocalFileComparator returns correctly', () {
      final uri = Uri.parse('./');
      final style = path.Style.platform;

      final lfc = MockLocalFileComparator();
      when(() => lfc.basedir).thenReturn(uri);

      expect(
        AlchemistFileComparator.fromLocalFileComparator(
          lfc,
          tolerance: 0,
        ),
        isA<AlchemistFileComparator>()
            .having((a) => a.basedir, 'basedir', equals(same(uri)))
            .having((a) => a.tolerance, 'tolerance', equals(0))
            .having((a) => a.path.style, 'path.style', equals(same(style))),
      );
    });

    group('compare', () {
      // TODO(jeroen-meijer): Write tests.
    });

    group('update', () {
      // TODO(jeroen-meijer): Write tests.
    });

    group('getGoldenBytes', () {
      // TODO(jeroen-meijer): Write tests.
    });
  });
}
