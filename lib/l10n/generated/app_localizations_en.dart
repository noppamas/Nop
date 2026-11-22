// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JSON Better Editor';

  @override
  String get untitledDocument => 'Untitled';

  @override
  String get toolbarNew => 'New';

  @override
  String get toolbarOpen => 'Open';

  @override
  String get toolbarSearch => 'Search';

  @override
  String get toolbarLayoutTextOnly => 'Text only';

  @override
  String get toolbarLayoutNodeOnly => 'Node only';

  @override
  String get toolbarLayoutSplit => 'Split';

  @override
  String get toolbarLanguage => 'Language';

  @override
  String get toolbarTheme => 'Theme';

  @override
  String get toolbarSettings => 'Settings';

  @override
  String get jsonFileTypeLabel => 'JSON';
}
