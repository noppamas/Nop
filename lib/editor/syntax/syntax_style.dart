import 'package:material_ui/material_ui.dart';

import 'json_tokenizer.dart';

/// Colors for the Text pane's syntax highlighting (§1.1).
///
/// A basic light palette for now; Atom One Light / One Dark arrive in Phase
/// 4. Type colors follow the Node mode type icons (§2.2).
class SyntaxStyle {
  const SyntaxStyle({
    required this.key,
    required this.string,
    required this.number,
    required this.boolean,
    required this.nullValue,
    required this.punctuation,
    required this.matchBackground,
  });

  static const light = SyntaxStyle(
    key: Color(0xFFA626A4),
    string: Color(0xFF50A14F),
    number: Color(0xFF4078F2),
    boolean: Color(0xFFC18401),
    nullValue: Color(0xFF8E8F96),
    punctuation: Color(0xFF383A42),
    matchBackground: Color(0x404078F2),
  );

  final Color key;
  final Color string;
  final Color number;
  final Color boolean;
  final Color nullValue;
  final Color punctuation;

  /// Background behind a matched bracket or quote pair.
  final Color matchBackground;

  /// Text color for [type], or null for the default text color.
  Color? colorFor(JsonTokenType type) => switch (type) {
    JsonTokenType.key => key,
    JsonTokenType.string => string,
    JsonTokenType.number => number,
    JsonTokenType.boolean => boolean,
    JsonTokenType.nullValue => nullValue,
    JsonTokenType.punctuation => punctuation,
    JsonTokenType.whitespace || JsonTokenType.invalid => null,
  };
}

/// Builds the colored span for one line. [highlightColumns] are columns to
/// mark as a matched bracket or quote.
TextSpan buildHighlightedLine(
  String line,
  TextStyle base,
  SyntaxStyle style, {
  Set<int> highlightColumns = const {},
}) {
  final children = <TextSpan>[];
  for (final token in tokenizeJsonLine(line)) {
    final color = style.colorFor(token.type);
    final tokenStyle = color == null ? base : base.copyWith(color: color);
    var start = token.start;
    for (final column in highlightColumns.toList()..sort()) {
      if (column < token.start || column >= token.end) continue;
      if (column > start) {
        children.add(
          TextSpan(text: line.substring(start, column), style: tokenStyle),
        );
      }
      children.add(
        TextSpan(
          text: line.substring(column, column + 1),
          style: tokenStyle.copyWith(backgroundColor: style.matchBackground),
        ),
      );
      start = column + 1;
    }
    if (start < token.end) {
      children.add(
        TextSpan(text: line.substring(start, token.end), style: tokenStyle),
      );
    }
  }
  return TextSpan(style: base, children: children);
}
