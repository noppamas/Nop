import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';

/// The document title row shown under the toolbar (§3.2).
class DocumentTitle extends StatelessWidget {
  const DocumentTitle({super.key, this.fileName, this.edited = false});

  static const titleKey = ValueKey('document.title');
  static const editedKey = ValueKey('document.edited');

  /// Whether the document has unsaved edits.
  final bool edited;

  /// Name of the open file, or null when nothing is open.
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              fileName ?? strings.untitledDocument,
              key: titleKey,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (edited) ...[
            const SizedBox(width: 8),
            Text(
              strings.documentEdited,
              key: editedKey,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
