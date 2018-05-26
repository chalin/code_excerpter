import 'package:code_excerpter/src/excerpter.dart';
import 'package:code_excerpter/src/util/logging.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/* TODO:
- Multiple regions named per directive.
- Regions with plaster markers
 */

// Mock URI used for all content origins.
final uri = 'foo';

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
        final excerpter = new Excerpter(uri, content);
        excerpter.weave();
        expect(excerpter.excerpts, {});
      });
    }
  });

  group('basic delimited default region:', () {
    test('empty region', () {
      final excerpter = new Excerpter(uri, '#docregion\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {defaultRegionKey: []});
    });

    test('1-line region', () {
      final excerpter = new Excerpter(uri, '#docregion\nabc\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
    });
  });

  group('normalized indentation', () {
    test('default region', () {
      final excerpter = new Excerpter(uri, '''
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
      final excerpter = new Excerpter(uri, '''
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
    final excerpter = new Excerpter(uri, '''
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
          final excerpter = new Excerpter(uri, '#docregion$eol');
          excerpter.weave();
          expect(excerpter.excerpts, {defaultRegionKey: emptyLines});
        });

        test('region a', () {
          final excerpter = new Excerpter(uri, '#docregion a$eol');
          excerpter.weave();
          expect(excerpter.excerpts,
              {defaultRegionKey: emptyLines, 'a': emptyLines});
        });
      });

      test('region a with lines but no EOL', () {
        final expectedLines = ['abc'];
        final excerpter = new Excerpter(uri, '#docregion a\nabc$eol');
        excerpter.weave();
        expect(excerpter.excerpts,
            {defaultRegionKey: expectedLines, 'a': expectedLines});
      });
    });
  });

  group('problems:', problemCases);
}

void problemCases() {
  final List<LogRecord> logs = [];

  setUpAll(() {
    logListeners.clear(); // Don't print during tests
    logListeners.add((r) => logs.add(r));
  });

  setUp(() => logs.clear());

  group('end before start', () {

    test('default region', () {
      final excerpter = new Excerpter(uri, '#enddocregion');
      excerpter.weave();
      expect(logs[0].message,
          contains('region "" end without a prior region start at $uri:1'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {defaultRegionKey: emptyLines});
    });

    test('region a', () {
      final excerpter = new Excerpter(uri, 'abc\n#enddocregion a');
      excerpter.weave();
      expect(logs[0].message,
          contains('region "a" end without a prior region start at $uri:2'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {defaultRegionKey: ['abc']});
    });
  });
}
