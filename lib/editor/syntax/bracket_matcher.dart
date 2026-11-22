import 'json_tokenizer.dart';

/// A character position: 0-based line and UTF-16 column.
typedef TextPos = ({int line, int column});

/// Finds the bracket or quote next to the caret and its partner (§1.1).
///
/// Looks at the character just before the caret first, then the one at the
/// caret. Brackets inside strings are ignored. Returns null when the caret is
/// not next to a bracket or quote, or when it has no partner.
(TextPos, TextPos)? findMatchingPair(List<String> lines, TextPos caret) {
  for (final column in [caret.column - 1, caret.column]) {
    final match = _matchAt(lines, (line: caret.line, column: column));
    if (match != null) return match;
  }
  return null;
}

(TextPos, TextPos)? _matchAt(List<String> lines, TextPos at) {
  if (at.line < 0 || at.line >= lines.length) return null;
  final line = lines[at.line];
  if (at.column < 0 || at.column >= line.length) return null;
  final tokens = tokenizeJsonLine(line);
  final token = tokens.firstWhere(
    (t) => t.start <= at.column && at.column < t.end,
  );
  final char = line[at.column];

  if (token.type == JsonTokenType.key || token.type == JsonTokenType.string) {
    if (char != '"' || !token.terminated) return null;
    if (at.column == token.start) {
      return (at, (line: at.line, column: token.end - 1));
    }
    if (at.column == token.end - 1) {
      return (at, (line: at.line, column: token.start));
    }
    return null;
  }
  if (token.type != JsonTokenType.punctuation) return null;
  const opens = {'{': '}', '[': ']'};
  const closes = {'}': '{', ']': '['};
  if (opens.containsKey(char)) {
    final partner = _scan(lines, at, char, opens[char]!, forward: true);
    return partner == null ? null : (at, partner);
  }
  if (closes.containsKey(char)) {
    final partner = _scan(lines, at, char, closes[char]!, forward: false);
    return partner == null ? null : (at, partner);
  }
  return null;
}

/// Scans from [from] for the bracket that balances it, skipping strings.
TextPos? _scan(
  List<String> lines,
  TextPos from,
  String self,
  String partner, {
  required bool forward,
}) {
  var depth = 0;
  final step = forward ? 1 : -1;
  for (var l = from.line; l >= 0 && l < lines.length; l += step) {
    final brackets = [
      for (final t in tokenizeJsonLine(lines[l]))
        if (t.type == JsonTokenType.punctuation &&
            (lines[l][t.start] == self || lines[l][t.start] == partner))
          t.start,
    ];
    final ordered = forward ? brackets : brackets.reversed;
    for (final column in ordered) {
      if (l == from.line &&
          (forward ? column < from.column : column > from.column)) {
        continue;
      }
      if (lines[l][column] == self) {
        depth++;
      } else {
        depth--;
        if (depth == 0) return (line: l, column: column);
      }
    }
  }
  return null;
}
