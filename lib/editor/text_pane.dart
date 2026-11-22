import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_controller.dart';

/// The Text pane: an editable code editor for the document text (§1.1,
/// §1.4), built on `re_editor` (decision 32).
///
/// Edits go to [EditorController.updateText]; when a different document is
/// loaded the pane replaces its text and starts a fresh history.
class TextPane extends StatefulWidget {
  const TextPane({super.key, required this.controller});

  static const editorKey = ValueKey('textPane.editor');

  /// Indent unit for Tab / Shift+Tab (matches the save format, decision 33).
  static const indentSize = 2;

  final EditorController controller;

  @override
  State<TextPane> createState() => _TextPaneState();
}

class _TextPaneState extends State<TextPane> {
  final CodeLineEditingController _code = CodeLineEditingController(
    options: const CodeLineOptions(indentSize: TextPane.indentSize),
  );
  int _loadedGeneration = -1;

  @override
  void initState() {
    super.initState();
    _syncFromDocument();
    widget.controller.addListener(_syncFromDocument);
  }

  @override
  void didUpdateWidget(TextPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromDocument);
      widget.controller.addListener(_syncFromDocument);
      _loadedGeneration = -1;
      _syncFromDocument();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromDocument);
    _code.dispose();
    super.dispose();
  }

  /// Loads the document text when a different document was opened.
  void _syncFromDocument() {
    final controller = widget.controller;
    if (controller.loadGeneration == _loadedGeneration) return;
    _loadedGeneration = controller.loadGeneration;
    _code.text = controller.document?.text ?? '';
    _code.clearHistory();
  }

  /// Tab: indents every selected line, or the caret's line when nothing is
  /// selected (§1.4), keeping the caret on the same character.
  void _indent() {
    final selection = _code.selection;
    if (!selection.isCollapsed) {
      _code.applyIndent();
      return;
    }
    const unit = TextPane.indentSize;
    _code.runRevocableOp(() {
      _code.selection = CodeLineSelection.collapsed(
        index: selection.extentIndex,
        offset: 0,
      );
      _code.replaceSelection(' ' * unit);
      _code.selection = CodeLineSelection.collapsed(
        index: selection.extentIndex,
        offset: selection.extentOffset + unit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mono = (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Monaco', 'Courier'],
      fontSize: 13,
      height: 1.4,
    );
    return CodeEditor(
      key: TextPane.editorKey,
      controller: _code,
      autofocus: true,
      wordWrap: false,
      onChanged: (_) => widget.controller.updateText(_code.text),
      shortcutsActivatorsBuilder: const _EditorShortcuts(),
      shortcutOverrideActions: {
        CodeShortcutIndentIntent: CallbackAction<CodeShortcutIndentIntent>(
          onInvoke: (_) {
            _indent();
            return null;
          },
        ),
      },
      padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8),
      style: CodeEditorStyle(
        fontFamily: mono.fontFamily,
        fontFamilyFallback: mono.fontFamilyFallback,
        fontSize: mono.fontSize,
        fontHeight: mono.height,
        textColor: colors.onSurface,
        backgroundColor: colors.surface,
        cursorColor: colors.primary,
        selectionColor: colors.primary.withValues(alpha: 0.25),
        cursorLineColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
            return DefaultCodeLineNumber(
              controller: editingController,
              notifier: notifier,
              textStyle: mono.copyWith(color: colors.outline),
              focusedTextStyle: mono.copyWith(color: colors.onSurfaceVariant),
            );
          },
      leadingDivider: Container(width: 1, color: colors.outlineVariant),
    );
  }
}

/// re_editor's default shortcuts, minus the ones the app handles itself
/// (Cmd+S is Save in the editor screen).
class _EditorShortcuts extends CodeShortcutsActivatorsBuilder {
  const _EditorShortcuts();

  static const _appOwned = {CodeShortcutType.save};

  @override
  List<ShortcutActivator>? build(CodeShortcutType type) {
    if (_appOwned.contains(type)) return null;
    return const DefaultCodeShortcutsActivatorsBuilder().build(type);
  }
}
