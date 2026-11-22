/// Kinds of token the Text pane colors differently (§1.1).
enum JsonTokenType {
  key,
  string,
  number,
  boolean,
  nullValue,
  punctuation,
  whitespace,

  /// Anything that is not JSON (shown in the default text color).
  invalid,
}

/// A token in one line: `[start, end)` in UTF-16 code units.
class JsonToken {
  const JsonToken(this.type, this.start, this.end, {this.terminated = true});

  final JsonTokenType type;
  final int start;
  final int end;

  /// For strings and keys: whether the closing quote is on this line.
  final bool terminated;

  @override
  bool operator ==(Object other) =>
      other is JsonToken &&
      other.type == type &&
      other.start == start &&
      other.end == end &&
      other.terminated == terminated;

  @override
  int get hashCode => Object.hash(type, start, end, terminated);

  @override
  String toString() => '$type[$start,$end)${terminated ? '' : ' open'}';
}

final RegExp _number = RegExp(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?');
final RegExp _word = RegExp(r'[A-Za-z0-9_$.+-]+');

/// Splits one line of JSON text into tokens, tolerating invalid text.
///
/// JSON strings cannot contain raw line breaks, so lines can be tokenized
/// on their own. A string is a key when the next non-space character on the
/// line is `:`.
List<JsonToken> tokenizeJsonLine(String line) {
  final tokens = <JsonToken>[];
  var i = 0;
  while (i < line.length) {
    final c = line.codeUnitAt(i);
    if (c == 0x20 || c == 0x09 || c == 0x0D) {
      var j = i + 1;
      while (j < line.length) {
        final d = line.codeUnitAt(j);
        if (d != 0x20 && d != 0x09 && d != 0x0D) break;
        j++;
      }
      tokens.add(JsonToken(JsonTokenType.whitespace, i, j));
      i = j;
    } else if (c == 0x22) {
      var j = i + 1;
      var terminated = false;
      while (j < line.length) {
        final d = line.codeUnitAt(j);
        if (d == 0x5C) {
          j += 2;
          continue;
        }
        j++;
        if (d == 0x22) {
          terminated = true;
          break;
        }
      }
      if (j > line.length) j = line.length;
      final type = _nextIsColon(line, j)
          ? JsonTokenType.key
          : JsonTokenType.string;
      tokens.add(JsonToken(type, i, j, terminated: terminated));
      i = j;
    } else if ('{}[]:,'.codeUnits.contains(c)) {
      tokens.add(JsonToken(JsonTokenType.punctuation, i, i + 1));
      i++;
    } else {
      final number = _number.matchAsPrefix(line, i);
      final word = _word.matchAsPrefix(line, i);
      if (number != null && (word == null || word.end == number.end)) {
        tokens.add(JsonToken(JsonTokenType.number, i, number.end));
        i = number.end;
      } else if (word != null) {
        final text = word[0];
        final type = switch (text) {
          'true' || 'false' => JsonTokenType.boolean,
          'null' => JsonTokenType.nullValue,
          _ => JsonTokenType.invalid,
        };
        tokens.add(JsonToken(type, i, word.end));
        i = word.end;
      } else {
        // One character that is not JSON (keep surrogate pairs together).
        final isHigh = c >= 0xD800 && c <= 0xDBFF && i + 1 < line.length;
        final end = isHigh ? i + 2 : i + 1;
        tokens.add(JsonToken(JsonTokenType.invalid, i, end));
        i = end;
      }
    }
  }
  return tokens;
}

bool _nextIsColon(String line, int from) {
  for (var k = from; k < line.length; k++) {
    final c = line.codeUnitAt(k);
    if (c == 0x20 || c == 0x09 || c == 0x0D) continue;
    return c == 0x3A;
  }
  return false;
}
