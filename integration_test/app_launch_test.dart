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

  test('round trip on the real disk: open, Save As, reopen', () async {
    final dir = await Directory.systemTemp.createTemp('jbe_save');
    addTearDown(() => dir.delete(recursive: true));
    final source = File('${dir.path}/source.json');
    const text = '{"ชื่อ":"สวัสดี",  "n":[1,2.50,null,true]}\n';
    await source.writeAsString(text);
    final files = _ScriptedSaveFiles('${dir.path}/copy');

    final controller = EditorController(files: files);
    await controller.openPath(source.path);
    final saved = await controller.saveAs(
      filterLabel: 'JSON',
      untitledName: 'U',
    );
    expect(saved, isA<SaveSucceeded>());
    expect(controller.document!.fileName, 'copy.json');

    final reopened = EditorController(files: files);
    expect(
      await reopened.openPath('${dir.path}/copy.json'),
      isA<OpenSucceeded>(),
    );
    expect(reopened.document!.text, text);
    expect(await File('${dir.path}/copy.json').readAsString(), text);
  });

  test('a failed real write keeps the document', () async {
    final dir = await Directory.systemTemp.createTemp('jbe_ro');
    addTearDown(() async {
      await Process.run('chmod', ['755', dir.path]);
      await dir.delete(recursive: true);
    });
    final source = File('${dir.path}/doc.json');
    await source.writeAsString('[1]');
    final controller = EditorController(files: const SystemDocumentFiles());
    await controller.openPath(source.path);
    await Process.run('chmod', ['444', source.path]);

    final result = await controller.save(
      filterLabel: 'JSON',
      untitledName: 'U',
    );

    expect(result, isA<SaveFailed>());
    expect(controller.document!.text, '[1]');
    expect(controller.document!.path, source.path);
  });
}

/// Real disk access, with the save dialog answered by a fixed path.
class _ScriptedSaveFiles extends SystemDocumentFiles {
  const _ScriptedSaveFiles(this.savePath);

  final String savePath;

  @override
  Future<String?> pickJsonSaveLocation({
    required String filterLabel,
    required String suggestedName,
  }) async => ensureJsonExtension(savePath);
}
