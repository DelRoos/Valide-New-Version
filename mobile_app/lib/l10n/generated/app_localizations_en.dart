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

  @override
  String get helloLanguageLabel => 'Language';

  @override
  String get helloLanguageFr => 'French';

  @override
  String get helloLanguageEn => 'English';

  @override
  String get catalogueWaitingTitle => 'Waiting for connection';

  @override
  String get catalogueWaitingMessage =>
      'To get started, Valide needs to connect once. Check your connection and try again.';

  @override
  String get catalogueWaitingRetry => 'Retry';

  @override
  String get subsystemChoiceTitle => 'Choose your language and program';

  @override
  String get subsystemChoiceSubtitle =>
      'You won\'t be able to change this later.';

  @override
  String get subsystemFrancophone => 'Francophone';

  @override
  String get subsystemAnglophone => 'Anglophone';

  @override
  String get subsystemConfirmTitle => 'Confirm your choice';

  @override
  String get subsystemConfirmBody =>
      'This choice locks your language and program. You won\'t be able to change it later.';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardingFiliereTitle => 'Choose your stream';

  @override
  String get onboardingFiliereGenerale => 'General';

  @override
  String get onboardingFiliereTechnique => 'Technical';

  @override
  String get onboardingNiveauTitle => 'Choose your level';

  @override
  String get onboardingSerieTitle => 'Choose your series';

  @override
  String get onboardingSerieSubtitle =>
      'Pick the series that matches your class.';

  @override
  String onboardingRecapPrepareLabel(String examName) {
    return 'You\'re preparing $examName';
  }

  @override
  String get onboardingRecapNoExamLabel => 'No exam target at this level';

  @override
  String onboardingRecapSubjectsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subjects',
      one: '1 subject',
    );
    return '$_temp0';
  }

  @override
  String get onboardingRecapValidateCta => 'That\'s my class';

  @override
  String get onboardingRecapOptOutLink => 'Remove a subject';

  @override
  String get onboardingRecapCreatingLabel => 'Setting up your profile…';

  @override
  String get onboardingRecapFirestoreErrorToast =>
      'Profile saved locally, we\'ll retry online';

  @override
  String get onboardingRecapNoMatchingRule =>
      'No class found for this profile. Go back and update your choices.';

  @override
  String get profileGuardIncompleteToast =>
      'Complete your profile to continue.';
}
