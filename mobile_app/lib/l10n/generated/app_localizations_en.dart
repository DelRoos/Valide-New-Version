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
  String get errorPermissionDenied =>
      'Session expired. Restart the app to refresh.';

  @override
  String get errorNetworkUnavailable =>
      'No connection. Check your network and try again.';

  @override
  String get errorFirestoreUnknown => 'Technical error. Try again in a moment.';

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
  String get subsystemChoiceTitle => 'Which section are you in?';

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
  String get onboardingPickerObligatoryTitle => 'Compulsory subjects';

  @override
  String get onboardingPickerOptionalTitle => 'Optional subjects';

  @override
  String get onboardingPickerSeriesTitle => 'Pick your stream';

  @override
  String get onboardingPickerTransversalesTitle =>
      'Optional transversal subjects';

  @override
  String get onboardingPickerProfessionalTitle =>
      'Professional subjects (mandatory)';

  @override
  String get onboardingPickerRelatedTitle => 'Related subjects';

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
  String get onboardingSchoolTitle => 'Which school are you in?';

  @override
  String get onboardingSchoolSubtitle =>
      'Search for your school. If not listed, you can suggest it.';

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

  @override
  String get onboardingSubSystemTitle => 'Choose Your System';

  @override
  String get onboardingSubSystemSubtitle =>
      'Pick the school system you follow to get started.';

  @override
  String get onboardingSubSystemFrancophone => 'Francophone';

  @override
  String get onboardingSubSystemFrancophoneDesc =>
      'Cameroonian official curriculum (BEPC, Probatoire, BAC)';

  @override
  String get onboardingSubSystemAnglophone => 'Anglophone';

  @override
  String get onboardingSubSystemAnglophoneDesc =>
      'GCE O-Level to A-Level (English-medium curriculum)';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get heroIntroTitle => 'Learn at your pace, your level.';

  @override
  String get heroIntroSubtitle =>
      'Courses, exercises, and an AI assistant always available.';

  @override
  String get heroIntroFeatureCoursesTitle => 'Courses';

  @override
  String get heroIntroFeatureCoursesDesc => 'All curricula, explained simply.';

  @override
  String get heroIntroFeatureExercisesTitle => 'Exercises';

  @override
  String get heroIntroFeatureExercisesDesc => 'Practice with instant feedback.';

  @override
  String get heroIntroFeatureChatTitle => 'AI Chat';

  @override
  String get heroIntroFeatureChatDesc => 'Ask any question, anytime.';

  @override
  String get heroIntroCta => 'Let\'s go';

  @override
  String get onboardingTrackTitle => 'What\'s Your Track?';

  @override
  String get onboardingTrackSubtitle =>
      'Pick the type of curriculum you follow.';

  @override
  String get onboardingTrackHintGeneral =>
      'Classic academic program (maths, sciences, arts)';

  @override
  String get onboardingTrackHintTechnique =>
      'Vocational program (industrial, commercial, services)';

  @override
  String get onboardingLevelTitle => 'What\'s Your Class?';

  @override
  String get onboardingLevelSubtitle =>
      'Select your current level to tailor content.';

  @override
  String get onboardingStreamSubjectsTitle => 'Which subjects are you taking?';

  @override
  String get onboardingStreamSubjectsSubtitle =>
      'Select your stream and subjects to tailor lessons.';

  @override
  String onboardingPickerCounter(int count, int max) {
    return '$count/$max selected';
  }

  @override
  String get onboardingPickerValidate => 'Confirm my subjects';

  @override
  String get errorCatalogueLoading =>
      'Cannot load catalogue. Check your connection and try again.';

  @override
  String get errorCatalogueEmpty => 'No data available. Try again later.';

  @override
  String get errorOfflineTitle => 'No connection';

  @override
  String get errorLoadingTitle => 'Loading failed';

  @override
  String get errorGenericTitle => 'Oops, something went wrong';

  @override
  String get offlineBannerMessage => 'No internet connection';

  @override
  String get onboardingAuthTitle => 'Create your account';

  @override
  String get onboardingAuthSubtitle =>
      'One step to save your progress and profile.';

  @override
  String get onboardingAuthGoogleLabel => 'Continue with Google';

  @override
  String get onboardingAuthAppleLabel => 'Continue with Apple';

  @override
  String get onboardingAuthOrLabel => 'or';

  @override
  String get onboardingAuthGuestLabel => 'Continue as guest';

  @override
  String get onboardingAuthErrorCanceled => 'Sign-in canceled.';

  @override
  String get onboardingAuthErrorConflict =>
      'This account is already linked to another profile.';

  @override
  String get onboardingGuestSwitchTitle => 'Continue as guest?';

  @override
  String get onboardingGuestSwitchBody =>
      'You\'re signed in with an account. Continuing as a guest will delete your current profile and you\'ll start over.';

  @override
  String get onboardingGuestSwitchConfirm => 'Delete and continue';

  @override
  String get onboardingGuestSwitchCancel => 'Keep my account';

  @override
  String get accountUpgradeSheetTitle => 'Save your account';

  @override
  String get accountUpgradeSheetBody =>
      'Linking your account lets you keep your progress on any phone and avoid losing everything if you switch devices.';

  @override
  String get accountUpgradeSuccess => 'Account saved ✨';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingNameSubtitle =>
      'Your first name (or a nickname) is enough.';

  @override
  String get onboardingNamePlaceholder => 'Your first name';

  @override
  String get onboardingNameTooShort => 'At least 2 characters.';

  @override
  String get onboardingNameTooLong => 'Maximum 50 characters.';

  @override
  String get onboardingPhoneTitle => 'Your phone number';

  @override
  String get onboardingPhoneSubtitle =>
      'So we can reach you if needed. Optional.';

  @override
  String get onboardingPhoneSkipLabel => 'Skip for now';

  @override
  String get onboardingPhoneSkipConfirmTitle => 'Skip this step?';

  @override
  String get onboardingPhoneSkipConfirmMessage =>
      'You can add your phone number later from your profile.';

  @override
  String get onboardingPhoneSkipConfirmYes => 'Yes, skip';

  @override
  String get onboardingPhoneSkipConfirmNo => 'No, add';

  @override
  String get onboardingPhoneInvalid =>
      'Invalid number. Format: +237 6XX XXX XXX';

  @override
  String get onboardingSchoolPlaceholder => 'Your school name';

  @override
  String onboardingSchoolAddTemplate(String name) {
    return '+ Add \"$name\"';
  }

  @override
  String get onboardingSchoolOfflineWarning =>
      'No connection. You can still suggest adding it.';

  @override
  String get onboardingSchoolSkipLabel => 'Skip for now';

  @override
  String get onboardingSuccessTitle => 'Welcome to Valide!';

  @override
  String get onboardingSuccessSubtitle => 'Your profile is ready. Let\'s go!';

  @override
  String get onboardingSuccessCta => 'Go to my dashboard';

  @override
  String get onboardingFlushError => 'Could not save your profile. Try again.';
}
