import 'package:material_ui/material_ui.dart';

/// Read-only, scrollable plain text view of the document (Phase 1: no
/// highlighting, no line numbers).
class PlainTextView extends StatefulWidget {
  const PlainTextView({super.key, required this.text});

  static const textKey = ValueKey('plainText.text');

  final String text;

  @override
  State<PlainTextView> createState() => _PlainTextViewState();
}

class _PlainTextViewState extends State<PlainTextView> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scrollbar(
      controller: _vertical,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        notificationPredicate: (n) => n.depth == 1,
        child: SingleChildScrollView(
          controller: _vertical,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              widget.text,
              key: PlainTextView.textKey,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Menlo',
                fontFamilyFallback: const ['Monaco', 'Courier', 'monospace'],
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
