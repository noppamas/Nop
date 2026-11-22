import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../platform/native_window.dart';
import '../editor_layout.dart';
import 'toolbar_button.dart';

/// Keys for the toolbar buttons, in on-screen order (used by tests).
abstract final class ToolbarKeys {
  static const newDocument = ValueKey('toolbar.new');
  static const open = ValueKey('toolbar.open');
  static const divider = ValueKey('toolbar.divider');
  static const search = ValueKey('toolbar.search');
  static const layoutTextOnly = ValueKey('toolbar.layout.textOnly');
  static const layoutNodeOnly = ValueKey('toolbar.layout.nodeOnly');
  static const layoutSplit = ValueKey('toolbar.layout.split');
  static const language = ValueKey('toolbar.language');
  static const theme = ValueKey('toolbar.theme');
  static const settings = ValueKey('toolbar.settings');
}

/// The main window toolbar (§3.2). It shares the title-bar row with the
/// macOS window controls, so it leaves room for them on the left.
///
/// Phase 1: buttons without a callback are placeholders.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.layout,
    required this.onLayoutChanged,
    this.onNew,
    this.onOpen,
    this.onSearch,
    this.onLanguage,
    this.onTheme,
    this.onSettings,
  });

  final EditorLayout layout;
  final ValueChanged<EditorLayout> onLayoutChanged;
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onSearch;
  final VoidCallback? onLanguage;
  final VoidCallback? onTheme;
  final VoidCallback? onSettings;

  static void _placeholder() {}

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    const gap = SizedBox(width: 4);

    Widget layoutButton(
      Key key,
      EditorLayout value,
      IconData icon,
      String tooltip,
    ) {
      return ToolbarButton(
        key: key,
        icon: icon,
        tooltip: tooltip,
        selected: layout == value,
        onPressed: () => onLayoutChanged(value),
      );
    }

    return SizedBox(
      height: NativeWindow.titleBarHeight,
      child: Stack(
        children: [
          // Empty areas of the row behave like a native title bar: drag to
          // move the window, double-click to zoom. Buttons sit above this
          // layer, so their taps are not delayed by the double-tap check.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => NativeWindow.startDrag(),
              onDoubleTap: NativeWindow.zoom,
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: NativeWindow.windowControlsInset,
                end: 12,
              ),
              child: Row(
                children: [
                  ToolbarButton(
                    key: ToolbarKeys.newDocument,
                    icon: Icons.insert_drive_file_outlined,
                    tooltip: strings.toolbarNew,
                    onPressed: onNew ?? _placeholder,
                  ),
                  gap,
                  ToolbarButton(
                    key: ToolbarKeys.open,
                    icon: Icons.folder_open_outlined,
                    tooltip: strings.toolbarOpen,
                    onPressed: onOpen ?? _placeholder,
                  ),
                  const SizedBox(
                    key: ToolbarKeys.divider,
                    height: 20,
                    child: VerticalDivider(width: 17),
                  ),
                  ToolbarButton(
                    key: ToolbarKeys.search,
                    icon: Icons.search,
                    tooltip: strings.toolbarSearch,
                    onPressed: onSearch ?? _placeholder,
                  ),
                  const Spacer(),
                  layoutButton(
                    ToolbarKeys.layoutTextOnly,
                    EditorLayout.textOnly,
                    Icons.notes,
                    strings.toolbarLayoutTextOnly,
                  ),
                  gap,
                  layoutButton(
                    ToolbarKeys.layoutNodeOnly,
                    EditorLayout.nodeOnly,
                    Icons.account_tree_outlined,
                    strings.toolbarLayoutNodeOnly,
                  ),
                  gap,
                  layoutButton(
                    ToolbarKeys.layoutSplit,
                    EditorLayout.split,
                    Icons.vertical_split_outlined,
                    strings.toolbarLayoutSplit,
                  ),
                  const SizedBox(width: 12),
                  ToolbarButton(
                    key: ToolbarKeys.language,
                    icon: Icons.translate,
                    tooltip: strings.toolbarLanguage,
                    onPressed: onLanguage ?? _placeholder,
                  ),
                  gap,
                  ToolbarButton(
                    key: ToolbarKeys.theme,
                    icon: Icons.contrast,
                    tooltip: strings.toolbarTheme,
                    onPressed: onTheme ?? _placeholder,
                  ),
                  gap,
                  ToolbarButton(
                    key: ToolbarKeys.settings,
                    icon: Icons.settings_outlined,
                    tooltip: strings.toolbarSettings,
                    onPressed: onSettings ?? _placeholder,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
