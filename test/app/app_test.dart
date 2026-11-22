import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/editor/editor_screen.dart';
import 'package:json_better_editor/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('app starts on the editor screen', (tester) async {
    await tester.pumpWidget(const JsonEditorApp());

    expect(find.byType(EditorScreen), findsOneWidget);
  });

  testWidgets('title comes from the English string table', (tester) async {
    await tester.pumpWidget(const JsonEditorApp());

    final context = tester.element(find.byType(EditorScreen));
    final strings = AppLocalizations.of(context);
    expect(strings.appTitle, 'JSON Better Editor');
    expect(Localizations.localeOf(context), const Locale('en'));
    final title = tester.widget<Title>(find.byType(Title));
    expect(title.title, strings.appTitle);
  });

  testWidgets('Material 3 is on with a light theme', (tester) async {
    await tester.pumpWidget(const JsonEditorApp());

    final theme = Theme.of(tester.element(find.byType(EditorScreen)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
  });
}
