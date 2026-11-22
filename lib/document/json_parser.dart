import 'json_node.dart';

/// Result of [parseJson]: either a [JsonParseSuccess] or a
/// [JsonParseFailure]. Parsing never throws.
sealed class JsonParseResult {
  const JsonParseResult();
}

class JsonParseSuccess extends JsonParseResult {
  const JsonParseSuccess(this.root);

  final JsonNode root;
}

/// Where and why the text is not valid JSON. [line] and [column] are
/// 1-based; [column] counts UTF-16 code units from the start of the line.
class JsonParseFailure extends JsonParseResult {
  const JsonParseFailure({
    required this.message,
    required this.offset,
    required this.line,
    required this.column,
  });

  final String message;
  final int offset;
  final int line;
  final int column;

  @override
  String toString() => '$message (line $line, column $column)';
}

/// Parses [text] (RFC 8259 JSON) into the document model.
JsonParseResult parseJson(String text) {
  final parser = _Parser(text);
  try {
    return JsonParseSuccess(parser.parseDocument());
  } on _ParseError catch (error) {
    var line = 1;
    var lineStart = 0;
    for (var i = 0; i < error.offset && i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        line++;
        lineStart = i + 1;
      }
    }
    return JsonParseFailure(
      message: error.message,
      offset: error.offset,
      line: line,
      column: error.offset - lineStart + 1,
    );
  }
}

class _ParseError implements Exception {
  _ParseError(this.message, this.offset);

  final String message;
  final int offset;
}

class _Parser {
  _Parser(this.text);

  final String text;
  int pos = 0;

  static const _maxDepth = 512;
  int _depth = 0;

  JsonNode parseDocument() {
    // A UTF-8 byte order mark is tolerated at the very start.
    if (text.startsWith('﻿')) pos = 1;
    _skipWhitespace();
    if (pos >= text.length) {
      throw _ParseError('The document is empty', pos);
    }
    final root = _parseValue();
    _skipWhitespace();
    if (pos < text.length) {
      throw _ParseError('Unexpected text after the JSON value', pos);
    }
    return root;
  }

  int get _current => text.codeUnitAt(pos);

  void _skipWhitespace() {
    while (pos < text.length) {
      final c = _current;
      if (c == 0x20 || c == 0x0A || c == 0x0D || c == 0x09) {
        pos++;
      } else {
        break;
      }
    }
  }

  Never _unexpected(String expected) {
    if (pos >= text.length) {
      throw _ParseError('Unexpected end of file, expected $expected', pos);
    }
    final char = text[pos];
    throw _ParseError("Unexpected '$char', expected $expected", pos);
  }

  JsonNode _parseValue() {
    if (pos >= text.length) _unexpected('a value');
    switch (_current) {
      case 0x7B: // {
        return _nested(_parseObject);
      case 0x5B: // [
        return _nested(_parseArray);
      case 0x22: // "
        return JsonString(_parseString());
      case 0x74: // t
        _literal('true');
        return const JsonBool(true);
      case 0x66: // f
        _literal('false');
        return const JsonBool(false);
      case 0x6E: // n
        _literal('null');
        return const JsonNull();
      default:
        final c = _current;
        if (c == 0x2D || (c >= 0x30 && c <= 0x39)) return _parseNumber();
        _unexpected('a value');
    }
  }

  JsonNode _nested(JsonNode Function() parse) {
    if (++_depth > _maxDepth) {
      throw _ParseError('Nesting is too deep', pos);
    }
    final node = parse();
    _depth--;
    return node;
  }

  void _literal(String word) {
    if (!text.startsWith(word, pos)) _unexpected('a value');
    pos += word.length;
  }

  JsonObject _parseObject() {
    pos++; // {
    final members = <JsonMember>[];
    _skipWhitespace();
    if (pos < text.length && _current == 0x7D) {
      pos++;
      return JsonObject(members);
    }
    while (true) {
      _skipWhitespace();
      if (pos >= text.length || _current != 0x22) {
        _unexpected('a key in double quotes');
      }
      final key = _parseString();
      _skipWhitespace();
      if (pos >= text.length || _current != 0x3A) _unexpected("':'");
      pos++;
      _skipWhitespace();
      members.add(JsonMember(key, _parseValue()));
      _skipWhitespace();
      if (pos >= text.length) _unexpected("',' or '}'");
      if (_current == 0x2C) {
        pos++;
        continue;
      }
      if (_current == 0x7D) {
        pos++;
        return JsonObject(members);
      }
      _unexpected("',' or '}'");
    }
  }

  JsonArray _parseArray() {
    pos++; // [
    final items = <JsonNode>[];
    _skipWhitespace();
    if (pos < text.length && _current == 0x5D) {
      pos++;
      return JsonArray(items);
    }
    while (true) {
      _skipWhitespace();
      items.add(_parseValue());
      _skipWhitespace();
      if (pos >= text.length) _unexpected("',' or ']'");
      if (_current == 0x2C) {
        pos++;
        continue;
      }
      if (_current == 0x5D) {
        pos++;
        return JsonArray(items);
      }
      _unexpected("',' or ']'");
    }
  }

  String _parseString() {
    final start = pos;
    pos++; // opening quote
    final buffer = StringBuffer();
    var chunkStart = pos;
    while (true) {
      if (pos >= text.length) {
        throw _ParseError('Unterminated string', start);
      }
      final c = _current;
      if (c == 0x22) {
        buffer.write(text.substring(chunkStart, pos));
        pos++;
        return buffer.toString();
      }
      if (c < 0x20) {
        throw _ParseError('Control character in string', pos);
      }
      if (c == 0x5C) {
        buffer.write(text.substring(chunkStart, pos));
        buffer.write(_parseEscape());
        chunkStart = pos;
        continue;
      }
      pos++;
    }
  }

  String _parseEscape() {
    final start = pos;
    pos++; // backslash
    if (pos >= text.length) throw _ParseError('Unterminated string', start);
    final c = _current;
    pos++;
    switch (c) {
      case 0x22:
        return '"';
      case 0x5C:
        return r'\';
      case 0x2F:
        return '/';
      case 0x62:
        return '\b';
      case 0x66:
        return '\f';
      case 0x6E:
        return '\n';
      case 0x72:
        return '\r';
      case 0x74:
        return '\t';
      case 0x75: // u
        if (pos + 4 > text.length) {
          throw _ParseError('Invalid unicode escape', start);
        }
        final hex = text.substring(pos, pos + 4);
        final code = int.tryParse(hex, radix: 16);
        if (code == null || !RegExp(r'^[0-9a-fA-F]{4}$').hasMatch(hex)) {
          throw _ParseError('Invalid unicode escape', start);
        }
        pos += 4;
        return String.fromCharCode(code);
      default:
        throw _ParseError('Invalid escape character', start);
    }
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  JsonNumber _parseNumber() {
    final start = pos;
    if (_current == 0x2D) pos++;
    if (pos >= text.length || !_isDigit(_current)) {
      throw _ParseError('Invalid number', start);
    }
    if (_current == 0x30) {
      pos++;
      if (pos < text.length && _isDigit(_current)) {
        throw _ParseError('Numbers cannot have leading zeros', start);
      }
    } else {
      while (pos < text.length && _isDigit(_current)) {
        pos++;
      }
    }
    if (pos < text.length && _current == 0x2E) {
      pos++;
      if (pos >= text.length || !_isDigit(_current)) {
        throw _ParseError('Invalid number', start);
      }
      while (pos < text.length && _isDigit(_current)) {
        pos++;
      }
    }
    if (pos < text.length && (_current == 0x65 || _current == 0x45)) {
      pos++;
      if (pos < text.length && (_current == 0x2B || _current == 0x2D)) pos++;
      if (pos >= text.length || !_isDigit(_current)) {
        throw _ParseError('Invalid number', start);
      }
      while (pos < text.length && _isDigit(_current)) {
        pos++;
      }
    }
    return JsonNumber(text.substring(start, pos));
  }
}
