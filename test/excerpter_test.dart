import 'package:test/test.dart';
import 'package:code_excerpter/src/excerpter.dart';

List<String> contentGeneratingNoExcerpts = [
  '',
  'abc',
  'abc\ndef\n',
  'docregion', // Without leading #
];

void main() {
  group('no excerpts:', () {
    for (final content in contentGeneratingNoExcerpts) {
      final testName = "'${content.replaceAll('\n', '\\n')}'";
      test(testName, () {
        Excerpter excerpter = new Excerpter(content);
        excerpter.weave();
        expect(excerpter.excerpts, {});
      });
    }
  });

  group('basic delimited region:', () {
    test('empty region', () {
      Excerpter excerpter = new Excerpter('#docregion\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {defaultRegionKey: []});
    });

    test('1-line region', () {
      Excerpter excerpter = new Excerpter('#docregion\nabc\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
    });
  });

  group('region not closed:', () {
    group('empty file:', () {
      final expectedLines = [];

      test('default region', () {
        Excerpter excerpter = new Excerpter('#docregion');
        excerpter.weave();
        expect(excerpter.excerpts, {defaultRegionKey: expectedLines});
      });

      test('region a', () {
        Excerpter excerpter = new Excerpter('#docregion a');
        excerpter.weave();
        expect(excerpter.excerpts,
            {defaultRegionKey: expectedLines, 'a': expectedLines});
      });
    });

    group('1-line file:', () {
      final expectedLines = [''];

      test('default region', () {
        Excerpter excerpter = new Excerpter('#docregion\n');
        excerpter.weave();
        expect(excerpter.excerpts, {defaultRegionKey: expectedLines});
      });

      test('region a', () {
        Excerpter excerpter = new Excerpter('#docregion a\n');
        excerpter.weave();
        expect(excerpter.excerpts,
            {defaultRegionKey: expectedLines, 'a': expectedLines});
      });
    });
  });
}
