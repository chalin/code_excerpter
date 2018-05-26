import 'dart:io';

import 'package:test/test.dart';
import 'package:code_excerpter/src/excerpter.dart';

List<String> contentGeneratingNoExcerpts = ['', 'abc', 'abc\ndef\n'];

void main() {
  group('no excerpts', () {
    for (final content in contentGeneratingNoExcerpts) {
      final testName = content.replaceAll('\n', '\\n');
      test(testName, () {
        Excerpter excerpter = new Excerpter(content);
        excerpter.weave();
        expect(excerpter.excerpts, {});
      });
    }
  });

  test('default region over empty file', () {
    Excerpter excerpter = new Excerpter('#docregion');
    excerpter.weave();
    expect(excerpter.excerpts, {defaultRegionKey: []});
  });

  test('default region over empty file', () {
    Excerpter excerpter = new Excerpter('#docregion\n');
    excerpter.weave();
    expect(excerpter.excerpts, {
      defaultRegionKey: ['']
    });
  });

//  test('default region over empty file', () {
//    Excerpter excerpter = new Excerpter('#docregion a\n');
//    excerpter.weave();
//    expect(excerpter.excerpts, {
//      defaultRegionKey: [''],
//      'a': ['']
//    });
//  });
}
