import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Types [text] into the focused re_editor field the way the macOS text
/// input plugin does: as a delta inserted at the current selection.
///
/// re_editor uses the delta text input model, which
/// `WidgetTester.enterText` does not support.
Future<void> typeText(WidgetTester tester, String text) async {
  final setClient = tester.testTextInput.log.lastWhere(
    (call) => call.method == 'TextInput.setClient',
    orElse: () => throw StateError('No text input client; focus the editor'),
  );
  final clientId = (setClient.arguments as List<Object?>)[0]! as int;
  final state = tester.testTextInput.editingState!;
  final oldText = state['text']! as String;
  final start = state['selectionBase']! as int;
  final end = state['selectionExtent']! as int;
  final from = start < end ? start : end;
  final to = start < end ? end : start;
  final caret = from + text.length;
  final delta = <String, Object>{
    'oldText': oldText,
    'deltaText': text,
    'deltaStart': from,
    'deltaEnd': to,
    'selectionBase': caret,
    'selectionExtent': caret,
    'selectionAffinity': 'TextAffinity.downstream',
    'selectionIsDirectional': false,
    'composingBase': -1,
    'composingExtent': -1,
  };
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.textInput.name,
    SystemChannels.textInput.codec.encodeMethodCall(
      MethodCall('TextInputClient.updateEditingStateWithDeltas', [
        clientId,
        {
          'deltas': [delta],
        },
      ]),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}
