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

  @override
  String get dialogOk => 'OK';

  @override
  String openErrorTitle(String fileName) {
    return 'Can’t open “$fileName”';
  }

  @override
  String get invalidJsonMessage =>
      'This file is not valid JSON, so it was not opened.';

  @override
  String invalidJsonPosition(int line, int column) {
    return 'Line $line, column $column';
  }

  @override
  String get readFailedMessage => 'The file could not be read.';

  @override
  String get jsonErrorEmptyDocument => 'The file is empty.';

  @override
  String jsonErrorUnexpectedEnd(String expected) {
    return 'The file ends where $expected was expected.';
  }

  @override
  String jsonErrorUnexpectedCharacter(String found, String expected) {
    return 'Found “$found” where $expected was expected.';
  }

  @override
  String get jsonErrorTrailingText =>
      'There is extra text after the JSON value.';

  @override
  String get jsonErrorUnterminatedString =>
      'A string is missing its closing quote.';

  @override
  String get jsonErrorControlCharacter =>
      'A string contains a control character (such as a raw line break).';

  @override
  String get jsonErrorInvalidEscape =>
      'A string contains an invalid escape sequence.';

  @override
  String get jsonErrorInvalidUnicodeEscape =>
      'A string contains an invalid \\u escape.';

  @override
  String get jsonErrorInvalidNumber => 'A number is not written correctly.';

  @override
  String get jsonErrorLeadingZero => 'A number starts with an extra zero.';

  @override
  String get jsonErrorTooDeep => 'The data is nested too deeply.';

  @override
  String get jsonExpectedValue => 'a value';

  @override
  String get jsonExpectedKey => 'a key in double quotes';

  @override
  String get jsonExpectedColon => '“:”';

  @override
  String get jsonExpectedCommaOrCloseBrace => '“,” or “}”';

  @override
  String get jsonExpectedCommaOrCloseBracket => '“,” or “]”';

  @override
  String saveErrorTitle(String fileName) {
    return 'Can’t save “$fileName”';
  }

  @override
  String get saveErrorMessage =>
      'The file could not be written. Your document is still open and unchanged.';
}
