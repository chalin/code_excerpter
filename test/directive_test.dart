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
      expect(d?.kind, Kind.startRegion);
    });

    test(Kind.endRegion, () {
      final d = new Directive.tryParse('#enddocregion');
      expect(d?.kind, Kind.endRegion);
    });
  });

  // Leading and trailing text is ignored
  group('context insenstivie', () {

    test(Kind.startRegion, () {
      final d = new Directive.tryParse(' // #docregion');
      expect(d?.kind, Kind.startRegion);
    });

    test(Kind.endRegion, () {
      final d = new Directive.tryParse(' #enddocregion a,b,c  ');
      expect(d?.kind, Kind.endRegion);
    });
  });


}
