import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/json_document.dart';
import 'package:json_better_editor/document/json_node.dart';
import 'package:json_better_editor/editor/dialogs/save_error_dialog.dart';
import 'package:json_better_editor/editor/document_title.dart';
import 'package:json_better_editor/editor/editor_controller.dart';
import 'package:json_better_editor/editor/editor_screen.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:json_better_editor/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../support/editor_finders.dart';
import '../support/fake_document_files.dart';

// Deliberately not pretty-printed: Phase 1 saves the text as-is.
const original = '{"name":"ตัวอย่าง",  "list":[1,2.50,null,true],"o":{}}';

Future<FakeDocumentFiles> pumpWithOpenFile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final files = FakeDocumentFiles()..disk['/docs/data.json'] = original;
  await tester.pumpWidget(JsonEditorApp(files: files));
  files.nextOpenPick = '/docs/data.json';
  await tester.tap(find.byKey(ToolbarKeys.open));
  await tester.pumpAndSettle();
  return files;
}

Future<void> pressCmdS(WidgetTester tester, {bool shift = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}

String title(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(DocumentTitle.titleKey)).data!;

void main() {
  testWidgets('Cmd+S saves to the current path and matches the document', (
    tester,
  ) async {
    final files = await pumpWithOpenFile(tester);
    files.disk['/docs/data.json'] = 'changed on disk';

    await pressCmdS(tester);

    expect(files.saveDialogCount, 0, reason: 'no dialog for a known path');
    expect(files.disk['/docs/data.json'], original);
    expect(title(tester), 'data.json');
  });

  testWidgets('Cmd+Shift+S asks for a location, saves and updates title', (
    tester,
  ) async {
    final files = await pumpWithOpenFile(tester);
    files.nextSavePick = '/backup/copy';

    await pressCmdS(tester, shift: true);

    expect(files.saveDialogCount, 1);
    expect(files.lastSuggestedName, 'data.json');
    expect(files.disk['/backup/copy.json'], original, reason: 'adds .json');
    expect(files.disk['/docs/data.json'], original, reason: 'original kept');
    expect(title(tester), 'copy.json');

    // Later saves go to the new path.
    files.disk['/backup/copy.json'] = '';
    await pressCmdS(tester);
    expect(files.saveDialogCount, 1);
    expect(files.disk['/backup/copy.json'], original);
  });

  testWidgets('cancelling the save dialog writes nothing', (tester) async {
    final files = await pumpWithOpenFile(tester);
    files.nextSavePick = null;

    await pressCmdS(tester, shift: true);

    expect(files.saveDialogCount, 1);
    expect(files.writeCount, 0);
    expect(title(tester), 'data.json');
  });

  testWidgets('a failed write shows an error dialog and keeps the document', (
    tester,
  ) async {
    final files = await pumpWithOpenFile(tester);
    files.readOnly.add('/docs/data.json');

    await pressCmdS(tester);

    expect(find.byKey(SaveErrorDialogKeys.dialog), findsOneWidget);
    expect(find.text('Can’t save “data.json”'), findsOneWidget);
    expect(
      find.text(
        'The file could not be written. Your document is still open and '
        'unchanged.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(SaveErrorDialogKeys.ok));
    await tester.pumpAndSettle();
    expect(title(tester), 'data.json');
    expect(editorText(tester), original);

    // Save As to a read-only location also fails without switching path.
    files.readOnly.add('/locked/new.json');
    files.nextSavePick = '/locked/new.json';
    await pressCmdS(tester, shift: true);
    expect(find.text('Can’t save “new.json”'), findsOneWidget);
    await tester.tap(find.byKey(SaveErrorDialogKeys.ok));
    await tester.pumpAndSettle();
    expect(title(tester), 'data.json');
  });

  testWidgets('Save with no path falls back to Save As', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final files = FakeDocumentFiles()..nextSavePick = '/new/fresh.json';
    final controller = EditorController(files: files)
      ..setDocument(JsonDocument(text: '{}', root: JsonObject([])));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditorScreen(files: files, controller: controller),
      ),
    );
    expect(title(tester), 'Untitled');

    await pressCmdS(tester);

    expect(files.saveDialogCount, 1);
    expect(files.lastSuggestedName, 'Untitled.json');
    expect(files.disk['/new/fresh.json'], '{}');
    expect(title(tester), 'fresh.json');
  });

  testWidgets('Save with nothing open does nothing', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final files = FakeDocumentFiles();
    await tester.pumpWidget(JsonEditorApp(files: files));

    await pressCmdS(tester);
    await pressCmdS(tester, shift: true);

    expect(files.saveDialogCount, 0);
    expect(files.writeCount, 0);
  });

  test('round trip: open, save to a new path, reopen, same content', () async {
    final files = FakeDocumentFiles()..disk['/a/in.json'] = original;
    final first = EditorController(files: files);
    await first.openPath('/a/in.json');
    files.nextSavePick = '/b/out.json';
    final saved = await first.saveAs(filterLabel: 'JSON', untitledName: 'U');
    expect(saved, isA<SaveSucceeded>());

    final second = EditorController(files: files);
    await second.openPath('/b/out.json');
    expect(second.document!.text, first.document!.text);
    expect(second.document!.root, first.document!.root);
    expect(second.document!.path, '/b/out.json');
  });
}
