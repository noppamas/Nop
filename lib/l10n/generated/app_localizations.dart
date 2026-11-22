import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name, used for the window title.
  ///
  /// In en, this message translates to:
  /// **'JSON Better Editor'**
  String get appTitle;

  /// Document title shown when no file is open.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledDocument;

  /// Toolbar tooltip: create a new document.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get toolbarNew;

  /// Toolbar tooltip: open a JSON file.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get toolbarOpen;

  /// Toolbar tooltip: search keys and values.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get toolbarSearch;

  /// Toolbar tooltip: show only the Text pane.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get toolbarLayoutTextOnly;

  /// Toolbar tooltip: show only the Node pane.
  ///
  /// In en, this message translates to:
  /// **'Node only'**
  String get toolbarLayoutNodeOnly;

  /// Toolbar tooltip: show Text and Node side by side.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get toolbarLayoutSplit;

  /// Toolbar tooltip: switch the UI language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get toolbarLanguage;

  /// Toolbar tooltip: toggle light or dark theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get toolbarTheme;

  /// Toolbar tooltip: open Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get toolbarSettings;

  /// File type name in the open and save dialogs.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get jsonFileTypeLabel;

  /// Button that closes an information dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// Title of the dialog shown when a file cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Can’t open “{fileName}”'**
  String openErrorTitle(String fileName);

  /// Explains that an invalid file was not opened.
  ///
  /// In en, this message translates to:
  /// **'This file is not valid JSON, so it was not opened.'**
  String get invalidJsonMessage;

  /// Where the JSON error is.
  ///
  /// In en, this message translates to:
  /// **'Line {line}, column {column}'**
  String invalidJsonPosition(int line, int column);

  /// Shown when reading a file from disk fails.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read.'**
  String get readFailedMessage;

  /// JSON error: no content.
  ///
  /// In en, this message translates to:
  /// **'The file is empty.'**
  String get jsonErrorEmptyDocument;

  /// JSON error: file ends too early.
  ///
  /// In en, this message translates to:
  /// **'The file ends where {expected} was expected.'**
  String jsonErrorUnexpectedEnd(String expected);

  /// JSON error: wrong character.
  ///
  /// In en, this message translates to:
  /// **'Found “{found}” where {expected} was expected.'**
  String jsonErrorUnexpectedCharacter(String found, String expected);

  /// JSON error: content after the root value.
  ///
  /// In en, this message translates to:
  /// **'There is extra text after the JSON value.'**
  String get jsonErrorTrailingText;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'A string is missing its closing quote.'**
  String get jsonErrorUnterminatedString;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'A string contains a control character (such as a raw line break).'**
  String get jsonErrorControlCharacter;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'A string contains an invalid escape sequence.'**
  String get jsonErrorInvalidEscape;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'A string contains an invalid \\u escape.'**
  String get jsonErrorInvalidUnicodeEscape;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'A number is not written correctly.'**
  String get jsonErrorInvalidNumber;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'A number starts with an extra zero.'**
  String get jsonErrorLeadingZero;

  /// JSON error.
  ///
  /// In en, this message translates to:
  /// **'The data is nested too deeply.'**
  String get jsonErrorTooDeep;

  /// Inserted into JSON error messages.
  ///
  /// In en, this message translates to:
  /// **'a value'**
  String get jsonExpectedValue;

  /// Inserted into JSON error messages.
  ///
  /// In en, this message translates to:
  /// **'a key in double quotes'**
  String get jsonExpectedKey;

  /// Inserted into JSON error messages.
  ///
  /// In en, this message translates to:
  /// **'“:”'**
  String get jsonExpectedColon;

  /// Inserted into JSON error messages.
  ///
  /// In en, this message translates to:
  /// **'“,” or “\'}\'”'**
  String get jsonExpectedCommaOrCloseBrace;

  /// Inserted into JSON error messages.
  ///
  /// In en, this message translates to:
  /// **'“,” or “]”'**
  String get jsonExpectedCommaOrCloseBracket;

  /// Title of the dialog shown when saving fails.
  ///
  /// In en, this message translates to:
  /// **'Can’t save “{fileName}”'**
  String saveErrorTitle(String fileName);

  /// Body of the dialog shown when saving fails.
  ///
  /// In en, this message translates to:
  /// **'The file could not be written. Your document is still open and unchanged.'**
  String get saveErrorMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
