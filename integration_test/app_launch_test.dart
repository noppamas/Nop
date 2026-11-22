import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/editor/editor_screen.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:json_better_editor/main.dart' as app;
import 'package:json_better_editor/platform/native_window.dart';

/// Launch smoke test: starts the real app on macOS.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows the main window', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);
    expect(await NativeWindow.getTitle(), 'JSON Better Editor');

    // The toolbar shares the title-bar row with the native window controls
    // without overlapping them.
    final controls = await NativeWindow.windowControlsFrame();
    expect(controls, isNotNull);
    final firstButton = tester.getRect(find.byKey(ToolbarKeys.newDocument));
    // ignore: avoid_print
    print('window controls: $controls, first toolbar button: $firstButton');
    expect(controls!.overlaps(firstButton), isFalse);
    expect(firstButton.left, greaterThan(controls.right));
    // Same row: vertical centers within a few points of each other.
    expect((controls.center.dy - firstButton.center.dy).abs(), lessThan(6));
  });
}
