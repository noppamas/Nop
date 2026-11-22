import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/edit_history.dart';
import 'package:json_better_editor/editor/document_title.dart';
import 'package:json_better_editor/editor/editor_controller.dart';
import 'package:json_better_editor/editor/editor_screen.dart';
import 'package:json_better_editor/editor/text_pane.dart';
import 'package:json_better_editor/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../support/editor_finders.dart';
import '../support/editor_typing.dart';
import '../support/fake_document_files.dart';

const original = '{\n  "a": 1\n}';

late FakeDocumentFiles files;
late EditorController controller;
var clock = DateTime(2026);

final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

Future<void> pumpWithFile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  files = FakeDocumentFiles()..disk['/d/doc.json'] = original;
  controller = EditorController(
    files: files,
    history: EditHistory(clock: () => clock),
  );
  addTearDown(controller.dispose);
  await controller.openPath('/d/doc.json');
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: EditorScreen(files: files, controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> caretAt(WidgetTester tester, int line, int column) async {
  await tester.tap(find.byKey(TextPane.editorKey));
  await tester.pumpAndSettle();
  codeController(tester).selection = CodeLineSelection.collapsed(
    index: line,
    offset: column,
  );
  await tester.pumpAndSettle();
}

Future<void> press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool meta = false,
  bool shift = false,
}) async {
  if (meta) await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  if (meta) await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}

Future<void> undo(WidgetTester tester) =>
    press(tester, LogicalKeyboardKey.keyZ, meta: true);
Future<void> redo(WidgetTester tester) =>
    press(tester, LogicalKeyboardKey.keyZ, meta: true, shift: true);

/// Types each character as its own edit at the caret, [gapMs] apart.
///
/// The first goes through the platform text input like a key press; the
/// rest go straight to the editor (the test text input does not track
/// re_editor's per-line editing state between deltas).
Future<void> typeSlowly(WidgetTester tester, String text, int gapMs) async {
  var first = true;
  for (final char in text.split('')) {
    clock = clock.add(Duration(milliseconds: gapMs));
    if (first) {
      await typeText(tester, char);
      first = false;
    } else {
      codeController(tester).replaceSelection(char);
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  testWidgets(
    'Cmd+Z undoes and Cmd+Shift+Z redoes, repeatedly',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await caretAt(tester, 1, 8);
      await typeSlowly(tester, '2', 0);
      clock = clock.add(const Duration(seconds: 5));
      await press(tester, LogicalKeyboardKey.tab); // indent line 2
      final indented = editorText(tester);
      expect(indented, '{\n    "a": 12\n}');

      await undo(tester);
      expect(editorText(tester), '{\n  "a": 12\n}');
      expect(controller.document!.text, '{\n  "a": 12\n}');
      await undo(tester);
      expect(editorText(tester), original);
      await undo(tester); // nothing left
      expect(editorText(tester), original);

      await redo(tester);
      expect(editorText(tester), '{\n  "a": 12\n}');
      await redo(tester);
      expect(editorText(tester), indented);
    },
  );

  testWidgets('paste and de-indent undo as one step each', variant: macOS, (
    tester,
  ) async {
    await pumpWithFile(tester);
    const clip = '"x"';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => switch (call.method) {
        'Clipboard.getData' => <String, Object?>{'text': clip},
        'Clipboard.hasStrings' => <String, Object?>{'value': true},
        _ => null,
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await caretAt(tester, 1, 7); // before `1`
    await press(tester, LogicalKeyboardKey.keyV, meta: true);
    expect(editorText(tester), '{\n  "a": "x"1\n}');
    await press(tester, LogicalKeyboardKey.tab, shift: true);
    expect(editorText(tester), '{\n"a": "x"1\n}');

    await undo(tester);
    expect(editorText(tester), '{\n  "a": "x"1\n}');
    await undo(tester);
    expect(editorText(tester), original);
  });

  testWidgets('a run of typing undoes as one step', variant: macOS, (
    tester,
  ) async {
    await pumpWithFile(tester);
    await caretAt(tester, 1, 8);

    await typeSlowly(tester, '234', 100);
    expect(editorText(tester), '{\n  "a": 1234\n}');
    clock = clock.add(const Duration(seconds: 3));
    await typeSlowly(tester, '5', 100);

    await undo(tester);
    expect(editorText(tester), '{\n  "a": 1234\n}');
    await undo(tester);
    expect(editorText(tester), original);
  });

  testWidgets('a new edit after undo clears the redo steps', variant: macOS, (
    tester,
  ) async {
    await pumpWithFile(tester);
    await caretAt(tester, 1, 8);
    await typeSlowly(tester, '2', 0);
    await undo(tester);
    expect(controller.canRedo, isTrue);

    await caretAt(tester, 1, 8);
    await typeSlowly(tester, '9', 0);
    expect(controller.canRedo, isFalse);
    await redo(tester);
    expect(editorText(tester), '{\n  "a": 19\n}');
  });

  testWidgets(
    'undo back to the saved text clears the Edited mark',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await caretAt(tester, 1, 8);
      await typeSlowly(tester, '7', 0);
      expect(find.byKey(DocumentTitle.editedKey), findsOneWidget);

      await undo(tester);
      expect(find.byKey(DocumentTitle.editedKey), findsNothing);
      expect(controller.isDirty, isFalse);
    },
  );

  testWidgets('opening another file clears the history', variant: macOS, (
    tester,
  ) async {
    await pumpWithFile(tester);
    await caretAt(tester, 1, 8);
    await typeSlowly(tester, '7', 0);
    expect(controller.canUndo, isTrue);

    files.disk['/d/b.json'] = '[]';
    await controller.openPath('/d/b.json');
    await tester.pumpAndSettle();

    expect(controller.canUndo, isFalse);
    await undo(tester);
    expect(editorText(tester), '[]');
  });

  testWidgets(
    'the macOS Edit menu Undo/Redo reach the same history',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await caretAt(tester, 1, 8);
      await typeSlowly(tester, '5', 0);

      // What the macOS Undo menu item sends through Flutter's UndoManager.
      Future<void> platformUndo(String direction) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.undoManager.name,
          SystemChannels.undoManager.codec.encodeMethodCall(
            MethodCall('UndoManagerClient.handleUndo', [direction]),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      await platformUndo('undo');
      expect(editorText(tester), original);
      await platformUndo('redo');
      expect(editorText(tester), '{\n  "a": 15\n}');
    },
  );

  test('the history does not depend on the text widget', () {
    // EditorController.history is a plain EditHistory: Node mode can record
    // edits into it in Phase 3 without the Text pane.
    final c = EditorController(files: FakeDocumentFiles());
    expect(c.history, isA<EditHistory>());
  });
}
