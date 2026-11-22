import 'package:flutter/foundation.dart';

import '../document/edit_history.dart';
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
  EditorController({required this.files, EditHistory? history})
    : history = history ?? EditHistory();

  final DocumentFiles files;

  /// One undo/redo history for the document (decision 26).
  final EditHistory history;
  int _textGeneration = 0;

  JsonDocument? _document;
  String? _savedText;
  bool _textIsValid = true;
  int _loadGeneration = 0;

  /// The open document, or null when nothing is open. Its [JsonDocument.root]
  /// is the last valid model: while the text is invalid JSON it keeps the
  /// previous value (decision 8).
  JsonDocument? get document => _document;

  /// Whether the current text is valid JSON.
  bool get textIsValid => _textIsValid;

  /// Whether the text differs from what was last opened or saved.
  bool get isDirty => _document != null && _document!.text != _savedText;

  /// Changes whenever a different document is loaded (open, new). Edits and
  /// saves keep it. Views use it to know when to replace their text.
  int get loadGeneration => _loadGeneration;

  /// Changes when the text was changed from outside the Text pane (undo,
  /// redo; Node edits in Phase 3). The Text pane then reloads the text.
  int get textGeneration => _textGeneration;

  bool get canUndo => _document != null && history.canUndo;
  bool get canRedo => _document != null && history.canRedo;

  /// Undoes the last edit (Cmd+Z).
  void undo() {
    final document = _document;
    if (document == null) return;
    final text = history.undo(document.text);
    if (text != null) _setTextFromOutside(text);
  }

  /// Redoes the last undone edit (Cmd+Shift+Z).
  void redo() {
    final document = _document;
    if (document == null) return;
    final text = history.redo(document.text);
    if (text != null) _setTextFromOutside(text);
  }

  void _setTextFromOutside(String text) {
    _applyText(text);
    _textGeneration++;
    notifyListeners();
  }

  /// Replaces the open document, for example with a new one. The given text
  /// counts as saved.
  void setDocument(JsonDocument? document) {
    _load(document);
    notifyListeners();
  }

  void _load(JsonDocument? document) {
    _document = document;
    _savedText = document?.text;
    _textIsValid = true;
    _loadGeneration++;
    history.clear();
  }

  /// Applies an edit from the Text pane: keeps the text and, when it is
  /// valid JSON, replaces the model.
  void updateText(String text) {
    final document = _document;
    if (document == null || document.text == text) return;
    history.record(document.text, text);
    _applyText(text);
    notifyListeners();
  }

  void _applyText(String text) {
    final document = _document!;
    final parsed = parseJson(text);
    _textIsValid = parsed is JsonParseSuccess;
    _document = JsonDocument(
      text: text,
      root: parsed is JsonParseSuccess ? parsed.root : document.root,
      path: document.path,
    );
  }

  /// Saves to the document's current path, or asks for one (Save As) if it
  /// has never been saved. Writes the current text as-is.
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
    return _write(_document ?? document, path);
  }

  Future<SaveResult> _write(JsonDocument document, String path) async {
    final generation = _loadGeneration;
    try {
      await files.writeText(path, document.text);
    } on Object catch (error) {
      return SaveFailed(path, error);
    }
    // Only update state if the same document is still loaded. Edits made
    // while writing stay unsaved.
    final current = _document;
    if (generation == _loadGeneration && current != null) {
      _savedText = document.text;
      if (current.path != path) {
        _document = JsonDocument(
          text: current.text,
          root: current.root,
          path: path,
        );
      }
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
        _load(document);
        notifyListeners();
        return OpenSucceeded(document);
    }
  }
}
