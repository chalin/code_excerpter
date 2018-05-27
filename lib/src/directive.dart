import 'nullable.dart';

/// Directives usually appear inside a line comment. HTML doesn't support
/// line comments, so we ignore an trailing `-->` syntax, since that couldn't
/// be a valid argument anyway.
final _directiveRegEx =
    new RegExp(r'#((?:end)?docregion)\b\s*(.*?)(?:\s*-->)?\s*$');

final _argSeparator = new RegExp(r'\s*,\s*');

/// Represents a code-excerpter directive (both the model and lexical elements)
class Directive {
  final Match _match;
  final Kind kind;

  List<String> _args;

  String get line => _match[0];
  String get lexeme => _match[1];
  String get rawArgs => _match[2];

  List<String> get args => _args ??= _parseArgs();

  Directive._(this.kind, this._match);

  @nullable
  factory Directive.tryParse(String line) {
    final match = _directiveRegEx.firstMatch(line);
    if (match == null) return null;

    final lexeme = match[1];
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
