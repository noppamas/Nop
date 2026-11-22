import 'package:flutter/foundation.dart';

import '../document/json_document.dart';
import '../document/json_parser.dart';
import '../files/document_files.dart';

/// Outcome of [EditorController.open].
sealed class OpenResult {
  const OpenResult();
}

/// The user cancelled the dialog; nothing changed.
class OpenCancelled extends OpenResult {
  const OpenCancelled();
}

/// The file was loaded and is now the current document.
class OpenSucceeded extends OpenResult {
  const OpenSucceeded(this.document);

  final JsonDocument document;
}

/// The file is not valid JSON; the current document is unchanged.
class OpenInvalidJson extends OpenResult {
  const OpenInvalidJson(this.path, this.error);

  final String path;
  final JsonParseFailure error;
}

/// The file could not be read; the current document is unchanged.
class OpenReadFailed extends OpenResult {
  const OpenReadFailed(this.path, this.error);

  final String path;
  final Object error;
}

/// Holds the open document and runs file commands.
class EditorController extends ChangeNotifier {
  EditorController({required this.files});

  final DocumentFiles files;

  JsonDocument? _document;

  /// The open document, or null when nothing is open.
  JsonDocument? get document => _document;

  /// Asks for a `.json` file and loads it if it is valid JSON.
  Future<OpenResult> open({required String filterLabel}) async {
    final path = await files.pickJsonToOpen(filterLabel: filterLabel);
    if (path == null) return const OpenCancelled();
    return openPath(path);
  }

  /// Loads [path] if it is valid JSON. Otherwise nothing changes.
  Future<OpenResult> openPath(String path) async {
    final String text;
    try {
      text = await files.readText(path);
    } on Object catch (error) {
      return OpenReadFailed(path, error);
    }
    switch (parseJson(text)) {
      case final JsonParseFailure failure:
        return OpenInvalidJson(path, failure);
      case JsonParseSuccess(:final root):
        final document = JsonDocument(text: text, root: root, path: path);
        _document = document;
        notifyListeners();
        return OpenSucceeded(document);
    }
  }
}
