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
    required this.kind,
    this.expected,
    this.found,
    required this.offset,
    required this.line,
    required this.column,
  });

  /// What went wrong. The UI turns this into a translated message.
  final JsonErrorKind kind;

  /// What the parser expected, for [JsonErrorKind.unexpectedEnd] and
  /// [JsonErrorKind.unexpectedCharacter].
  final JsonExpected? expected;

  /// The unexpected character, for [JsonErrorKind.unexpectedCharacter].
  final String? found;

  /// UTF-16 offset of the error in the text.
  final int offset;
  final int line;
  final int column;

  /// English description for logs and debugging. User-facing text comes
  /// from the string table instead.
  String get message => switch (kind) {
    JsonErrorKind.emptyDocument => 'The document is empty',
    JsonErrorKind.unexpectedEnd =>
      'Unexpected end of file, expected ${expected?.name}',
    JsonErrorKind.unexpectedCharacter =>
      "Unexpected '$found', expected ${expected?.name}",
    JsonErrorKind.trailingText => 'Unexpected text after the JSON value',
    JsonErrorKind.unterminatedString => 'Unterminated string',
    JsonErrorKind.controlCharacter => 'Control character in string',
    JsonErrorKind.invalidEscape => 'Invalid escape character',
    JsonErrorKind.invalidUnicodeEscape => 'Invalid unicode escape',
    JsonErrorKind.invalidNumber => 'Invalid number',
    JsonErrorKind.leadingZero => 'Numbers cannot have leading zeros',
    JsonErrorKind.tooDeep => 'Nesting is too deep',
  };

  @override
  String toString() => '$message (line $line, column $column)';
}

/// Kinds of JSON syntax error.
enum JsonErrorKind {
  emptyDocument,
  unexpectedEnd,
  unexpectedCharacter,
  trailingText,
  unterminatedString,
  controlCharacter,
  invalidEscape,
  invalidUnicodeEscape,
  invalidNumber,
  leadingZero,
  tooDeep,
}

/// What the parser expected when it met something else.
enum JsonExpected { value, key, colon, commaOrCloseBrace, commaOrCloseBracket }

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
      kind: error.kind,
      expected: error.expected,
      found: error.found,
      offset: error.offset,
      line: line,
      column: error.offset - lineStart + 1,
    );
  }
}

class _ParseError implements Exception {
  _ParseError(this.kind, this.offset, {this.expected, this.found});

  final JsonErrorKind kind;
  final int offset;
  final JsonExpected? expected;
  final String? found;
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
      throw _ParseError(JsonErrorKind.emptyDocument, pos);
    }
    final root = _parseValue();
    _skipWhitespace();
    if (pos < text.length) {
      throw _ParseError(JsonErrorKind.trailingText, pos);
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

  Never _unexpected(JsonExpected expected) {
    if (pos >= text.length) {
      throw _ParseError(JsonErrorKind.unexpectedEnd, pos, expected: expected);
    }
    // Report whole characters, including ones outside the BMP.
    final found = String.fromCharCode(_runeAt(pos));
    throw _ParseError(
      JsonErrorKind.unexpectedCharacter,
      pos,
      expected: expected,
      found: found,
    );
  }

  int _runeAt(int index) {
    final c = text.codeUnitAt(index);
    if (c >= 0xD800 && c <= 0xDBFF && index + 1 < text.length) {
      final d = text.codeUnitAt(index + 1);
      if (d >= 0xDC00 && d <= 0xDFFF) {
        return 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00);
      }
    }
    return c;
  }

  JsonNode _parseValue() {
    if (pos >= text.length) _unexpected(JsonExpected.value);
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
        _unexpected(JsonExpected.value);
    }
  }

  JsonNode _nested(JsonNode Function() parse) {
    if (++_depth > _maxDepth) {
      throw _ParseError(JsonErrorKind.tooDeep, pos);
    }
    final node = parse();
    _depth--;
    return node;
  }

  void _literal(String word) {
    if (!text.startsWith(word, pos)) _unexpected(JsonExpected.value);
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
        _unexpected(JsonExpected.key);
      }
      final key = _parseString();
      _skipWhitespace();
      if (pos >= text.length || _current != 0x3A) {
        _unexpected(JsonExpected.colon);
      }
      pos++;
      _skipWhitespace();
      members.add(JsonMember(key, _parseValue()));
      _skipWhitespace();
      if (pos >= text.length) _unexpected(JsonExpected.commaOrCloseBrace);
      if (_current == 0x2C) {
        pos++;
        continue;
      }
      if (_current == 0x7D) {
        pos++;
        return JsonObject(members);
      }
      _unexpected(JsonExpected.commaOrCloseBrace);
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
      if (pos >= text.length) _unexpected(JsonExpected.commaOrCloseBracket);
      if (_current == 0x2C) {
        pos++;
        continue;
      }
      if (_current == 0x5D) {
        pos++;
        return JsonArray(items);
      }
      _unexpected(JsonExpected.commaOrCloseBracket);
    }
  }

  String _parseString() {
    final start = pos;
    pos++; // opening quote
    final buffer = StringBuffer();
    var chunkStart = pos;
    while (true) {
      if (pos >= text.length) {
        throw _ParseError(JsonErrorKind.unterminatedString, start);
      }
      final c = _current;
      if (c == 0x22) {
        buffer.write(text.substring(chunkStart, pos));
        pos++;
        return buffer.toString();
      }
      if (c < 0x20) {
        throw _ParseError(JsonErrorKind.controlCharacter, pos);
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
    if (pos >= text.length) {
      throw _ParseError(JsonErrorKind.unterminatedString, start);
    }
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
          throw _ParseError(JsonErrorKind.invalidUnicodeEscape, start);
        }
        final hex = text.substring(pos, pos + 4);
        final code = int.tryParse(hex, radix: 16);
        if (code == null || !RegExp(r'^[0-9a-fA-F]{4}$').hasMatch(hex)) {
          throw _ParseError(JsonErrorKind.invalidUnicodeEscape, start);
        }
        pos += 4;
        return String.fromCharCode(code);
      default:
        throw _ParseError(JsonErrorKind.invalidEscape, start);
    }
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  JsonNumber _parseNumber() {
    final start = pos;
    if (_current == 0x2D) pos++;
    if (pos >= text.length || !_isDigit(_current)) {
      throw _ParseError(JsonErrorKind.invalidNumber, start);
    }
    if (_current == 0x30) {
      pos++;
      if (pos < text.length && _isDigit(_current)) {
        throw _ParseError(JsonErrorKind.leadingZero, start);
      }
    } else {
      while (pos < text.length && _isDigit(_current)) {
        pos++;
      }
    }
    if (pos < text.length && _current == 0x2E) {
      pos++;
      if (pos >= text.length || !_isDigit(_current)) {
        throw _ParseError(JsonErrorKind.invalidNumber, start);
      }
      while (pos < text.length && _isDigit(_current)) {
        pos++;
      }
    }
    if (pos < text.length && (_current == 0x65 || _current == 0x45)) {
      pos++;
      if (pos < text.length && (_current == 0x2B || _current == 0x2D)) pos++;
      if (pos >= text.length || !_isDigit(_current)) {
        throw _ParseError(JsonErrorKind.invalidNumber, start);
      }
      while (pos < text.length && _isDigit(_current)) {
        pos++;
      }
    }
    return JsonNumber(text.substring(start, pos));
  }
}
