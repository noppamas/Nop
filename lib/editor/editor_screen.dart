import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../files/document_files.dart';
import '../l10n/generated/app_localizations.dart';
import '../platform/native_window.dart';
import '../document/json_document.dart';
import 'dialogs/open_error_dialog.dart';
import 'dialogs/save_error_dialog.dart';
import 'document_title.dart';
import 'editor_controller.dart';
import 'editor_layout.dart';
import 'text_pane.dart';
import 'toolbar/editor_toolbar.dart';

/// The single-document editor window.
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    this.files = const SystemDocumentFiles(),
    this.controller,
  });

  final DocumentFiles files;

  /// Optional controller supplied by the caller (tests); otherwise the
  /// screen creates and owns one.
  final EditorController? controller;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller =
      widget.controller ?? EditorController(files: widget.files);
  EditorLayout _layout = EditorLayout.split;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateWindowTitle);
  }

  /// Keeps the native window title (Window menu, Mission Control) in step
  /// with the document title.
  void _updateWindowTitle() {
    final strings = AppLocalizations.of(context);
    final name = _controller.document?.fileName;
    unawaited(NativeWindow.setTitle(name ?? strings.appTitle));
  }

  @override
  void dispose() {
    _controller.removeListener(_updateWindowTitle);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final strings = AppLocalizations.of(context);
    final result = await _controller.open(
      filterLabel: strings.jsonFileTypeLabel,
    );
    if (!mounted) return;
    switch (result) {
      case OpenInvalidJson(:final path, :final error):
        await showInvalidJsonDialog(
          context,
          fileName: fileNameOf(path),
          error: error,
        );
      case OpenReadFailed(:final path):
        await showReadFailedDialog(context, fileName: fileNameOf(path));
      case OpenCancelled() || OpenSucceeded():
        break;
    }
  }

  Future<void> _save({required bool saveAs}) async {
    final strings = AppLocalizations.of(context);
    final result = saveAs
        ? await _controller.saveAs(
            filterLabel: strings.jsonFileTypeLabel,
            untitledName: strings.untitledDocument,
          )
        : await _controller.save(
            filterLabel: strings.jsonFileTypeLabel,
            untitledName: strings.untitledDocument,
          );
    if (!mounted) return;
    if (result case SaveFailed(:final path)) {
      await showSaveFailedDialog(context, fileName: fileNameOf(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            unawaited(_save(saveAs: false)),
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          meta: true,
          shift: true,
        ): () =>
            unawaited(_save(saveAs: true)),
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
            unawaited(_open()),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final document = _controller.document;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EditorToolbar(
                    layout: _layout,
                    onLayoutChanged: (layout) =>
                        setState(() => _layout = layout),
                    onOpen: () => unawaited(_open()),
                  ),
                  DocumentTitle(
                    fileName: document?.fileName,
                    edited: _controller.isDirty,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: document == null
                        ? const SizedBox.expand()
                        : TextPane(controller: _controller),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
