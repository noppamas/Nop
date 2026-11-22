import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import '../editor/editor_screen.dart';
import '../files/document_files.dart';
import '../l10n/generated/app_localizations.dart';
import '../platform/native_window.dart';
import 'theme.dart';

/// Root widget of JSON Better Editor.
class JsonEditorApp extends StatelessWidget {
  const JsonEditorApp({super.key, this.files = const SystemDocumentFiles()});

  /// File dialogs and disk access; tests pass a fake.
  final DocumentFiles files;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) {
        final title = AppLocalizations.of(context).appTitle;
        unawaited(NativeWindow.setTitle(title));
        return title;
      },
      theme: buildLightTheme(),
      // English is the only and default language for now (decision 30).
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: EditorScreen(files: files),
    );
  }
}
