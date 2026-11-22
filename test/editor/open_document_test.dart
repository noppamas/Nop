import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/editor/document_title.dart';
import 'package:json_better_editor/editor/text_pane.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:material_ui/material_ui.dart';

import '../support/editor_finders.dart';
import '../support/fake_document_files.dart';

const validText = '{\n  "name": "ตัวอย่าง",\n  "count": 3\n}\n';

Future<FakeDocumentFiles> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final files = FakeDocumentFiles();
  await tester.pumpWidget(JsonEditorApp(files: files));
  return files;
}

String titleText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(DocumentTitle.titleKey)).data!;

void main() {
  testWidgets('toolbar Open shows the dialog filtered to JSON', (tester) async {
    final files = await pumpApp(tester);

    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle();

    expect(files.openDialogCount, 1);
    expect(files.lastOpenFilterLabel, 'JSON');
  });

  testWidgets('Cmd+O shows the open dialog', (tester) async {
    final files = await pumpApp(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(files.openDialogCount, 1);
  });

  testWidgets('opening a valid file shows its text and file name', (
    tester,
  ) async {
    final files = await pumpApp(tester);
    files.disk['/tmp/data/sample.json'] = validText;
    files.nextOpenPick = '/tmp/data/sample.json';

    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle();

    expect(titleText(tester), 'sample.json');
    expect(editorText(tester), validText);
  });

  testWidgets('a long document can be scrolled', (tester) async {
    final files = await pumpApp(tester);
    final long = List.generate(500, (i) => '  "k$i": $i').join(',\n');
    files.disk['/tmp/long.json'] = '{\n$long\n}';
    files.nextOpenPick = '/tmp/long.json';

    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle();

    double maxOffset() => tester
        .stateList<ScrollableState>(
          find.descendant(
            of: find.byType(TextPane),
            matching: find.byType(Scrollable),
          ),
        )
        .map((s) => s.position.pixels)
        .fold(0, (a, b) => a > b ? a : b);
    expect(maxOffset(), 0);
    await tester.drag(find.byType(TextPane), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(maxOffset(), greaterThan(0));
  });

  testWidgets('cancelling the dialog leaves the state unchanged', (
    tester,
  ) async {
    final files = await pumpApp(tester);

    // Nothing open: still Untitled with no text.
    files.nextOpenPick = null;
    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle();
    expect(titleText(tester), 'Untitled');
    expect(find.byType(TextPane), findsNothing);

    // A document open: cancelling keeps it.
    files.disk['/tmp/a.json'] = validText;
    files.nextOpenPick = '/tmp/a.json';
    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle();
    files.nextOpenPick = null;
    await tester.tap(find.byKey(ToolbarKeys.open));
    await tester.pumpAndSettle();

    expect(files.openDialogCount, 3);
    expect(titleText(tester), 'a.json');
    expect(editorText(tester), validText);
  });
}
