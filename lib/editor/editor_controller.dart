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

/// Outcome of [EditorController.save] and [EditorController.saveAs].
sealed class SaveResult {
  const SaveResult();
}

/// Nothing is open, so there is nothing to save.
class SaveNoDocument extends SaveResult {
  const SaveNoDocument();
}

/// The user cancelled the save dialog; nothing was written.
class SaveCancelled extends SaveResult {
  const SaveCancelled();
}

/// The document was written to [path].
class SaveSucceeded extends SaveResult {
  const SaveSucceeded(this.path);

  final String path;
}

/// Writing to [path] failed; the document is unchanged and still open.
class SaveFailed extends SaveResult {
  const SaveFailed(this.path, this.error);

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

  /// Replaces the open document, for example with a new one.
  void setDocument(JsonDocument? document) {
    _document = document;
    notifyListeners();
  }

  /// Saves to the document's current path, or asks for one (Save As) if it
  /// has never been saved. Writes the text as-is: pretty-printing on save is
  /// Phase 2 (decision 28).
  Future<SaveResult> save({
    required String filterLabel,
    required String untitledName,
  }) async {
    final document = _document;
    if (document == null) return const SaveNoDocument();
    final path = document.path;
    if (path == null) {
      return saveAs(filterLabel: filterLabel, untitledName: untitledName);
    }
    return _write(document, path);
  }

  /// Asks for a location, saves there and makes it the document's path.
  Future<SaveResult> saveAs({
    required String filterLabel,
    required String untitledName,
  }) async {
    final document = _document;
    if (document == null) return const SaveNoDocument();
    final path = await files.pickJsonSaveLocation(
      filterLabel: filterLabel,
      suggestedName: document.fileName ?? '$untitledName.json',
    );
    if (path == null) return const SaveCancelled();
    return _write(document, path);
  }

  Future<SaveResult> _write(JsonDocument document, String path) async {
    try {
      await files.writeText(path, document.text);
    } on Object catch (error) {
      return SaveFailed(path, error);
    }
    // Only switch to the new path once the write succeeded, and only if the
    // document was not replaced in the meantime.
    if (identical(_document, document) && document.path != path) {
      _document = JsonDocument(
        text: document.text,
        root: document.root,
        path: path,
      );
      notifyListeners();
    }
    return SaveSucceeded(path);
  }

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
