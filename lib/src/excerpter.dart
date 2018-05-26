import 'package:code_excerpter/src/util/line.dart';

import 'directive.dart';
import 'util/logging.dart';

/// Key used for excerpt representing the entire file w/o directives
const fullFileKey = '\u0000';
const defaultRegionKey = '';

Map<String, List<String>> newExcerptsMap() => new Map();

class Excerpter {
  final String content;
  final List<String> _lines; // content as list of lines

  // Number of line being processed.
  int _lineNum;
  String get _line => _lines[_lineNum];

  bool containsDirectives = false;

  int get numExcerpts => excerpts.length;

  Excerpter(this.content)
      : _lines = content.split(eol),
        _lineNum = 0;

  final Map<String, List<String>> excerpts = newExcerptsMap();
  final Set<String> _openExcerpts = new Set();

  void weave() {
    final lines = content.split(eol);

    // Collect the full file in case we need it.
    _excerptStart(fullFileKey);

    for (_lineNum = 0; _lineNum < lines.length; _lineNum++) _processLine();

    // Final adjustment to excerpts relative to fullFileKey:
    if (!containsDirectives) {
      // No directives, don't report any excerpts
      excerpts.clear();
    } else if (excerpts.containsKey(defaultRegionKey)) {
      // There was an explicitly named default region. Drop fullFileKey.
      excerpts.remove(fullFileKey);
    } else {
      excerpts[defaultRegionKey] = excerpts[fullFileKey];
      excerpts.remove(fullFileKey);
    }
  }

  void _processLine() {
    final directive = new Directive.tryParse(_line);

    switch (directive?.kind) {
      case Kind.startRegion:
        _startRegion(directive);
        break;
      case Kind.endRegion:
        _endRegion(directive);
        break;
      default:
        if (directive != null)
          throw new Exception('Unimplemented directive: $_line');

        // Add line to open regions:
        _openExcerpts.forEach((name) => excerpts[name].add(_line));
    }
  }

  void _startRegion(Directive directive) {
    List<String> regionNames = [directive.rawArgs];
    log.finer('_startRegion(regionNames = $regionNames)');
    for (final name in regionNames) {
      _excerptStart(name);
    }
    containsDirectives = true;
  }

  void _endRegion(Directive directive) {
    List<String> regionNames = [directive.rawArgs];
    log.finer('_endRegion(regionNames = $regionNames)');
    for (final name in regionNames) {
      if (_openExcerpts.remove(name)) {
        // TODO add special marker. For now just end region
      } else {
        final n = name.startsWith("'") ? name : "'$name'";
        log.warning('WARNING: end before start directive for region $n');
      }
    }
    containsDirectives = true;
  }

  void _excerptStart(String name) {
    if (excerpts.containsKey(name)) return;
    excerpts[name] = [];
    _openExcerpts.add(name);
  }
}
