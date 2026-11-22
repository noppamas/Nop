import 'package:material_ui/material_ui.dart';

import '../../document/json_parser.dart';
import '../../l10n/generated/app_localizations.dart';

/// Keys for the open-error dialog (used by tests).
abstract final class OpenErrorDialogKeys {
  static const dialog = ValueKey('openError.dialog');
  static const position = ValueKey('openError.position');
  static const reason = ValueKey('openError.reason');
  static const ok = ValueKey('openError.ok');
}

/// Tells the user that [fileName] is not valid JSON and was not opened,
/// with the error's line and column (§1.2, decision 8).
Future<void> showInvalidJsonDialog(
  BuildContext context, {
  required String fileName,
  required JsonParseFailure error,
}) {
  final strings = AppLocalizations.of(context);
  return _show(
    context,
    title: strings.openErrorTitle(fileName),
    lines: [
      Text(strings.invalidJsonMessage),
      const SizedBox(height: 12),
      Text(
        strings.invalidJsonPosition(error.line, error.column),
        key: OpenErrorDialogKeys.position,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      Text(jsonErrorReason(strings, error), key: OpenErrorDialogKeys.reason),
    ],
  );
}

/// Tells the user that [fileName] could not be read from disk.
Future<void> showReadFailedDialog(
  BuildContext context, {
  required String fileName,
}) {
  final strings = AppLocalizations.of(context);
  return _show(
    context,
    title: strings.openErrorTitle(fileName),
    lines: [Text(strings.readFailedMessage, key: OpenErrorDialogKeys.reason)],
  );
}

Future<void> _show(
  BuildContext context, {
  required String title,
  required List<Widget> lines,
}) {
  final strings = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: OpenErrorDialogKeys.dialog,
      icon: const Icon(Icons.error_outline),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
      actions: [
        FilledButton(
          key: OpenErrorDialogKeys.ok,
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.dialogOk),
        ),
      ],
    ),
  );
}

/// The user-facing reason for a JSON syntax error, from the string table.
String jsonErrorReason(AppLocalizations strings, JsonParseFailure error) {
  String expected() => switch (error.expected) {
    JsonExpected.key => strings.jsonExpectedKey,
    JsonExpected.colon => strings.jsonExpectedColon,
    JsonExpected.commaOrCloseBrace => strings.jsonExpectedCommaOrCloseBrace,
    JsonExpected.commaOrCloseBracket => strings.jsonExpectedCommaOrCloseBracket,
    JsonExpected.value || null => strings.jsonExpectedValue,
  };
  return switch (error.kind) {
    JsonErrorKind.emptyDocument => strings.jsonErrorEmptyDocument,
    JsonErrorKind.unexpectedEnd => strings.jsonErrorUnexpectedEnd(expected()),
    JsonErrorKind.unexpectedCharacter => strings.jsonErrorUnexpectedCharacter(
      error.found ?? '',
      expected(),
    ),
    JsonErrorKind.trailingText => strings.jsonErrorTrailingText,
    JsonErrorKind.unterminatedString => strings.jsonErrorUnterminatedString,
    JsonErrorKind.controlCharacter => strings.jsonErrorControlCharacter,
    JsonErrorKind.invalidEscape => strings.jsonErrorInvalidEscape,
    JsonErrorKind.invalidUnicodeEscape => strings.jsonErrorInvalidUnicodeEscape,
    JsonErrorKind.invalidNumber => strings.jsonErrorInvalidNumber,
    JsonErrorKind.leadingZero => strings.jsonErrorLeadingZero,
    JsonErrorKind.tooDeep => strings.jsonErrorTooDeep,
  };
}
