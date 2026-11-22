import 'package:re_editor/re_editor.dart';

import 'json_tokenizer.dart';

/// Finds the foldable blocks of a JSON document for the Text pane gutter
/// (§1.1): every object `{}` or array `[]` that spans more than one line.
/// Brackets inside strings are ignored.
class JsonChunkAnalyzer implements CodeChunkAnalyzer {
  const JsonChunkAnalyzer();

  @override
  List<CodeChunk> run(CodeLines codeLines) {
    return findJsonChunks([
      for (var i = 0; i < codeLines.length; i++) codeLines[i].text,
    ]).map((c) => CodeChunk(c.$1, c.$2)).toList();
  }
}

/// `(startLine, endLine)` of every multi-line object or array, sorted by
/// start line. A line that opens several blocks folds the outermost one.
List<(int, int)> findJsonChunks(List<String> lines) {
  final stack = <(int, String)>[];
  final chunks = <int, int>{};
  for (var l = 0; l < lines.length; l++) {
    final line = lines[l];
    for (final token in tokenizeJsonLine(line)) {
      if (token.type != JsonTokenType.punctuation) continue;
      final c = line[token.start];
      if (c == '{' || c == '[') {
        stack.add((l, c));
      } else if (c == '}' || c == ']') {
        final open = c == '}' ? '{' : '[';
        // Drop unclosed openers of the other kind (invalid text).
        while (stack.isNotEmpty && stack.last.$2 != open) {
          stack.removeLast();
        }
        if (stack.isEmpty) continue;
        final (start, _) = stack.removeLast();
        if (l > start) {
          final existing = chunks[start];
          if (existing == null || l > existing) chunks[start] = l;
        }
      }
    }
  }
  return chunks.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => a.$1.compareTo(b.$1));
}
