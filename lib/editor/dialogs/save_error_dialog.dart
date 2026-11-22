import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

/// Keys for the save-error dialog (used by tests).
abstract final class SaveErrorDialogKeys {
  static const dialog = ValueKey('saveError.dialog');
  static const ok = ValueKey('saveError.ok');
}

/// Tells the user that writing [fileName] failed (§3.4).
Future<void> showSaveFailedDialog(
  BuildContext context, {
  required String fileName,
}) {
  final strings = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: SaveErrorDialogKeys.dialog,
      icon: const Icon(Icons.error_outline),
      title: Text(strings.saveErrorTitle(fileName)),
      content: Text(strings.saveErrorMessage),
      actions: [
        FilledButton(
          key: SaveErrorDialogKeys.ok,
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.dialogOk),
        ),
      ],
    ),
  );
}
