import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/editor/syntax/json_tokenizer.dart';
import 'package:json_better_editor/editor/syntax/syntax_style.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const base = TextStyle(color: Color(0xFF000000), fontSize: 13);
  const style = SyntaxStyle.light;

  Color? colorOf(TextSpan line, String text) => line.children!
      .cast<TextSpan>()
      .firstWhere((s) => s.text == text)
      .style
      ?.color;

  test('six distinct colors for keys, strings, numbers, booleans, null, '
      'punctuation', () {
    final colors = {
      for (final type in [
        JsonTokenType.key,
        JsonTokenType.string,
        JsonTokenType.number,
        JsonTokenType.boolean,
        JsonTokenType.nullValue,
        JsonTokenType.punctuation,
      ])
        style.colorFor(type),
    };
    expect(colors.length, 6);
    expect(colors, isNot(contains(null)));
  });

  test('a line gets one span per token with its color', () {
    final span = buildHighlightedLine('"k": ["s", 1, true, null]', base, style);
    expect(span.toPlainText(), '"k": ["s", 1, true, null]');
    expect(colorOf(span, '"k"'), style.key);
    expect(colorOf(span, '"s"'), style.string);
    expect(colorOf(span, '1'), style.number);
    expect(colorOf(span, 'true'), style.boolean);
    expect(colorOf(span, 'null'), style.nullValue);
    expect(colorOf(span, '['), style.punctuation);
    expect(style.key, isNot(style.string));
  });

  test('matched columns get the match background', () {
    final span = buildHighlightedLine(
      '{"a": "b"}',
      base,
      style,
      highlightColumns: {0, 9},
    );
    expect(span.toPlainText(), '{"a": "b"}');
    final marked = span.children!
        .cast<TextSpan>()
        .where((s) => s.style?.backgroundColor == style.matchBackground)
        .map((s) => s.text)
        .toList();
    expect(marked, ['{', '}']);
  });

  test('a matched quote splits its string span', () {
    final span = buildHighlightedLine(
      '"ab"',
      base,
      style,
      highlightColumns: {0, 3},
    );
    expect(span.children!.cast<TextSpan>().map((s) => s.text), [
      '"',
      'ab',
      '"',
    ]);
    expect(span.toPlainText(), '"ab"');
  });
}
