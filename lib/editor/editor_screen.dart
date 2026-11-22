import 'package:material_ui/material_ui.dart';

import 'document_title.dart';
import 'editor_layout.dart';
import 'toolbar/editor_toolbar.dart';

/// The single-document editor window.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  EditorLayout _layout = EditorLayout.split;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorToolbar(
            layout: _layout,
            onLayoutChanged: (layout) => setState(() => _layout = layout),
          ),
          const DocumentTitle(),
          const Divider(height: 1),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );
  }
}
