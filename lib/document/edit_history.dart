/// Undo/redo history for the document text (§3.5).
///
/// It stores text snapshots and knows nothing about widgets, so the Text
/// pane today and the Node pane in Phase 3 can share one history
/// (decision 26): every edit, from either pane, is recorded as the text
/// before and after it.
class EditHistory {
  EditHistory({DateTime Function()? clock, this.groupWindow = _defaultWindow})
    : _clock = clock ?? DateTime.now;

  static const _defaultWindow = Duration(seconds: 1);

  /// Typing edits closer together than this undo as one step.
  final Duration groupWindow;

  final DateTime Function() _clock;
  final List<String> _undo = [];
  final List<String> _redo = [];
  EditKind? _lastKind;
  DateTime? _lastTime;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Records an edit that changed the text from [before] to [after].
  /// Consecutive [EditKind.typing] (or [EditKind.deleting]) edits within
  /// [groupWindow] merge into one undo step.
  void record(String before, String after) {
    if (before == after) return;
    final kind = classifyEdit(before, after);
    final now = _clock();
    final merge =
        kind != EditKind.other &&
        kind == _lastKind &&
        _lastTime != null &&
        now.difference(_lastTime!) <= groupWindow &&
        _undo.isNotEmpty;
    if (!merge) _undo.add(before);
    _redo.clear();
    _lastKind = kind;
    _lastTime = now;
  }

  /// Returns the text before the last edit, or null if there is none.
  String? undo(String current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    _breakGroup();
    return _undo.removeLast();
  }

  /// Returns the text after the last undone edit, or null if there is none.
  String? redo(String current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    _breakGroup();
    return _redo.removeLast();
  }

  /// Forgets everything (for example when another file is opened).
  void clear() {
    _undo.clear();
    _redo.clear();
    _breakGroup();
  }

  void _breakGroup() {
    _lastKind = null;
    _lastTime = null;
  }
}

/// How an edit changed the text, for grouping undo steps.
enum EditKind {
  /// One character typed (not a line break).
  typing,

  /// One character removed (backspace or delete).
  deleting,

  /// Anything else: paste, cut, indent, new line, replace, ...
  other,
}

/// Classifies the change from [before] to [after].
EditKind classifyEdit(String before, String after) {
  var prefix = 0;
  final minLength = before.length < after.length ? before.length : after.length;
  while (prefix < minLength &&
      before.codeUnitAt(prefix) == after.codeUnitAt(prefix)) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < minLength - prefix &&
      before.codeUnitAt(before.length - 1 - suffix) ==
          after.codeUnitAt(after.length - 1 - suffix)) {
    suffix++;
  }
  final removed = before.length - prefix - suffix;
  final inserted = after.substring(prefix, after.length - suffix);
  if (removed == 0 && inserted.runes.length == 1 && inserted != '\n') {
    return EditKind.typing;
  }
  if (inserted.isEmpty && removed >= 1 && removed <= 2) {
    final gone = before.substring(prefix, prefix + removed);
    if (gone.runes.length == 1 && gone != '\n') return EditKind.deleting;
  }
  return EditKind.other;
}
