import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/editor/syntax/bracket_matcher.dart';

const doc = [
  '{', //                      0
  '  "a": [1, {"b": "}"}],', // 1
  '  "c": "x"', //             2
  '}', //                      3
];

(TextPos, TextPos)? at(int line, int column, [List<String> lines = doc]) =>
    findMatchingPair(lines, (line: line, column: column));

TextPos p(int line, int column) => (line: line, column: column);

void main() {
  test('caret after an opening brace matches the closing one', () {
    expect(at(0, 1), (p(0, 0), p(3, 0)));
  });

  test('caret before a closing brace matches the opening one', () {
    expect(at(3, 0), (p(3, 0), p(0, 0)));
  });

  test('square brackets across nested objects', () {
    // `[` at column 7 of line 1, `]` at column 21.
    expect(at(1, 8), (p(1, 7), p(1, 21)));
    expect(at(1, 22), (p(1, 21), p(1, 7)));
  });

  test('brackets inside strings are ignored', () {
    // `{` at 11 matches the `}` at 20, not the "}" inside the string at 18.
    expect(at(1, 12), (p(1, 11), p(1, 20)));
    expect(at(1, 21), (p(1, 20), p(1, 11)));
    // Caret beside the string "}" (17..19) is a quote match.
    expect(at(1, 18), (p(1, 17), p(1, 19)));
  });

  test('quotes match the other end of their string', () {
    // `"c"` starts at column 2 on line 2.
    expect(at(2, 2), (p(2, 2), p(2, 4)));
    expect(at(2, 5), (p(2, 4), p(2, 2)));
  });

  test('the character before the caret wins over the one after it', () {
    // Caret between `}` (20) and `]` (21): the `}` before the caret is used.
    expect(at(1, 21)!.$1, p(1, 20));
  });

  test('unmatched brackets and quotes are not paired', () {
    expect(at(0, 1, ['{', '  "a": 1']), isNull);
    expect(at(0, 2, ['[1, 2']), isNull);
    expect(at(0, 1, ['"abc']), isNull);
    expect(at(0, 3, ['  ]']), isNull);
  });

  test('no pair when the caret is not next to a bracket or quote', () {
    expect(at(2, 6), isNull); // between `:` and a space
    expect(at(1, 9), isNull); // between `1` and `,`
  });
}
