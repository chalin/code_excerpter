import 'package:code_excerpter/src/util/line.dart';

import 'directive.dart';
import 'util/logging.dart';

/// Key used for excerpt representing the entire file w/o directives
const fullFileKey = '\u0000';
const defaultRegionKey = '';

Map<String, List<String>> newExcerptsMap() => new Map();

class Excerpter {
  final String uri;
  final String content;
  final List<String> _lines; // content as list of lines

  // Index of next line to process.
  int _lineIdx;
  int get _lineNum => _lineIdx + 1;
  String get _line => _lines[_lineIdx];

  bool containsDirectives = false;

  int get numExcerpts => excerpts.length;

  Excerpter(this.uri, this.content)
      : _lines = content.split(eol),
        _lineIdx = 0;

  final Map<String, List<String>> excerpts = newExcerptsMap();
  final Set<String> _openExcerpts = new Set();

  void weave() {
    final lines = content.split(eol);

    // Collect the full file in case we need it.
    _excerptStart(fullFileKey);

    for (_lineIdx = 0; _lineIdx < lines.length; _lineIdx++) _processLine();

    // Drop trailing blank lines for all excerpts.
    // Normalize indentation for all but the full file.
    for (final name in excerpts.keys) {
      dropTrailingBlankLines(excerpts[name]);
      if (name == fullFileKey) continue;
      excerpts[name] = maxUnindent(excerpts[name]);
    }

    // Final adjustment to excerpts relative to fullFileKey:
    if (!containsDirectives) {
      // No directives? Don't report any excerpts
      excerpts.clear();
    } else if (excerpts.containsKey(defaultRegionKey)) {
      // There was an explicitly named default region. Drop fullFileKey.
      excerpts.remove(fullFileKey);
    } else {
      // Report fullFileKey excerpt for defaultRegionKey
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
    var regionNames = directive.args;
    log.finer('_startRegion(regionNames = $regionNames)');

    if (regionNames.isEmpty) regionNames.add(defaultRegionKey);
    for (final name in regionNames) {
      _excerptStart(name);
    }
    containsDirectives = true;
  }

  void _endRegion(Directive directive) {
    var regionNames = directive.args;
    log.finer('_endRegion(regionNames = $regionNames)');

//    if (regionNames.isEmpty) {
//      _warn('support for ${directive.lexeme} without arguments isn\'t fully implemented');
//    }

    for (final name in regionNames) {
      if (_openExcerpts.remove(name)) {
        // TODO add special marker. For now just end region
      } else {
        final n = name.startsWith("'") ? name : '"$name"';
        _warn('region $n end without a prior region start');
      }
    }
    containsDirectives = true;
  }

  void _excerptStart(String name) {
    _openExcerpts.add(name);
    excerpts.putIfAbsent(name, () => []);
  }

  void _warn(String msg) => log.warning('$msg at $uri:$_lineNum');
}