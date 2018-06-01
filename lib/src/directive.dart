import 'nullable.dart';

/// Directives usually appear inside a line comment.
///
/// Ignore any close-comment syntax:
///
/// - CSS and Java-like languages: `*/`
/// - HTML: `-->`
///
final _directiveRegEx = new RegExp(
    r'^(\s*)(\S.*?)?#((?:end)?docregion)\b\s*(.*?)(?:\s*(?:-->|\*\/))?\s*$');

final _argSeparator = new RegExp(r'\s*,\s*');

/// Represents a code-excerpter directive (both the model and lexical elements)
class Directive {
  static final int _lexemeIndex = 3;

  final Match _match;
  final Kind kind;

  List<String> _args;

  String get line => _match[0];

  /// Whitespace before the directive
  String get indentation => _match[1];

  /// Characters at the start of the line before the directive lexeme
  String get prefix => _match[1] + (_match[2] ?? '');

  /// The directive's lexeme
  String get lexeme => _match[_lexemeIndex];

  /// Raw string corresponding to the directive's arguments
  String get rawArgs => _match[4];

  List<String> get args => _args ??= _parseArgs();

  Directive._(this.kind, this._match);

  @nullable
  factory Directive.tryParse(String line) {
    final match = _directiveRegEx.firstMatch(line);
    if (match == null) return null;

    final lexeme = match[_lexemeIndex];
    final kind = tryParseKind(lexeme);
    return kind == null ? null : new Directive._(kind, match);
  }

  List<String> _parseArgs() =>
      rawArgs.isEmpty ? [] : rawArgs.split(_argSeparator);
}

enum Kind {
  startRegion,
  endRegion,
  plaster, // TO be deprecated
}

@nullable
Kind tryParseKind(String lexeme) {
  switch (lexeme) {
    case 'docregion':
      return Kind.startRegion;
    case 'enddocregion':
      return Kind.endRegion;
    case 'docplaster':
      return Kind.plaster;
    default:
      return null;
  }
}
