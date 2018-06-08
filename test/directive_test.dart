import 'package:test/test.dart';

import 'package:code_excerpter/src/directive.dart';

void main() {
  group('basic', () {
    test('not a directive', () {
      final d = new Directive.tryParse('');
      expect(d, isNull);
    });

    test(Kind.startRegion, () {
      final d = new Directive.tryParse('#docregion');
      expect(d.kind, Kind.startRegion);
      expect(d.rawArgs, '');
      expect(d.args, []);
    });

    test(Kind.endRegion, () {
      final d = new Directive.tryParse('#enddocregion');
      expect(d.kind, Kind.endRegion);
      expect(d.rawArgs, '');
      expect(d.args, []);
    });
  });

  // Leading and trailing text is ignored
  group('context insenstivie', () {
    test(Kind.startRegion, () {
      final spaces = '  ';
      final d = new Directive.tryParse('$spaces// #docregion');
      expect(d.kind, Kind.startRegion);
      expect(d.rawArgs, '');
      expect(d.args, []);
      expect(d.indentation, spaces);
    });

    test(Kind.endRegion, () {
      final d = new Directive.tryParse(' #enddocregion a,b,  c  ');
      expect(d.kind, Kind.endRegion);
      expect(d.rawArgs, 'a,b,  c');
      expect(d.args, ['a', 'b', 'c']);
      expect(d.indentation, ' ');
    });
  });

  group('close comment syntax:', () {
    group('HTML:', () {
      test(Kind.startRegion, () {
        final d = new Directive.tryParse('<!--#docregion-->');
        expect(d.kind, Kind.startRegion);
        expect(d.rawArgs, '');
        expect(d.args, []);
        expect(d.indentation, '');
      });

      test(Kind.endRegion, () {
        final d = new Directive.tryParse('<!-- #enddocregion a -->  ');
        expect(d.kind, Kind.endRegion);
        expect(d.rawArgs, 'a');
        expect(d.args, ['a']);
        expect(d.indentation, '');
      });
    });

    group('CSS:', () {
      test(Kind.startRegion, () {
        final d = new Directive.tryParse('/*#docregion*/');
        expect(d.kind, Kind.startRegion);
        expect(d.rawArgs, '');
        expect(d.args, []);
        expect(d.indentation, '');
      });

      test(Kind.endRegion, () {
        final d = new Directive.tryParse('/* #enddocregion a */  ');
        expect(d.kind, Kind.endRegion);
        expect(d.rawArgs, 'a');
        expect(d.args, ['a']);
        expect(d.indentation, '');
      });
    });
  });

  group('problem cases:', () {
    test('Duplicate "a" region', () {
      final d = new Directive.tryParse('#docregion a,b,c,a');
      expect(d.kind, Kind.startRegion);
      expect(d.rawArgs, 'a,b,c,a');
      expect(d.args, ['a', 'b', 'c']);
      expect(d.issues, ['repeated argument "a"']);
    });

    test('Duplicate "" region', () {
      final d = new Directive.tryParse('#docregion ,');
      expect(d.kind, Kind.startRegion);
      expect(d.rawArgs, ',');
      expect(d.args, ['']);
      expect(d.issues, ['repeated argument ""']);
    });
  });
}
