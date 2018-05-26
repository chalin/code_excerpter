import 'util.dart';

/// Key used for excerpt representing the entire file w/o directives
const fullFileKey = '\u0000';
const defaultRegionKey = '';

Map<String, List<String>> newExcerptsMap() => new Map();

class Excerpter {
  final _directiveRegEx = new RegExp(r'#((?:end)?docregion)\b(.*)$');

  final String content;

  // Number of line being processed.
  int _lineNum = 0;

  bool containsDirectives = false;

  int get numExcerpts => excerpts.length;

  Excerpter(this.content);

  final Map<String, List<String>> excerpts = newExcerptsMap();
  final Set<String> _openExcerpts = new Set();

  void weave() {
    final lines = content.split(eol);

    // Collect the full file in case we need it.
    _excerptStart(fullFileKey);

    _lineNum = 0;
    for (final line in lines) {
      _lineNum++;
      _processLine(line);
    }

    // Don't provid
    if (!containsDirectives) {
      // No directives, don't report any regions
      excerpts.clear();
    } else if (excerpts.containsKey(defaultRegionKey)) {
      // There was an explicitly named default region. Drop fullFileKey.
      excerpts.remove(fullFileKey);
    } else {
      excerpts[defaultRegionKey] = excerpts[fullFileKey];
      excerpts.remove(fullFileKey);
    }
  }

  void _processLine(String line) {
    final match = _directiveRegEx.firstMatch(line);
    if (match == null) {
      _addToOpenExcerpts(line);
    } else if (match[1] == 'docregion') {
      containsDirectives = true;
    } else if (match[1] == 'enddocregion') {
      containsDirectives = true;
    } else {
      throw new Exception('Unexpected directive: ${match[1]}');
    }
  }

  void _addToOpenExcerpts(String line) {
    _openExcerpts.forEach((name) => excerpts[name].add(line));
  }

  bool _isOpenDirective(String line) => null;

  void _excerptStart(String name) {
    if (excerpts.containsKey(name)) return;
    excerpts[name] = [];
    _openExcerpts.add(name);
  }
}
