import 'package:material_ui/material_ui.dart';

/// Basic Material 3 light theme (§3.6).
///
/// Full Atom One Light / One Dark themes arrive in Phase 4.
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4078F2)),
  );
}
