import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../files/document_files.dart';
import '../l10n/generated/app_localizations.dart';
import '../platform/native_window.dart';
import 'document_title.dart';
import 'editor_controller.dart';
import 'editor_layout.dart';
import 'plain_text_view.dart';
import 'toolbar/editor_toolbar.dart';

/// The single-document editor window.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.files = const SystemDocumentFiles()});

  final DocumentFiles files;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller = EditorController(
    files: widget.files,
  );
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final strings = AppLocalizations.of(context);
    await _controller.open(filterLabel: strings.jsonFileTypeLabel);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
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
                  DocumentTitle(fileName: document?.fileName),
                  const Divider(height: 1),
                  Expanded(
                    child: document == null
                        ? const SizedBox.expand()
                        : PlainTextView(text: document.text),
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
