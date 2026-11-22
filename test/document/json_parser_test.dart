import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/json_node.dart';
import 'package:json_better_editor/document/json_parser.dart';

JsonNode parseOk(String text) {
  final result = parseJson(text);
  if (result is! JsonParseSuccess) fail('expected success, got $result');
  return result.root;
}

JsonParseFailure parseBad(String text) {
  final result = parseJson(text);
  if (result is! JsonParseFailure) fail('expected failure for: $text');
  return result;
}

void main() {
  group('parses each of the six types', () {
    test('string', () {
      expect(parseOk('"hello"'), const JsonString('hello'));
      expect(parseOk('"hello"').type, JsonType.string);
    });

    test('string escapes', () {
      expect(
        parseOk(r'"a\"b\\c\/d\b\f\n\r\tAก"'),
        const JsonString('a"b\\c/d\b\f\n\r\tAก'),
      );
    });

    test('number keeps its source text', () {
      for (final n in [
        '0',
        '-1',
        '42',
        '3.14',
        '1.0',
        '-0.5e10',
        '1E+3',
        '2e-2',
        '123456789012345678901234567890',
      ]) {
        final node = parseOk(n);
        expect(node, JsonNumber(n));
        expect(node.type, JsonType.number);
      }
      expect((parseOk('3.14') as JsonNumber).value, 3.14);
    });

    test('boolean', () {
      expect(parseOk('true'), const JsonBool(true));
      expect(parseOk('false'), const JsonBool(false));
      expect(parseOk('true').type, JsonType.boolean);
    });

    test('null', () {
      expect(parseOk('null'), const JsonNull());
      expect(parseOk('null').type, JsonType.nullValue);
    });

    test('object', () {
      final node = parseOk('{"a": 1}');
      expect(node.type, JsonType.object);
      expect((node as JsonObject)['a'], const JsonNumber('1'));
    });

    test('array', () {
      final node = parseOk('[1, "x", null]');
      expect(node.type, JsonType.array);
      expect((node as JsonArray).items, [
        const JsonNumber('1'),
        const JsonString('x'),
        const JsonNull(),
      ]);
    });
  });

  test('empty object and empty array', () {
    expect(parseOk('{}'), JsonObject([]));
    expect(parseOk(' [ ] '), JsonArray([]));
    expect(
      parseOk('{"a": {}, "b": []}'),
      JsonObject([
        JsonMember('a', JsonObject([])),
        JsonMember('b', JsonArray([])),
      ]),
    );
  });

  test('nested structures', () {
    final node = parseOk('''
{
  "name": "demo",
  "tags": ["a", {"deep": [1, [2, [3]]]}],
  "meta": {"ok": true, "none": null, "n": -1.5}
}
''');
    expect(
      node,
      JsonObject([
        const JsonMember('name', JsonString('demo')),
        JsonMember(
          'tags',
          JsonArray([
            const JsonString('a'),
            JsonObject([
              JsonMember(
                'deep',
                JsonArray([
                  const JsonNumber('1'),
                  JsonArray([
                    const JsonNumber('2'),
                    JsonArray([const JsonNumber('3')]),
                  ]),
                ]),
              ),
            ]),
          ]),
        ),
        JsonMember(
          'meta',
          JsonObject([
            const JsonMember('ok', JsonBool(true)),
            const JsonMember('none', JsonNull()),
            const JsonMember('n', JsonNumber('-1.5')),
          ]),
        ),
      ]),
    );
  });

  test('keeps object key order', () {
    final node = parseOk('{"z": 1, "a": 2, "m": 3, "b": 4}') as JsonObject;
    expect(node.keys, ['z', 'a', 'm', 'b']);
  });

  test('Thai text in keys and values', () {
    final node = parseOk(
      '{"ชื่อ": "สวัสดีครับ", "รายการ": ["หนึ่ง", "สอง"]}',
    ) as JsonObject;
    expect(node.keys, ['ชื่อ', 'รายการ']);
    expect(node['ชื่อ'], const JsonString('สวัสดีครับ'));
    expect(
      node['รายการ'],
      JsonArray([const JsonString('หนึ่ง'), const JsonString('สอง')]),
    );
  });

  test('tolerates a leading byte order mark', () {
    expect(
      parseOk('﻿{"a": 1}'),
      JsonObject([const JsonMember('a', JsonNumber('1'))]),
    );
  });

  group('invalid text returns line and column instead of throwing', () {
    final cases = <String, (int, int)>{
      '': (1, 1),
      '   \n  ': (2, 3),
      '{': (1, 2),
      '{"a": 1,}': (1, 9),
      '{\n  "a": 1\n  "b": 2\n}': (3, 3),
      '[1, 2': (1, 6),
      '{"a" 1}': (1, 6),
      '{a: 1}': (1, 2),
      '"unterminated': (1, 1),
      '01': (1, 1),
      '1.': (1, 1),
      'tru': (1, 1),
      '{"x": undefined}': (1, 7),
      '[1] [2]': (1, 5),
      "{'a': 1}": (1, 2),
      '"bad \\x escape"': (1, 6),
      '{\n  "ชื่อ": ผิด\n}': (2, 11),
    };
    for (final entry in cases.entries) {
      test(entry.key.replaceAll('\n', r'\n'), () {
        final failure = parseBad(entry.key);
        expect(
          (failure.line, failure.column),
          entry.value,
          reason: failure.message,
        );
        expect(failure.message, isNotEmpty);
      });
    }
  });

  test('deep nesting fails cleanly', () {
    final text = '${'[' * 10000}${']' * 10000}';
    expect(parseBad(text).message, contains('deep'));
  });
}
