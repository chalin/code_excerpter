import 'package:code_excerpter/src/excerpter.dart';
import 'package:code_excerpter/src/util/logging.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/* TODO:
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

final List<LogRecord> logs = [];

void _expectNoLogs() => expect(logs, []);

void main() {
  setUpAll(() {
    logListeners.clear(); // Don't print during tests
    logListeners.add((r) => logs.add(r));
  });

  setUp(() => logs.clear());

  // Each individual test must check [logs], and then clear them.
  // This will catch situations where this is not done.
  tearDown(_expectNoLogs);

  test('helper sanity:', () {
    var content = '''
      #docregion a
        abc
      #enddocregion a
      #docregion b
        def
      #enddocregion b
    ''';
    expect(stripDirectives(content), [
      '        abc',
      '        def',
    ]);
  });

  group('no excerpts:', () {
    for (final content in contentGeneratingNoExcerpts) {
      final testName = "'${content.replaceAll('\n', '\\n')}'";
      test(testName, () {
        final excerpter = new Excerpter(uri, content);
        excerpter.weave();
        expect(excerpter.excerpts, {});
        _expectNoLogs();
      });
    }
  });

  // Independent of indentation
  group('basic delimited default region:', () {
    test('1-line region', () {
      final excerpter = new Excerpter(uri, '#docregion\nabc\n#enddocregion');
      excerpter.weave();
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
      _expectNoLogs();
    });
  });

  group('normalized indentation:', () {
    test('default region', () {
      final excerpter = new Excerpter(uri, '''
        #docregion
          abc
        #enddocregion
      ''');
      expect(excerpter.weave().excerpts, {
        defaultRegionKey: ['abc']
      });
      _expectNoLogs();
    });

    test('region a', () {
      var content = '''
        #docregion a
          abc
        #enddocregion a
      ''';
      final excerpter = new Excerpter(uri, content);
      expect(excerpter.weave().excerpts, {
        defaultRegionKey: ['          abc'],
        'a': ['abc'],
      });
      _expectNoLogs();
    });
  });

  test('two disjoint regions', () {
    var content = '''
      #docregion a
        abc
      #enddocregion a
      #docregion b
        def
      #enddocregion b
    ''';
    final excerpter = new Excerpter(uri, content);
    expect(excerpter.weave().excerpts, {
      defaultRegionKey: stripDirectives(content),
      'a': ['abc'],
      'b': ['def'],
    });
    _expectNoLogs();
  });

  group('region not closed:', () {
    ['', '\n'].forEach((eol) {
      group('empty region:', () {
        test('default region', () {
          final excerpter = new Excerpter(uri, '#docregion$eol');
          expect(excerpter.weave().excerpts, {defaultRegionKey: emptyLines});
          _expectNoLogs();
        });

        test('region a', () {
          final excerpter = new Excerpter(uri, '#docregion a$eol');
          expect(excerpter.weave().excerpts,
              {defaultRegionKey: emptyLines, 'a': emptyLines});
          _expectNoLogs();
        });
      });

      test('region with a line', () {
        final expectedLines = ['abc'];
        final excerpter = new Excerpter(uri, '#docregion b\nabc$eol');
        expect(excerpter.weave().excerpts,
            {defaultRegionKey: expectedLines, 'b': expectedLines});
        _expectNoLogs();
      });
    });
  });

  group('problems:', problemCases);
  group('plaster:', plasterCases);
}

void problemCases() {
  test('empty region', () {
    final excerpter = new Excerpter(uri, '#docregion\n#enddocregion');
    excerpter.weave();
    expect(logs[0].message, contains('empty region at $uri:2'));
    expect(logs.length, 1);
    expect(excerpter.excerpts, {defaultRegionKey: []});
    logs.clear();
  });

  group('end before start', () {
    test('default region', () {
      final excerpter = new Excerpter(uri, '#enddocregion');
      excerpter.weave();
      expect(logs[0].message,
          contains('region "" end without a prior start at $uri:1'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {defaultRegionKey: emptyLines});
      logs.clear();
    });

    test('region a', () {
      final excerpter = new Excerpter(uri, 'abc\n#enddocregion a');
      excerpter.weave();
      expect(logs[0].message,
          contains('region "a" end without a prior start at $uri:2'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
      logs.clear();
    });

    test('region a,b', () {
      final excerpter = new Excerpter(uri, 'abc\n#enddocregion a,b');
      excerpter.weave();
      expect(logs[0].message,
          contains('regions ("a", "b") end without a prior start at $uri:2'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {
        defaultRegionKey: ['abc']
      });
      logs.clear();
    });

    test('start a end default region', () {
      final expectedLines = ['abc'];
      final excerpter = new Excerpter(uri, '#docregion a\nabc\n#enddocregion');
      excerpter.weave();
      expect(logs[0].message,
          contains('region "" end without a prior start at $uri:3'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {
        defaultRegionKey: expectedLines,
        'a': expectedLines,
      });
      logs.clear();
    });
  });

  group('repeated start:', () {
    test('default region', () {
      final excerpter = new Excerpter(uri, '#docregion\n#docregion');
      excerpter.weave();
      expect(
          logs[0].message, contains('repeated start for region "" at $uri:2'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {
        defaultRegionKey: [],
      });
      logs.clear();
    });

    test('region a', () {
      final excerpter = new Excerpter(uri, '#docregion a\n#docregion a');
      excerpter.weave();
      expect(
          logs[0].message, contains('repeated start for region "a" at $uri:2'));
      expect(logs.length, 1);
      expect(excerpter.excerpts, {
        defaultRegionKey: [],
        'a': [],
      });
      logs.clear();
    });
  });
}

void plasterCases() {
  test('region a with 1 plaster', () {
    var content = '''
      #docregion a
      abc
      #enddocregion a
      123
      #docregion a
      def
      #enddocregion a
    ''';
    final excerpter = new Excerpter(uri, content);
    expect(excerpter.weave().excerpts, {
      defaultRegionKey: stripDirectives(content),
      'a': ['abc', defaultPlaster, 'def'],
    });
    _expectNoLogs();
  });

  test('overlapping regions', () {
    var content = '''
      #docregion a,b,c
      abc
      #enddocregion b, c
      #docregion b
      def
      #enddocregion a, b
    ''';
    final excerpter = new Excerpter(uri, content);
    expect(excerpter.weave().excerpts, {
      defaultRegionKey: stripDirectives(content),
      'a': ['abc', 'def'],
      'b': ['abc', defaultPlaster, 'def'],
      'c': ['abc'],
    });
    _expectNoLogs();
  });

  test('plaster with different indentations', () {
    var content = '''
      #docregion a,b,c
      abc
        #enddocregion b, c
      #docregion b
      def
      #enddocregion a, b
    ''';
    final excerpter = new Excerpter(uri, content);
    expect(excerpter.weave().excerpts, {
      defaultRegionKey: stripDirectives(content),
      'a': ['abc', 'def'],
      'b': ['abc', '  $defaultPlaster', 'def'],
      'c': ['abc'],
    });
    _expectNoLogs();
  });
}

// Utils

const eol = '\n';

final _directiveRegEx = new RegExp(r'#(end)?docregion');
final _blankLine = new RegExp(r'^\s*$');

List<String> stripDirectives(String excerpt) {
  final lines = excerpt
      .split(eol)
      .where((line) => !_directiveRegEx.hasMatch(line))
      .toList();
  if (_blankLine.hasMatch(lines.last)) lines.removeLast();
  return lines;
}
