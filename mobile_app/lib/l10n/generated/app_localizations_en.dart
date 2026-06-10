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
  String get subsystemConfirmTitle => 'Which section are you in?';

  @override
  String get subsystemConfirmBody =>
      'Final choice: language (FR/EN) + school curriculum.';

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

  @override
  String get onboardingOptOutTitle => 'Pick your subjects';

  @override
  String get onboardingOptOutSubtitle => 'Uncheck the ones you\'re not taking.';

  @override
  String onboardingOptOutTakingCount(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'ll take $count of $total subjects',
      one: 'You\'ll take 1 of $total subjects',
    );
    return '$_temp0';
  }

  @override
  String get onboardingOptOutValidateCta => 'Save';

  @override
  String get onboardingPickerTitle => 'Choose your subjects';

  @override
  String get onboardingPickerSubtitle =>
      'Select the subjects you\'ll sit for at your exam.';

  @override
  String get onboardingPickerObligatoryTitle => 'Mandatory subjects';

  @override
  String get onboardingPickerOptionalTitle => 'Optional subjects';

  @override
  String get onboardingPickerSeriesTitle => 'Series (mandatory)';

  @override
  String get onboardingPickerTransversalesTitle =>
      'Optional transversal subjects';

  @override
  String get onboardingPickerProfessionalTitle =>
      'Professional subjects (mandatory)';

  @override
  String get onboardingPickerRelatedTitle =>
      'Related professional subjects (mandatory)';

  @override
  String get onboardingPickerOtherTitle => 'Other subjects';

  @override
  String onboardingPickerCounterLive(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You take $count/$max subjects',
      one: 'You take 1/$max subject',
    );
    return '$_temp0';
  }

  @override
  String get onboardingPickerErrorObligatoryToast =>
      'This subject is mandatory and cannot be removed.';

  @override
  String get onboardingPickerValidateCta => 'Confirm my choice';

  @override
  String get onboardingRecapModifyLink => 'Edit my subjects';

  @override
  String get onboardingAccountTitle => 'Create your account';

  @override
  String get onboardingAccountSubtitle =>
      'Save your progress, pick up on any device.';

  @override
  String get onboardingAccountGoogleCta => 'Continue with Google';

  @override
  String get onboardingAccountAppleCta => 'Continue with Apple';

  @override
  String get onboardingAccountGuestCta => 'Continue as guest';

  @override
  String get onboardingAccountNetworkErrorToast =>
      'No connection. Check your connection and try again.';

  @override
  String get onboardingAccountConflictTitle => 'Account already in use';

  @override
  String get onboardingAccountConflictBody =>
      'This account is already linked to another Valide profile. If you sign in with it, you\'ll lose your current profile.';

  @override
  String get onboardingAccountAlreadyLinkedToast =>
      'You already have an account.';

  @override
  String get onboardingSchoolTitle => 'Link your school (optional)';

  @override
  String get onboardingSchoolSubtitle =>
      'To join class and school rankings later.';

  @override
  String get onboardingSchoolSearchPlaceholder => 'Search my school…';

  @override
  String onboardingSchoolEmptyTitle(String query) {
    return 'No school found for \"$query\".';
  }

  @override
  String get onboardingSchoolAddCta => 'Add my school';

  @override
  String get onboardingSchoolAddDialogTitle => 'Request to add my school';

  @override
  String get onboardingSchoolAddDialogNameLabel => 'School name';

  @override
  String get onboardingSchoolAddDialogCityLabel => 'City';

  @override
  String get onboardingSchoolAddDialogRegionLabel => 'Region (optional)';

  @override
  String get onboardingSchoolAddDialogSubSystemLabel => 'Sub-system (optional)';

  @override
  String get onboardingSchoolAddDialogSubSystemFrancophone => 'Francophone';

  @override
  String get onboardingSchoolAddDialogSubSystemAnglophone => 'Anglophone';

  @override
  String get onboardingSchoolAddDialogSubSystemBoth => 'Bilingual';

  @override
  String get onboardingSchoolAddDialogSubSystemUnknown => 'I don\'t know';

  @override
  String get onboardingSchoolAddDialogSubmitCta => 'Send request';

  @override
  String get onboardingSchoolAddRequestSentToast =>
      'Request sent, we\'ll get back to you.';

  @override
  String get onboardingSchoolSkipCta => 'Skip this step';

  @override
  String get onboardingSchoolSkipToast =>
      'You can link your school later in Profile.';

  @override
  String get onboardingSchoolValidatedBadge => 'Verified';

  @override
  String get onboardingSchoolGenericErrorToast =>
      'Something went wrong, check your connection and try again.';

  @override
  String dashboardWelcomeWithName(String name) {
    return 'Welcome $name!';
  }

  @override
  String get dashboardWelcomeGuest => 'Welcome!';

  @override
  String dashboardSubtitleWithExam(String exam) {
    return 'Here are your subjects — you\'re preparing for $exam';
  }

  @override
  String get dashboardSubtitleNoExam => 'Here are your subjects.';

  @override
  String get dashboardGuestBadge => 'Guest';

  @override
  String get dashboardGuestInviteText =>
      'Create an account to save your progress';

  @override
  String get dashboardGuestInviteCta => 'Create my account';

  @override
  String get dashboardEmptyStateText =>
      'Complete your profile to see your subjects.';

  @override
  String get dashboardEmptyStateCta => 'Continue onboarding';

  @override
  String get dashboardComingSoon => 'Coming soon';

  @override
  String get dashboardTabHome => 'Home';

  @override
  String get dashboardTabSubjects => 'Subjects';

  @override
  String get dashboardTabActivities => 'Activities';

  @override
  String get dashboardTabProfile => 'Profile';
}
