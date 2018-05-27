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
      final d = new Directive.tryParse(' // #docregion');
      expect(d.kind, Kind.startRegion);
      expect(d.rawArgs, '');
      expect(d.args, []);
    });

    test(Kind.endRegion, () {
      final d = new Directive.tryParse(' #enddocregion a,b,  c  ');
      expect(d.kind, Kind.endRegion);
      expect(d.rawArgs, 'a,b,  c');
      expect(d.args, ['a', 'b', 'c']);
    });
  });

  group('close comment syntax:', () {
    group('HTML:', () {
      test(Kind.startRegion, () {
        final d = new Directive.tryParse('<!--#docregion-->');
        expect(d.kind, Kind.startRegion);
        expect(d.rawArgs, '');
        expect(d.args, []);
      });

      test(Kind.endRegion, () {
        final d = new Directive.tryParse('<!-- #enddocregion a -->  ');
        expect(d.kind, Kind.endRegion);
        expect(d.rawArgs, 'a');
        expect(d.args, ['a']);
      });
    });

    group('CSS:', () {
      test(Kind.startRegion, () {
        final d = new Directive.tryParse('/*#docregion*/');
        expect(d.kind, Kind.startRegion);
        expect(d.rawArgs, '');
        expect(d.args, []);
      });

      test(Kind.endRegion, () {
        final d = new Directive.tryParse('/* #enddocregion a */  ');
        expect(d.kind, Kind.endRegion);
        expect(d.rawArgs, 'a');
        expect(d.args, ['a']);
      });
    });
  });
}
