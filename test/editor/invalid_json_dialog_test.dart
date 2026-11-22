import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/json_parser.dart';
import 'package:json_better_editor/editor/dialogs/open_error_dialog.dart';
import 'package:json_better_editor/editor/document_title.dart';
import 'package:json_better_editor/editor/editor_controller.dart';
import 'package:json_better_editor/editor/text_pane.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:json_better_editor/l10n/generated/app_localizations_en.dart';
import 'package:material_ui/material_ui.dart';

import '../support/editor_finders.dart';
import '../support/fake_document_files.dart';

const validText = '{"ok": true}';

Future<FakeDocumentFiles> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final files = FakeDocumentFiles();
  await tester.pumpWidget(JsonEditorApp(files: files));
  return files;
}

Future<void> openPick(
  WidgetTester tester,
  FakeDocumentFiles files,
  String path,
) async {
  files.nextOpenPick = path;
  await tester.tap(find.byKey(ToolbarKeys.open));
  await tester.pumpAndSettle();
}

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  testWidgets('invalid file shows line and column and is not opened', (
    tester,
  ) async {
    final files = await pumpApp(tester);
    files.disk['/tmp/broken.json'] = '{\n  "a": 1\n  "b": 2\n}';

    await openPick(tester, files, '/tmp/broken.json');

    expect(find.byKey(OpenErrorDialogKeys.dialog), findsOneWidget);
    expect(find.text('Can’t open “broken.json”'), findsOneWidget);
    expect(
      find.text('This file is not valid JSON, so it was not opened.'),
      findsOneWidget,
    );
    expect(textOf(tester, OpenErrorDialogKeys.position), 'Line 3, column 3');
    expect(
      textOf(tester, OpenErrorDialogKeys.reason),
      'Found “"” where “,” or “}” was expected.',
    );

    await tester.tap(find.byKey(OpenErrorDialogKeys.ok));
    await tester.pumpAndSettle();
    expect(find.byKey(OpenErrorDialogKeys.dialog), findsNothing);
    expect(textOf(tester, DocumentTitle.titleKey), 'Untitled');
    expect(find.byType(TextPane), findsNothing);
  });

  testWidgets('empty file shows the dialog at line 1, column 1', (
    tester,
  ) async {
    final files = await pumpApp(tester);
    files.disk['/tmp/empty.json'] = '';

    await openPick(tester, files, '/tmp/empty.json');

    expect(find.text('Can’t open “empty.json”'), findsOneWidget);
    expect(textOf(tester, OpenErrorDialogKeys.position), 'Line 1, column 1');
    expect(textOf(tester, OpenErrorDialogKeys.reason), 'The file is empty.');
  });

  testWidgets('the open document stays as it was', (tester) async {
    final files = await pumpApp(tester);
    files.disk['/tmp/good.json'] = validText;
    files.disk['/tmp/bad.json'] = '[1, 2,';

    await openPick(tester, files, '/tmp/good.json');
    await openPick(tester, files, '/tmp/bad.json');

    expect(
      textOf(tester, OpenErrorDialogKeys.reason),
      'The file ends where a value was expected.',
    );
    await tester.tap(find.byKey(OpenErrorDialogKeys.ok));
    await tester.pumpAndSettle();

    expect(textOf(tester, DocumentTitle.titleKey), 'good.json');
    expect(editorText(tester), validText);
  });

  testWidgets('a file that cannot be read shows an error dialog', (
    tester,
  ) async {
    final files = await pumpApp(tester);

    await openPick(tester, files, '/tmp/missing.json');

    expect(find.text('Can’t open “missing.json”'), findsOneWidget);
    expect(
      textOf(tester, OpenErrorDialogKeys.reason),
      'The file could not be read.',
    );
    expect(textOf(tester, DocumentTitle.titleKey), 'Untitled');
  });

  test('controller does not load invalid or empty files', () async {
    final files = FakeDocumentFiles()
      ..disk['/a.json'] = validText
      ..disk['/empty.json'] = ''
      ..disk['/bad.json'] = '{"x": }';
    final controller = EditorController(files: files);

    await controller.openPath('/a.json');
    final before = controller.document;

    final empty = await controller.openPath('/empty.json');
    expect(empty, isA<OpenInvalidJson>());
    expect((empty as OpenInvalidJson).error.kind, JsonErrorKind.emptyDocument);
    final bad = await controller.openPath('/bad.json');
    expect((bad as OpenInvalidJson).error.line, 1);
    expect(bad.error.column, 7);
    expect(controller.document, same(before));
  });

  test('every error kind has an English reason from the string table', () {
    final strings = AppLocalizationsEn();
    for (final kind in JsonErrorKind.values) {
      for (final expected in [null, ...JsonExpected.values]) {
        final reason = jsonErrorReason(
          strings,
          JsonParseFailure(
            kind: kind,
            expected: expected,
            found: 'x',
            offset: 0,
            line: 1,
            column: 1,
          ),
        );
        expect(reason, isNotEmpty);
        expect(reason, isNot(contains('{')), reason: '$kind $expected');
      }
    }
  });
}
