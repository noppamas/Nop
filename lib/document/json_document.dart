import 'json_node.dart';

/// An open document: its text, the parsed model, and where it lives on disk.
class JsonDocument {
  const JsonDocument({required this.text, required this.root, this.path});

  /// The document text exactly as loaded (Phase 1 shows it as-is).
  final String text;

  /// The parsed model shared by the Text and Node panes.
  final JsonNode root;

  /// Absolute file path, or null for a document never saved.
  final String? path;

  /// File name shown as the document title, or null when unsaved.
  String? get fileName {
    final p = path;
    if (p == null) return null;
    final slash = p.lastIndexOf('/');
    return slash < 0 ? p : p.substring(slash + 1);
  }
}
