import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/json_node.dart';
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

const original = '{\n  "a": 1,\n  "b": [true, null]\n}';

late FakeDocumentFiles files;
late EditorController controller;

Future<void> pumpWithFile(WidgetTester tester, [String text = original]) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  files = FakeDocumentFiles()..disk['/d/doc.json'] = text;
  controller = EditorController(files: files);
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

/// Focuses the editor and places the caret at [line], [column] (0-based).
Future<void> caretAt(WidgetTester tester, int line, int column) async {
  await tester.tap(find.byKey(TextPane.editorKey));
  await tester.pumpAndSettle();
  codeController(tester).selection = CodeLineSelection.collapsed(
    index: line,
    offset: column,
  );
  await tester.pumpAndSettle();
}

Future<void> select(WidgetTester tester, (int, int) from, (int, int) to) async {
  await tester.tap(find.byKey(TextPane.editorKey));
  await tester.pumpAndSettle();
  codeController(tester).selection = CodeLineSelection(
    baseIndex: from.$1,
    baseOffset: from.$2,
    extentIndex: to.$1,
    extentOffset: to.$2,
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

bool editorHasFocus(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  return focused.findAncestorWidgetOfExactType<CodeEditor>() != null ||
      focused.widget is CodeEditor;
}

final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  testWidgets(
    'opened file shows in an editable pane with line numbers',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);

      expect(editorText(tester), original);
      // The gutter paints one number per line (see the screenshot test for
      // how it looks on macOS).
      expect(
        find.descendant(
          of: find.byKey(TextPane.editorKey),
          matching: find.byType(DefaultCodeLineNumber),
        ),
        findsOneWidget,
      );
      expect(codeController(tester).lineCount, 4);
    },
  );

  testWidgets(
    'typing edits the text and updates the model when valid',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await caretAt(tester, 1, 8); // after `1`

      await typeText(tester, '23');

      expect(editorText(tester), original.replaceFirst('"a": 1', '"a": 123'));
      expect(controller.textIsValid, isTrue);
      final root = controller.document!.root as JsonObject;
      expect(root['a'], const JsonNumber('123'));
    },
  );

  testWidgets(
    'invalid text keeps the last valid model and shows no dialog',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      final before = controller.document!.root;
      await caretAt(tester, 1, 8);

      await typeText(tester, ',,');

      expect(editorText(tester), contains('"a": 1,,,'));
      expect(controller.textIsValid, isFalse);
      expect(controller.document!.root, before);
      expect(find.byType(AlertDialog), findsNothing);

      // Fixing the text updates the model again.
      codeController(tester).text = '{"a": 5}';
      await tester.pumpAndSettle();
      expect(controller.textIsValid, isTrue);
      expect(
        (controller.document!.root as JsonObject)['a'],
        const JsonNumber('5'),
      );
    },
  );

  testWidgets(
    'Tab and Shift+Tab indent and de-indent the current line',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await caretAt(tester, 1, 4);

      await press(tester, LogicalKeyboardKey.tab);
      expect(editorText(tester).split('\n')[1], '    "a": 1,');
      expect(editorHasFocus(tester), isTrue, reason: 'Tab keeps focus');

      await press(tester, LogicalKeyboardKey.tab, shift: true);
      expect(editorText(tester).split('\n')[1], '  "a": 1,');
      await press(tester, LogicalKeyboardKey.tab, shift: true);
      expect(editorText(tester).split('\n')[1], '"a": 1,');
      expect(editorHasFocus(tester), isTrue);
    },
  );

  testWidgets(
    'Tab and Shift+Tab indent and de-indent every selected line',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await select(tester, (1, 3), (2, 5));

      await press(tester, LogicalKeyboardKey.tab);
      var lines = editorText(tester).split('\n');
      expect(lines[0], '{');
      expect(lines[1], '    "a": 1,');
      expect(lines[2], '    "b": [true, null]');
      expect(lines[3], '}');

      await press(tester, LogicalKeyboardKey.tab, shift: true);
      lines = editorText(tester).split('\n');
      expect(lines[1], '  "a": 1,');
      expect(lines[2], '  "b": [true, null]');
    },
  );

  testWidgets(
    'copy, cut and paste behave like a normal text editor',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      String? content;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              content =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return <String, Object?>{'text': content};
            case 'Clipboard.hasStrings':
              return <String, Object?>{'value': content != null};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      // Copy `"a": 1` from line 2.
      await select(tester, (1, 2), (1, 8));
      await press(tester, LogicalKeyboardKey.keyC, meta: true);
      expect(content, '"a": 1');
      expect(editorText(tester), original);

      // Cut `true, ` from line 3.
      await select(tester, (2, 8), (2, 14));
      await press(tester, LogicalKeyboardKey.keyX, meta: true);
      expect(content, 'true, ');
      expect(editorText(tester).split('\n')[2], '  "b": [null]');

      // Paste it back before `null`.
      await caretAt(tester, 2, 8);
      await press(tester, LogicalKeyboardKey.keyV, meta: true);
      expect(editorText(tester), original);
    },
  );

  testWidgets(
    'unsaved edits show in the title row until saved',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      expect(find.byKey(DocumentTitle.editedKey), findsNothing);

      await caretAt(tester, 1, 8);
      await typeText(tester, '0');
      expect(find.byKey(DocumentTitle.editedKey), findsOneWidget);
      expect(find.text('Edited'), findsOneWidget);

      await press(tester, LogicalKeyboardKey.keyS, meta: true);

      expect(files.disk['/d/doc.json'], original.replaceFirst('1,', '10,'));
      expect(find.byKey(DocumentTitle.editedKey), findsNothing);
    },
  );

  testWidgets(
    'typing back to the saved text clears the indicator',
    variant: macOS,
    (tester) async {
      await pumpWithFile(tester);
      await caretAt(tester, 1, 8);
      await typeText(tester, '9');
      expect(controller.isDirty, isTrue);

      codeController(tester).text = original;
      await tester.pumpAndSettle();
      expect(controller.isDirty, isFalse);
      expect(find.byKey(DocumentTitle.editedKey), findsNothing);
    },
  );

  testWidgets('opening another file replaces the editor text', variant: macOS, (
    tester,
  ) async {
    await pumpWithFile(tester);
    await caretAt(tester, 1, 8);
    await typeText(tester, '7');

    files.disk['/d/other.json'] = '[1, 2]';
    await controller.openPath('/d/other.json');
    await tester.pumpAndSettle();

    expect(editorText(tester), '[1, 2]');
    expect(controller.isDirty, isFalse);
  });
}
