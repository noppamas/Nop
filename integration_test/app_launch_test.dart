import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/editor/editor_screen.dart';
import 'package:json_better_editor/main.dart' as app;
import 'package:json_better_editor/platform/window_title.dart';

/// Launch smoke test: starts the real app on macOS and checks the main
/// window appears with its title from the English string table.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows the main window', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);
    expect(await WindowTitle.get(), 'JSON Better Editor');
  });
}
