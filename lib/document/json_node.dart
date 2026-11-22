/// Shared JSON document model used by the Text and Node panes (§1.2).
///
/// Covers the six JSON types: Object, Array, String, Number, Boolean and
/// Null. Objects keep their keys in document order.
sealed class JsonNode {
  const JsonNode();

  JsonType get type;
}

/// The six JSON data types.
enum JsonType { object, array, string, number, boolean, nullValue }

/// One `"key": value` member of a [JsonObject].
class JsonMember {
  const JsonMember(this.key, this.value);

  final String key;
  final JsonNode value;

  @override
  bool operator ==(Object other) =>
      other is JsonMember && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => '$key: $value';
}

class JsonObject extends JsonNode {
  JsonObject(List<JsonMember> members) : members = List.unmodifiable(members);

  /// Members in document order.
  final List<JsonMember> members;

  @override
  JsonType get type => JsonType.object;

  /// Keys in document order.
  Iterable<String> get keys => members.map((m) => m.key);

  /// The value of the last member named [key] (as JSON.parse does), or null.
  JsonNode? operator [](String key) {
    for (final member in members.reversed) {
      if (member.key == key) return member.value;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is JsonObject && _listEquals(other.members, members);

  @override
  int get hashCode => Object.hashAll(members);

  @override
  String toString() => '{${members.join(', ')}}';
}

class JsonArray extends JsonNode {
  JsonArray(List<JsonNode> items) : items = List.unmodifiable(items);

  final List<JsonNode> items;

  @override
  JsonType get type => JsonType.array;

  @override
  bool operator ==(Object other) =>
      other is JsonArray && _listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => '[${items.join(', ')}]';
}

class JsonString extends JsonNode {
  const JsonString(this.value);

  final String value;

  @override
  JsonType get type => JsonType.string;

  @override
  bool operator ==(Object other) => other is JsonString && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '"$value"';
}

/// A JSON number. Keeps the source text so formatting such as `1.0` or
/// `1e3` and large integers survive unchanged.
class JsonNumber extends JsonNode {
  const JsonNumber(this.source);

  /// The number exactly as written in the document.
  final String source;

  /// The numeric value (may lose precision for very large numbers).
  num get value => num.parse(source);

  @override
  JsonType get type => JsonType.number;

  @override
  bool operator ==(Object other) =>
      other is JsonNumber && other.source == source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => source;
}

class JsonBool extends JsonNode {
  const JsonBool(this.value);

  final bool value;

  @override
  JsonType get type => JsonType.boolean;

  @override
  bool operator ==(Object other) => other is JsonBool && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}

class JsonNull extends JsonNode {
  const JsonNull();

  @override
  JsonType get type => JsonType.nullValue;

  @override
  bool operator ==(Object other) => other is JsonNull;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'null';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
