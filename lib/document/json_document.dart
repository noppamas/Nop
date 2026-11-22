import 'json_node.dart';

/// An open document: its text, the parsed model, and where it lives on disk.
class JsonDocument {
  const JsonDocument({required this.text, required this.root, this.path});

  /// The current document text.
  final String text;

  /// The parsed model shared by the Text and Node panes: the last valid
  /// parse of [text].
  final JsonNode root;

  /// Absolute file path, or null for a document never saved.
  final String? path;

  /// File name shown as the document title, or null when unsaved.
  String? get fileName {
    final p = path;
    return p == null ? null : fileNameOf(p);
  }
}

/// The last component of a POSIX [path].
String fileNameOf(String path) {
  final slash = path.lastIndexOf('/');
  return slash < 0 ? path : path.substring(slash + 1);
}
