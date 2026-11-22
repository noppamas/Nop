import 'package:material_ui/material_ui.dart';

/// Rounded, pill-shaped icon button used in the editor toolbar (§3.2).
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        isSelected: selected,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(44, 32),
          maximumSize: const Size(44, 32),
          padding: EdgeInsets.zero,
          backgroundColor: selected ? colors.secondaryContainer : null,
          foregroundColor: selected
              ? colors.onSecondaryContainer
              : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
