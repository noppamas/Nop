import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/editor/text_pane.dart';
import 'package:re_editor/re_editor.dart';

/// The Text pane's editing controller.
CodeLineEditingController codeController(WidgetTester tester) =>
    tester.widget<CodeEditor>(find.byKey(TextPane.editorKey)).controller!;

/// The text shown in the Text pane.
String editorText(WidgetTester tester) => codeController(tester).text;
