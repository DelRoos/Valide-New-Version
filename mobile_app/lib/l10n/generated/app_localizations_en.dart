// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Valide School';

  @override
  String helloValide(String target) {
    return 'Hello $target';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get closeLabel => 'Close';

  @override
  String get okLabel => 'OK';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get confirmYes => 'Yes';

  @override
  String get confirmNo => 'No';

  @override
  String get loadingLabel => 'Loading…';

  @override
  String get sendingLabel => 'Sending…';

  @override
  String get loadingMore => 'Loading…';

  @override
  String get retryLabel => 'Try again';

  @override
  String get tryAgain => 'Try again later';

  @override
  String get errorGeneric => 'Something went wrong. Try again?';

  @override
  String get errorNoConnection =>
      'No connection. You can continue with what you\'ve opened.';

  @override
  String get successCopied => 'Link copied.';

  @override
  String get emptyStateGeneric => 'Nothing to show yet.';

  @override
  String get pageNotFound => 'Page not found';
}
