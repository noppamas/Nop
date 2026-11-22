import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/editor/syntax/json_tokenizer.dart';

/// (type, text) pairs for the non-whitespace tokens of [line].
List<(JsonTokenType, String)> tokens(String line) => [
  for (final t in tokenizeJsonLine(line))
    if (t.type != JsonTokenType.whitespace)
      (t.type, line.substring(t.start, t.end)),
];

void main() {
  test('each token type', () {
    expect(
      tokens('{"k": "v", "n": -1.5e3, "t": true, "f": false, "z": null}'),
      [
        (JsonTokenType.punctuation, '{'),
        (JsonTokenType.key, '"k"'),
        (JsonTokenType.punctuation, ':'),
        (JsonTokenType.string, '"v"'),
        (JsonTokenType.punctuation, ','),
        (JsonTokenType.key, '"n"'),
        (JsonTokenType.punctuation, ':'),
        (JsonTokenType.number, '-1.5e3'),
        (JsonTokenType.punctuation, ','),
        (JsonTokenType.key, '"t"'),
        (JsonTokenType.punctuation, ':'),
        (JsonTokenType.boolean, 'true'),
        (JsonTokenType.punctuation, ','),
        (JsonTokenType.key, '"f"'),
        (JsonTokenType.punctuation, ':'),
        (JsonTokenType.boolean, 'false'),
        (JsonTokenType.punctuation, ','),
        (JsonTokenType.key, '"z"'),
        (JsonTokenType.punctuation, ':'),
        (JsonTokenType.nullValue, 'null'),
        (JsonTokenType.punctuation, '}'),
      ],
    );
  });

  test('a key is a string followed by a colon, even with spaces', () {
    expect(tokens('  "name"   :  "x"'), [
      (JsonTokenType.key, '"name"'),
      (JsonTokenType.punctuation, ':'),
      (JsonTokenType.string, '"x"'),
    ]);
    expect(
      tokens('["a", "b"]').where((t) => t.$1 == JsonTokenType.key),
      isEmpty,
    );
  });

  test('escapes inside strings do not end them', () {
    expect(tokens(r'"a\"b\\": "c\"}"'), [
      (JsonTokenType.key, r'"a\"b\\"'),
      (JsonTokenType.punctuation, ':'),
      (JsonTokenType.string, r'"c\"}"'),
    ]);
  });

  test('brackets inside strings are part of the string', () {
    expect(tokens('"{[]}"'), [(JsonTokenType.string, '"{[]}"')]);
  });

  test('Thai text in keys and values', () {
    expect(tokens('"ชื่อ": "สวัสดี"'), [
      (JsonTokenType.key, '"ชื่อ"'),
      (JsonTokenType.punctuation, ':'),
      (JsonTokenType.string, '"สวัสดี"'),
    ]);
  });

  test('tolerates invalid text while typing', () {
    final unterminated = tokenizeJsonLine('"abc');
    expect(unterminated.single.type, JsonTokenType.string);
    expect(unterminated.single.terminated, isFalse);
    expect(tokens('{"a": tru'), [
      (JsonTokenType.punctuation, '{'),
      (JsonTokenType.key, '"a"'),
      (JsonTokenType.punctuation, ':'),
      (JsonTokenType.invalid, 'tru'),
    ]);
    expect(tokens("'x' 😀"), [
      (JsonTokenType.invalid, "'"),
      (JsonTokenType.invalid, 'x'),
      (JsonTokenType.invalid, "'"),
      (JsonTokenType.invalid, '😀'),
    ]);
    expect(tokens('12abc'), [(JsonTokenType.invalid, '12abc')]);
  });

  test('tokens cover the whole line without gaps', () {
    const line = ' {"ก": [1, true, null, "x"]} ?? ';
    final all = tokenizeJsonLine(line);
    expect(all.first.start, 0);
    expect(all.last.end, line.length);
    for (var i = 1; i < all.length; i++) {
      expect(all[i].start, all[i - 1].end);
    }
  });
}
