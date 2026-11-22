import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/editor/editor_controller.dart';
import 'package:json_better_editor/editor/editor_screen.dart';
import 'package:json_better_editor/files/document_files.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:json_better_editor/main.dart' as app;
import 'package:json_better_editor/platform/native_window.dart';

/// Launch smoke test: starts the real app on macOS.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows the main window', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);
    expect(await NativeWindow.getTitle(), 'JSON Better Editor');

    // The toolbar shares the title-bar row with the native window controls
    // without overlapping them.
    final controls = await NativeWindow.windowControlsFrame();
    expect(controls, isNotNull);
    final firstButton = tester.getRect(find.byKey(ToolbarKeys.newDocument));
    // ignore: avoid_print
    print('window controls: $controls, first toolbar button: $firstButton');
    expect(controls!.overlaps(firstButton), isFalse);
    expect(firstButton.left, greaterThan(controls.right));
    // Same row: vertical centers within a few points of each other.
    expect((controls.center.dy - firstButton.center.dy).abs(), lessThan(6));
  });

  test(
    'opens a real UTF-8 file from disk with the system file access',
    () async {
      final dir = await Directory.systemTemp.createTemp('jbe_open');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/ไทย sample.json');
      const text = '{"ชื่อ": "สวัสดี", "n": [1, 2.5, null, true]}';
      await file.writeAsString(text);

      final controller = EditorController(files: const SystemDocumentFiles());
      final result = await controller.openPath(file.path);

      expect(result, isA<OpenSucceeded>());
      expect(controller.document!.text, text);
      expect(controller.document!.fileName, 'ไทย sample.json');
    },
  );
}
