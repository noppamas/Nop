import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/editor/text_pane.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:json_better_editor/files/document_files.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

/// Renders the real app on macOS with a sample file open and saves a PNG of
/// the Flutter content (the native window controls are not included).
/// Not part of tool/check.sh. Run:
///   flutter test integration_test/screenshot_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (tester) async {
    final dir = await Directory.systemTemp.createTemp('jbe_shot');
    final sample = File('${dir.path}/sample.json');
    await sample.writeAsString('''{
  "name": "JSON Better Editor",
  "version": 1.0,
  "platforms": ["macOS"],
  "ภาษา": "ไทย และ English",
  "settings": {
    "theme": "light",
    "wordWrap": false,
    "fontSize": 13,
    "lastFile": null
  },
  "tags": [
    {"id": 1, "label": "text"},
    {"id": 2, "label": "node"}
  ]
}
''');
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: JsonEditorApp(files: _PickFiles(sample.path)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Optional: fold the block starting on this 0-based line
    // (--dart-define=SCREENSHOT_FOLD_LINE=5).
    const foldLine = int.fromEnvironment(
      'SCREENSHOT_FOLD_LINE',
      defaultValue: -1,
    );
    if (foldLine >= 0) {
      final chunks = tester
          .widget<DefaultCodeChunkIndicator>(find.byKey(TextPane.foldGutterKey))
          .controller;
      for (var i = 0; i < 50 && chunks.value.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      chunks.collapse(foldLine);
      await tester.pumpAndSettle();
    }

    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('${Directory.systemTemp.path}/jbe_screenshot.png');
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('SCREENSHOT ${out.path}');
    // Keep the window up so a full-window capture (with the native window
    // controls) can be taken with `screencapture -l <window id>`.
    await Future<void>.delayed(const Duration(seconds: 15));
  });
}

class _PickFiles extends SystemDocumentFiles {
  const _PickFiles(this.path);

  final String path;

  @override
  Future<String?> pickJsonToOpen({required String filterLabel}) async => path;
}
