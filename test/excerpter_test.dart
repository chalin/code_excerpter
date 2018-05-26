import 'package:test/test.dart';
import 'package:code_excerpter/src/excerpter.dart';

/* TODO

- Multiple regions named per directive.
- Regions with plaster markers

 */

List<String> contentGeneratingNoExcerpts = [
  '',
  'abc',
  'abc\ndef\n',
  'docregion', // Without leading #
];

final emptyLines = new List.unmodifiable([]);

void main() {
  group('no excerpts:', () {
    for (final content in contentGeneratingNoExcerpts) {
      final testName = "'${content.replaceAll('\n', '\\n')}'";
      test(testName, () {
        final excerpter = new Excerpter(content);
        excerpter.weave();
        expect(excerpter.excerpts, {});
      });
    }
  });

  group('basic delimited region:', () {
    test('empty region', () {
      final excerpter = new Excerpter('#docregion\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {defaultRegionKey: []});
    });

    test('1-line region', () {
      final excerpter = new Excerpter('#docregion\nabc\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
    });
  });

  group('normalized indentation', () {
    test('default region', () {
      final excerpter = new Excerpter('''
    #docregion
      abc
    #enddocregion
    ''');
      excerpter.weave();
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
    });

    test('region a', () {
      final excerpter = new Excerpter('''
        #docregion a
          abc
        #enddocregion a
      ''');
      excerpter.weave();
      expect(excerpter.excerpts, {
        defaultRegionKey: ['          abc'],
        'a': ['abc'],
      });
    });
  });

  test('two disjoint regions', () {
    final excerpter = new Excerpter('''
      #docregion a
        abc
      #enddocregion a
      #docregion b
        def
      #enddocregion b
    ''');
    excerpter.weave();
    expect(excerpter.excerpts, {
      defaultRegionKey: ['        abc', '        def'],
      'a': ['abc'],
      'b': ['def'],
    });
  });

  test('two named regions', () {});

  group('region not closed:', () {
    ['', '\n'].forEach((eol) {
      group('empty region:', () {
        test('default region', () {
          final excerpter = new Excerpter('#docregion$eol');
          excerpter.weave();
          expect(excerpter.excerpts, {defaultRegionKey: emptyLines});
        });

        test('region a', () {
          final excerpter = new Excerpter('#docregion a$eol');
          excerpter.weave();
          expect(excerpter.excerpts,
              {defaultRegionKey: emptyLines, 'a': emptyLines});
        });
      });

      test('region a with lines but no EOL', () {
        final expectedLines = ['abc'];
        final excerpter = new Excerpter('#docregion a\nabc$eol');
        excerpter.weave();
        expect(excerpter.excerpts,
            {defaultRegionKey: expectedLines, 'a': expectedLines});
      });
    });
  });

  group('problems:', () {

  });
}
