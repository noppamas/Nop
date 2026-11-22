import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/editor/syntax/json_chunk_analyzer.dart';

void main() {
  test('every multi-line object and array is a chunk', () {
    expect(
      findJsonChunks([
        '{', //                 0
        '  "a": [', //          1
        '    1,', //            2
        '    {"b": 2}', //      3  (single line: not foldable)
        '  ],', //              4
        '  "c": {', //          5
        '    "d": null', //     6
        '  }', //               7
        '}', //                 8
      ]),
      [(0, 8), (1, 4), (5, 7)],
    );
  });

  test('brackets inside strings are ignored', () {
    expect(findJsonChunks(['{', '  "a": "{[",', '  "b": "]}"', '}']), [(0, 3)]);
  });

  test('a line opening several blocks folds the outermost', () {
    expect(findJsonChunks(['[{', '  "a": 1', '}]']), [(0, 2)]);
  });

  test('invalid text does not throw and still finds closed blocks', () {
    expect(findJsonChunks(['{', '  "a": [', '}']), [(0, 2)]);
    expect(findJsonChunks(['}', '{', ']']), isEmpty);
    expect(findJsonChunks(['{', '  "x"']), isEmpty);
  });
}
