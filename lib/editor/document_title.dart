import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';

/// The document title row shown under the toolbar (§3.2).
class DocumentTitle extends StatelessWidget {
  const DocumentTitle({super.key, this.fileName});

  static const titleKey = ValueKey('document.title');

  /// Name of the open file, or null when nothing is open.
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        fileName ?? strings.untitledDocument,
        key: titleKey,
        style: theme.textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
