// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Valide School';

  @override
  String helloValide(String target) {
    return 'Bonjour $target';
  }

  @override
  String get continueLabel => 'Continuer';

  @override
  String get cancelLabel => 'Annuler';

  @override
  String get closeLabel => 'Fermer';

  @override
  String get okLabel => 'OK';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get confirmYes => 'Oui';

  @override
  String get confirmNo => 'Non';

  @override
  String get loadingLabel => 'Chargement…';

  @override
  String get sendingLabel => 'Envoi…';

  @override
  String get loadingMore => 'Chargement…';

  @override
  String get retryLabel => 'Réessayer';

  @override
  String get tryAgain => 'Réessaie plus tard';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessaie ?';

  @override
  String get errorPermissionDenied =>
      'Session expirée. Re-lance l\'app pour rafraîchir.';

  @override
  String get errorNetworkUnavailable =>
      'Pas de connexion. Vérifie ton réseau et réessaie.';

  @override
  String get errorFirestoreUnknown =>
      'Erreur technique. Réessaie dans un instant.';

  @override
  String get errorNoConnection =>
      'Pas de connexion. Tu peux continuer ce que tu as ouvert.';

  @override
  String get successCopied => 'Lien copié.';

  @override
  String get emptyStateGeneric => 'Rien à afficher pour le moment.';

  @override
  String get pageNotFound => 'Page introuvable';

  @override
  String get helloLanguageLabel => 'Langue';

  @override
  String get helloLanguageFr => 'Français';

  @override
  String get helloLanguageEn => 'English';

  @override
  String get catalogueWaitingTitle => 'En attente de connexion';

  @override
  String get catalogueWaitingMessage =>
      'Pour démarrer, Valide doit se connecter une première fois. Vérifie ta connexion et réessaie.';

  @override
  String get catalogueWaitingRetry => 'Réessayer';

  @override
  String get subsystemChoiceTitle => 'Tu fais quelle section ?';

  @override
  String get subsystemChoiceSubtitle => 'Tu ne pourras pas changer après.';

  @override
  String get subsystemFrancophone => 'Francophone';

  @override
  String get subsystemAnglophone => 'Anglophone';

  @override
  String get subsystemConfirmTitle => 'Tu fais quelle section ?';

  @override
  String get subsystemConfirmBody =>
      'Choix définitif : langue (FR/EN) + cursus scolaire.';

  @override
  String onboardingStepLabel(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get onboardingFiliereTitle => 'Choisis ta filière';

  @override
  String get onboardingFiliereGenerale => 'Générale';

  @override
  String get onboardingFiliereTechnique => 'Technique';

  @override
  String get onboardingNiveauTitle => 'Choisis ton niveau';

  @override
  String get onboardingSerieTitle => 'Choisis ta série';

  @override
  String get onboardingSerieSubtitle =>
      'Sélectionne la série qui correspond à ta classe.';

  @override
  String onboardingRecapPrepareLabel(String examName) {
    return 'Tu prépares $examName';
  }

  @override
  String get onboardingRecapNoExamLabel => 'Pas d\'examen visé à ce niveau';

  @override
  String onboardingRecapSubjectsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matières',
      one: '1 matière',
    );
    return '$_temp0';
  }

  @override
  String get onboardingRecapValidateCta => 'C\'est ma classe';

  @override
  String get onboardingRecapOptOutLink => 'Retirer une matière';

  @override
  String get onboardingRecapCreatingLabel => 'Création de ton profil…';

  @override
  String get onboardingRecapFirestoreErrorToast =>
      'Profil sauvegardé localement, on retentera en ligne';

  @override
  String get onboardingRecapNoMatchingRule =>
      'Aucune classe trouvée pour ce profil. Reviens en arrière et corrige tes choix.';

  @override
  String get profileGuardIncompleteToast =>
      'Termine ton profil pour continuer.';

  @override
  String get onboardingOptOutTitle => 'Choisis tes matières';

  @override
  String get onboardingOptOutSubtitle =>
      'Décoche celles que tu ne présentes pas.';

  @override
  String onboardingOptOutTakingCount(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tu présentes $count matières sur $total',
      one: 'Tu présentes 1 matière sur $total',
    );
    return '$_temp0';
  }

  @override
  String get onboardingOptOutValidateCta => 'Valider';

  @override
  String get onboardingPickerTitle => 'Choisis tes matières';

  @override
  String get onboardingPickerSubtitle =>
      'Sélectionne les matières que tu présentes à ton examen.';

  @override
  String get onboardingPickerObligatoryTitle => 'Matières obligatoires';

  @override
  String get onboardingPickerOptionalTitle => 'Matières optionnelles';

  @override
  String get onboardingPickerSeriesTitle => 'Choisis ta série';

  @override
  String get onboardingPickerTransversalesTitle => 'Transversales optionnelles';

  @override
  String get onboardingPickerProfessionalTitle =>
      'Matières professionnelles (obligatoires)';

  @override
  String get onboardingPickerRelatedTitle => 'Matières connexes';

  @override
  String get onboardingPickerOtherTitle => 'Autres matières';

  @override
  String onboardingPickerCounterLive(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tu présentes $count/$max matières',
      one: 'Tu présentes 1/$max matière',
    );
    return '$_temp0';
  }

  @override
  String get onboardingPickerErrorObligatoryToast =>
      'Cette matière est obligatoire et ne peut pas être retirée.';

  @override
  String get onboardingPickerValidateCta => 'Valider mon choix';

  @override
  String get onboardingRecapModifyLink => 'Modifier mes matières';

  @override
  String get onboardingAccountTitle => 'Crée ton compte';

  @override
  String get onboardingAccountSubtitle =>
      'Sauvegarde tes progrès, reprends sur n\'importe quel appareil.';

  @override
  String get onboardingAccountGoogleCta => 'Continuer avec Google';

  @override
  String get onboardingAccountAppleCta => 'Continuer avec Apple';

  @override
  String get onboardingAccountGuestCta => 'Continuer en mode visiteur';

  @override
  String get onboardingAccountNetworkErrorToast =>
      'Pas de connexion. Vérifie ta connexion et réessaie.';

  @override
  String get onboardingAccountConflictTitle => 'Compte déjà utilisé';

  @override
  String get onboardingAccountConflictBody =>
      'Ce compte est déjà lié à un autre profil Valide. Si tu te connectes avec, tu perdras ton profil actuel.';

  @override
  String get onboardingAccountAlreadyLinkedToast => 'Tu as déjà un compte.';

  @override
  String get onboardingSchoolTitle => 'Tu es dans quelle école ?';

  @override
  String get onboardingSchoolSubtitle =>
      'Recherche ton école. Si elle n\'est pas listée, tu peux la proposer.';

  @override
  String get onboardingSchoolSearchPlaceholder => 'Rechercher mon école…';

  @override
  String onboardingSchoolEmptyTitle(String query) {
    return 'Aucune école trouvée pour « $query ».';
  }

  @override
  String get onboardingSchoolAddCta => 'Ajouter mon école';

  @override
  String get onboardingSchoolAddDialogTitle => 'Demander l\'ajout de mon école';

  @override
  String get onboardingSchoolAddDialogNameLabel => 'Nom de ton école';

  @override
  String get onboardingSchoolAddDialogCityLabel => 'Ville';

  @override
  String get onboardingSchoolAddDialogRegionLabel => 'Région (optionnel)';

  @override
  String get onboardingSchoolAddDialogSubSystemLabel =>
      'Sous-système (optionnel)';

  @override
  String get onboardingSchoolAddDialogSubSystemFrancophone => 'Francophone';

  @override
  String get onboardingSchoolAddDialogSubSystemAnglophone => 'Anglophone';

  @override
  String get onboardingSchoolAddDialogSubSystemBoth => 'Bilingue';

  @override
  String get onboardingSchoolAddDialogSubSystemUnknown => 'Je ne sais pas';

  @override
  String get onboardingSchoolAddDialogSubmitCta => 'Envoyer la demande';

  @override
  String get onboardingSchoolAddRequestSentToast =>
      'Demande envoyée, on revient vers toi.';

  @override
  String get onboardingSchoolSkipCta => 'Passer cette étape';

  @override
  String get onboardingSchoolSkipToast =>
      'Tu pourras lier ton école plus tard dans Profil.';

  @override
  String get onboardingSchoolValidatedBadge => 'Validée';

  @override
  String get onboardingSchoolGenericErrorToast =>
      'Erreur, vérifie ta connexion et réessaie.';

  @override
  String dashboardWelcomeWithName(String name) {
    return 'Salut, $name 👋';
  }

  @override
  String get dashboardWelcomeGuest => 'Salut 👋';

  @override
  String dashboardSubtitleWithExam(String exam) {
    return 'Voici tes matières — tu prépares le $exam';
  }

  @override
  String get dashboardSubtitleNoExam => 'Voici tes matières.';

  @override
  String get dashboardGuestBadge => 'Visiteur';

  @override
  String get dashboardGuestInviteText =>
      'Crée ton compte pour sauvegarder ta progression';

  @override
  String get dashboardGuestInviteCta => 'Créer mon compte';

  @override
  String get dashboardEmptyStateText =>
      'Termine ton profil pour voir tes matières.';

  @override
  String get dashboardEmptyStateCta => 'Continuer mon onboarding';

  @override
  String get dashboardComingSoon => 'Bientôt disponible';

  @override
  String get dashboardTabHome => 'Accueil';

  @override
  String get dashboardTabSubjects => 'Cours';

  @override
  String get coursesPageTitle => 'Mes cours';

  @override
  String get coursesStartLesson => 'Commencer';

  @override
  String get coursesRecommendedBannerTitle => 'Reprends là où tu t\'es arrêté';

  @override
  String get coursesSectionTitle => 'Mes matières';

  @override
  String coursesChaptersOf(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done/$total chapitres',
      one: '$done/$total chapitre',
    );
    return '$_temp0';
  }

  @override
  String coursesTermChip(int n) {
    return '📚 Trimestre $n';
  }

  @override
  String coursesTermChaptersProgress(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done chapitres sur $total terminés',
      one: '$done chapitre sur $total terminé',
    );
    return '$_temp0';
  }

  @override
  String get coursesTermCtaLabel => 'Reprendre la leçon';

  @override
  String get dashboardTabActivities => 'Examen';

  @override
  String get dashboardTabProfile => 'Profil';

  @override
  String get examsPageTitle => 'Examens';

  @override
  String get examsCountdownChip => '🎯  BAC 2026';

  @override
  String get examsCountdownHeadline => '4 mois restants';

  @override
  String get examsCountdownSubtitle => 'Continue à réviser chaque jour';

  @override
  String examsCountdownPrepared(int pct) {
    return '$pct% préparé';
  }

  @override
  String get examsCountdownMonths => 'mois';

  @override
  String get examsSectionTitle => 'Fiches de révision';

  @override
  String examsExercisesOf(int done, int total) {
    return '$done/$total exercices';
  }

  @override
  String get profilePageTitle => 'Mon profil';

  @override
  String get profileStreak => 'Série';

  @override
  String get profileLessons => 'Leçons';

  @override
  String get profileAvgScore => 'Score moy.';

  @override
  String get profileDays => 'jours';

  @override
  String get profileSubjects => 'Matières';

  @override
  String get profileExams => 'Examens';

  @override
  String get profileSectionCourses => 'Mon parcours';

  @override
  String get profileSectionSettings => 'Réglages';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileMenuSubscription => 'Mon abonnement';

  @override
  String get profileMenuResults => 'Mes résultats';

  @override
  String get profileMenuLanguage => 'Langue';

  @override
  String get profileMenuNotifications => 'Notifications';

  @override
  String get profileMenuAccount => 'Paramètres du compte';

  @override
  String get profileMenuSignOut => 'Se déconnecter';

  @override
  String get profileGuestTitle => 'Continue avec un compte';

  @override
  String get profileGuestSubtitle =>
      'Sauvegarde ta progression et rejoins le classement.';

  @override
  String get completeProfileDialogTitle => 'Compléter mon profil';

  @override
  String get completeProfileDialogBody =>
      'Complète ton profil pour sauvegarder ta progression et accéder à toutes les fonctionnalités.';

  @override
  String get languagePickerTitle => 'Choisir la langue';

  @override
  String get languageOptionFrench => 'Français';

  @override
  String get languageOptionEnglish => 'Anglais';

  @override
  String get onboardingSubSystemTitle => 'Quelle section suis-tu ?';

  @override
  String get onboardingSubSystemSubtitle =>
      'Choisis ton système scolaire pour démarrer.';

  @override
  String get onboardingSubSystemFrancophone => 'Francophone';

  @override
  String get onboardingSubSystemFrancophoneDesc =>
      'De la 6ᵉ à la Terminale · BEPC, Probatoire, BAC';

  @override
  String get onboardingSubSystemAnglophone => 'Anglophone';

  @override
  String get onboardingSubSystemAnglophoneDesc =>
      'De Form 1 à Upper Sixth · GCE O-Level, A-Level';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get heroIntroTitle => 'Apprends à ton rythme, à ton niveau.';

  @override
  String get heroIntroSubtitle =>
      'Cours, exercices, et un assistant IA toujours disponible.';

  @override
  String get heroIntroFeatureCoursesTitle => 'Cours';

  @override
  String get heroIntroFeatureCoursesDesc =>
      'Tout le programme, expliqué simplement.';

  @override
  String get heroIntroFeatureExercisesTitle => 'Exercices';

  @override
  String get heroIntroFeatureExercisesDesc =>
      'Entraîne-toi avec correction immédiate.';

  @override
  String get heroIntroFeatureChatTitle => 'Chat IA';

  @override
  String get heroIntroFeatureChatDesc =>
      'Pose toutes tes questions, à toute heure.';

  @override
  String get heroIntroCta => 'C\'est parti';

  @override
  String get onboardingTrackTitle => 'Quelle filière suis-tu ?';

  @override
  String get onboardingTrackSubtitle =>
      'Choisis le type d\'enseignement que tu veux suivre.';

  @override
  String get onboardingTrackHintGeneral =>
      'Programme académique classique (maths, sciences, lettres)';

  @override
  String get onboardingTrackHintTechnique =>
      'Programme professionnel (industriel, commercial, tertiaire)';

  @override
  String get onboardingLevelTitle => 'Tu es en quelle classe ?';

  @override
  String get onboardingLevelSubtitle =>
      'Sélectionne ton niveau actuel pour adapter le contenu.';

  @override
  String get onboardingStreamSubjectsTitle => 'Ta classe';

  @override
  String get onboardingStreamSubjectsSubtitle =>
      'Voici les matières que tu vas étudier.';

  @override
  String get onboardingRecapLabelSection => 'Section';

  @override
  String get onboardingRecapLabelTrack => 'Filière';

  @override
  String get onboardingRecapLabelLevel => 'Niveau';

  @override
  String get onboardingRecapLabelStream => 'Série';

  @override
  String get onboardingRecapLabelExam => 'Examen';

  @override
  String get onboardingStreamPickerEmptyTitle => 'Aucune série disponible';

  @override
  String get onboardingStreamPickerEmptyBody =>
      'Pour ce niveau, aucune série n\'est encore configurée. Essaie un autre niveau, ou réessaie dans quelques minutes.';

  @override
  String get onboardingStreamPickerEmptyRetry => 'Réessayer';

  @override
  String get onboardingStreamPickerEmptyChangeLevel => 'Changer de niveau';

  @override
  String get onboardingLevelEmptyForTrackTitle =>
      'Aucune classe pour cette filière';

  @override
  String get onboardingLevelEmptyForTrackBody =>
      'Aucune classe n\'est encore disponible pour cette filière. Change de filière pour continuer.';

  @override
  String get onboardingLevelEmptyForTrackChangeTrack => 'Changer de filière';

  @override
  String get onboardingLoaderLabel => 'Chargement…';

  @override
  String get onboardingGroupLv2 => 'Langue Vivante 2';

  @override
  String get onboardingGroupLv3 => 'Langue Vivante 3';

  @override
  String get onboardingGroupOlevelOptions => 'Matière O-Level';

  @override
  String get onboardingGroupAlevelOptions => 'Matière A-Level';

  @override
  String get onboardingGroupGeneric => 'matière';

  @override
  String get onboardingGroupPickHint => 'Choisis 1';

  @override
  String onboardingPickerChooseUpTo(int count) {
    return 'Choisis jusqu\'à $count';
  }

  @override
  String onboardingPickerCounter(int count, int max) {
    return '$count/$max sélectionnées';
  }

  @override
  String get onboardingPickerValidate => 'Valider mes matières';

  @override
  String get onboardingStartRevising => 'Commencer à réviser';

  @override
  String get errorCatalogueLoading =>
      'Impossible de charger le catalogue. Vérifie ta connexion et réessaie.';

  @override
  String get errorCatalogueEmpty =>
      'Aucune donnee disponible. Reessaie plus tard.';

  @override
  String get errorOfflineTitle => 'Pas de connexion';

  @override
  String get errorLoadingTitle => 'Chargement impossible';

  @override
  String get errorGenericTitle => 'Oups, quelque chose a coince';

  @override
  String get offlineBannerMessage => 'Pas de connexion internet';

  @override
  String get onboardingAuthTitle => 'Crée ton compte';

  @override
  String get onboardingAuthSubtitle =>
      'Une seule étape pour sauvegarder ton progrès et ton profil.';

  @override
  String get onboardingAuthGoogleLabel => 'Continuer avec Google';

  @override
  String get onboardingAuthAppleLabel => 'Continuer avec Apple';

  @override
  String get onboardingAuthOrLabel => 'ou';

  @override
  String get onboardingAuthGuestLabel => 'Continuer en visiteur';

  @override
  String get onboardingAuthErrorCanceled => 'Connexion annulee.';

  @override
  String get onboardingAuthErrorConflict =>
      'Ce compte est déjà lié à un autre profil.';

  @override
  String get onboardingGuestSwitchTitle => 'Continuer en visiteur ?';

  @override
  String get onboardingGuestSwitchBody =>
      'Tu es connecte avec un compte. Continuer en visiteur supprimera ton profil actuel et tu repartiras de zero.';

  @override
  String get onboardingGuestSwitchConfirm => 'Effacer et continuer';

  @override
  String get onboardingGuestSwitchCancel => 'Garder mon compte';

  @override
  String get accountUpgradeSheetTitle => 'Sauvegarder ton compte';

  @override
  String get accountUpgradeSheetBody =>
      'En liant ton compte, tu retrouves ta progression sur n\'importe quel téléphone et tu évites de tout perdre si tu changes d\'appareil.';

  @override
  String get accountUpgradeSuccess => 'Compte sauvegarde ✨';

  @override
  String get onboardingNameTitle => 'Comment tu t\'appelles ?';

  @override
  String get onboardingNameSubtitle => 'Ton prénom (ou un surnom) suffit.';

  @override
  String get onboardingNamePlaceholder => 'Ton prénom';

  @override
  String get onboardingNameTooShort => 'Au moins 2 caracteres.';

  @override
  String get onboardingNameTooLong => 'Maximum 50 caracteres.';

  @override
  String get onboardingPhoneTitle => 'Ton numéro de téléphone';

  @override
  String get onboardingPhoneSubtitle =>
      'Pour te contacter en cas de besoin. Optionnel.';

  @override
  String get onboardingPhoneSkipLabel => 'Passer pour l\'instant';

  @override
  String get onboardingPhoneSkipConfirmTitle => 'Passer cette étape ?';

  @override
  String get onboardingPhoneSkipConfirmMessage =>
      'Tu pourras ajouter ton numéro plus tard depuis ton profil.';

  @override
  String get onboardingPhoneSkipConfirmYes => 'Oui, passer';

  @override
  String get onboardingPhoneSkipConfirmNo => 'Non, ajouter';

  @override
  String get onboardingPhoneInvalid =>
      'Numéro invalide. Format : +237 6XX XXX XXX';

  @override
  String get onboardingSchoolPlaceholder => 'Nom de ton école';

  @override
  String onboardingSchoolAddTemplate(String name) {
    return '+ Ajouter \"$name\"';
  }

  @override
  String get onboardingSchoolOfflineWarning =>
      'Pas de connexion. Tu peux quand meme proposer l\'ajout.';

  @override
  String get onboardingSchoolSkipLabel => 'Passer pour l\'instant';

  @override
  String get onboardingSuccessTitle => 'Bienvenue dans Valide !';

  @override
  String get onboardingSuccessSubtitle => 'Ton profil est pret. On y va ?';

  @override
  String get onboardingSuccessCta => 'Decouvrir mon dashboard';

  @override
  String get onboardingFlushError =>
      'Sauvegarde impossible. Vérifie ta connexion et réessaie.';

  @override
  String get onboardingAuthProviderNotSupported =>
      'Ce compte est lié à un autre service (Apple ou Google). Reconnecte-toi avec le même service que lors de ton inscription.';

  @override
  String get onboardingSuccessDialogTitle => 'Ton compte est cree !';

  @override
  String get onboardingSuccessDialogSubtitle => 'Avec Valide, tu peux :';

  @override
  String get onboardingSuccessBenefit1 =>
      'Suivre ta progression semaine apres semaine';

  @override
  String get onboardingSuccessBenefit2 =>
      'Acceder aux classements de ta classe et ton ecole';

  @override
  String get onboardingSuccessBenefit3 =>
      'Recevoir des exercices adaptes a ton niveau';

  @override
  String get onboardingSuccessDialogCta => 'Commencer';

  @override
  String get onboardingHaveAccount => 'J\'ai un compte';

  @override
  String get onboardingNoAccount => 'Je n\'ai pas encore de compte';

  @override
  String get dashboardTabSettingsCta => 'Paramètres';

  @override
  String get profileSettingsTitle => 'Paramètres';

  @override
  String get profileSettingsAccountSection => 'Mon compte';

  @override
  String get profileSettingsDangerSection => 'Zone de danger';

  @override
  String get profileSettingsDeleteCta => 'Supprimer mon compte';

  @override
  String get profileSettingsDeleteSubtitle =>
      'Cette action est irréversible après 7 jours.';

  @override
  String get profileSettingsVisitorMessage =>
      'Crée d\'abord un compte permanent pour pouvoir le supprimer';

  @override
  String get profileSettingsCreateAccountCta => 'Créer mon compte';

  @override
  String get profileSettingsLinkedAccount => 'Compte lié';

  @override
  String get signOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get signOutConfirmBody =>
      'Tu pourras te reconnecter à tout moment avec ton compte Google ou Apple.';

  @override
  String get signOutConfirmCta => 'Confirmer la déconnexion';

  @override
  String get accountDeletionConfirmTitle => 'Es-tu sûr ?';

  @override
  String get accountDeletionConfirmBody =>
      'Ton compte et toutes tes données seront définitivement supprimés. Cette action est irréversible.';

  @override
  String get accountDeletionConfirmCta => 'Confirmer la suppression';

  @override
  String accountDeletionRequestedToast(String date) {
    return 'Demande enregistrée. Reconnecte-toi avant le $date pour annuler.';
  }

  @override
  String accountDeletionScheduledBanner(String date) {
    return 'Ton compte sera supprimé le $date. Toucher pour annuler.';
  }

  @override
  String get accountDeletionCancelConfirmTitle => 'Annuler la suppression ?';

  @override
  String get accountDeletionCancelConfirmBody =>
      'Ton compte ne sera plus supprimé. Tu peux toujours en demander la suppression plus tard.';

  @override
  String get accountDeletionCancelConfirmCta => 'Oui, annuler la suppression';

  @override
  String get accountDeletionKeepDeletionCta => 'Non, garder la suppression';

  @override
  String get accountDeletionCancelledToast => 'Suppression annulée.';

  @override
  String get accountDeletionAutoCancelledToast =>
      'Ton compte est de nouveau actif.';

  @override
  String get accountDeletionNotAvailableToast =>
      'Fonctionnalité bientôt disponible.';

  @override
  String get accountDeletionRecentLoginToast =>
      'Session expirée. Reconnecte-toi et réessaie.';

  @override
  String get accountDeletionWrongAccountToast =>
      'Ce n\'est pas le bon compte Google. Reconnecte-toi avec le compte lié à cette application.';

  @override
  String get accountDeletionReauthTitle => 'Vérification requise';

  @override
  String get accountDeletionReauthBody =>
      'Ta session a expiré. Reconnecte-toi avec Google pour confirmer la suppression de ton compte.';

  @override
  String get dashboardDailyGoalTitle => 'Objectif du jour';

  @override
  String get dashboardDailyGoalTask => 'Faire 1 quiz + lire 1 leçon';

  @override
  String get dashboardDailyGoalCta => 'Reprendre';

  @override
  String get dashboardHistoryTitle => 'Historique récent';

  @override
  String get dashboardRecommendedTitle => 'Recommandé pour toi';

  @override
  String get dashboardRecommendedAiTag => 'IA personnalisé';

  @override
  String dashboardRecommendedLessonCta(int min) {
    return 'Leçon · $min min';
  }

  @override
  String dashboardRecommendedQuizCta(int count) {
    return 'Quiz · $count q';
  }

  @override
  String get dashboardMySubjectsTitle => 'Mes matières';

  @override
  String get dashboardHeroRankLabel => 'Classement';

  @override
  String get dashboardHeroProgressLabel => 'Progression';

  @override
  String get dashboardObjectivesTitle => 'Objectifs du jour';

  @override
  String get dashboardSubjectLevelPoor => 'Faible';

  @override
  String get dashboardSubjectLevelAverage => 'Moyen';

  @override
  String get dashboardSubjectLevelGood => 'Bon';

  @override
  String get dashboardSeeAll => 'Voir tout';

  @override
  String dashboardHeroSubjectChip(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n matières',
      one: '1 matière',
    );
    return '$_temp0';
  }

  @override
  String get dashboardLevelWeak => 'Faible';

  @override
  String get dashboardLevelMedium => 'Moyen';

  @override
  String get dashboardLevelStrong => 'Fort';

  @override
  String get dashboardRankingTitle => 'Classement';

  @override
  String dashboardRankingWeeklyGain(int n) {
    return '+$n places cette semaine';
  }

  @override
  String dashboardRankingPositionMessage(int rank, String subject) {
    return 'Tu es ${rank}e en $subject. Continue !';
  }

  @override
  String get profileEditButton => 'Modifier';

  @override
  String get profileEditSheetTitle => 'Modifier mon profil';

  @override
  String get profileEditSuccess => 'Profil mis à jour.';

  @override
  String get profileEditSchoolTitle => 'Changer de classe';

  @override
  String get profileEditSchoolLevelLabel => 'Quelle est ta classe ?';

  @override
  String get profileEditSchoolStreamLabel => 'Quelle est ta spécialité ?';

  @override
  String get profileEditSchoolSubjectsLabel => 'Tes matières';

  @override
  String get profileEditSchoolSaving => 'Mise à jour…';

  @override
  String get profileEditNameLabel => 'Prénom ou surnom';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get profileSetupSheetTitle => 'Finalise ton compte';

  @override
  String get profileSetupPhoneLabel => 'Numéro de téléphone (optionnel)';

  @override
  String get profileDeletionPendingTitle => 'Suppression programmée';

  @override
  String profileDeletionPendingSubtitle(String date) {
    return 'Ton compte sera définitivement supprimé le $date. Reconnecte-toi avant cette date pour annuler.';
  }

  @override
  String get profileMenuSchool => 'Mon école';

  @override
  String get profileMenuClass => 'Ma classe';

  @override
  String get profileMenuName => 'Mon nom';

  @override
  String get profileMenuAddName => 'Ajouter mon nom';

  @override
  String get profileMenuPhone => 'Mon numéro';

  @override
  String get profileMenuAddPhone => 'Ajouter mon numéro';

  @override
  String get profileSchoolSheetTitle => 'Changer d\'école';

  @override
  String get profileSchoolUpdateSuccess => 'École mise à jour.';

  @override
  String get profileSchoolRemove => 'Retirer mon école';

  @override
  String get featureComingSoon => 'Bientôt disponible';

  @override
  String get publicProfilePageTitle => 'Profil';

  @override
  String get publicProfileStatsTitle => 'Statistiques';

  @override
  String get publicProfileLessonsRead => 'leçons lues';

  @override
  String get publicProfileQuizPassed => 'quiz réussis';

  @override
  String get publicProfileNotFound => 'Profil introuvable';

  @override
  String get publicProfileNotFoundSubtitle =>
      'Ce profil n\'existe pas ou a été supprimé.';

  @override
  String get quizPageTitle => 'Quiz';

  @override
  String get quizQuitDialogTitle => 'Quitter le quiz ?';

  @override
  String get quizQuitDialogBody => 'Ta progression sera perdue.';

  @override
  String get quizQuitLabel => 'Quitter';

  @override
  String quizProgressLabel(int n, int total) {
    return 'Question $n sur $total';
  }

  @override
  String get quizResultExcellent => 'Excellent !';

  @override
  String get quizResultGoodJob => 'Bon travail !';

  @override
  String get quizResultKeepStudying => 'Continue d\'étudier';

  @override
  String get quizResultReviewLesson => 'Revois le cours !';

  @override
  String quizResultCorrectPct(int pct) {
    return '$pct% de réponses correctes';
  }

  @override
  String get quizResultReviewAnswers => 'Voir mes réponses';

  @override
  String get quizResultReplay => 'Rejouer';

  @override
  String get quizResultBackToCourse => 'Retour au cours';

  @override
  String quizReviewTitle(int score, int total) {
    return 'Mes réponses — $score / $total';
  }

  @override
  String get quizReviewBack => 'Retour au résultat';

  @override
  String get fichePracticeChapter => 'S\'exercer sur ce chapitre';

  @override
  String get ficheTitle => 'Fiche de lecture';

  @override
  String get ficheComingSoon => 'Fiche bientôt disponible';

  @override
  String get tableLabel => 'TABLEAU';

  @override
  String get quizTabTitle => 'Teste tes connaissances';

  @override
  String get quizTabSubtitle => 'Un quiz personnalisé sur ce chapitre';

  @override
  String get quizTabStart => 'Commencer le quiz';

  @override
  String get quizNeedHelp => 'Besoin d\'aide';

  @override
  String get quizSeeResult => 'Voir le résultat';

  @override
  String get quizNextQuestion => 'Question suivante';

  @override
  String get quizNoNotionHint => 'Relis le cours pour retrouver cette notion.';

  @override
  String get quizQuestionsComingSoon => 'Questions bientôt disponibles';

  @override
  String get subjectProgress => 'Progression';

  @override
  String get subjectChaptersLabel => 'CHAPITRES';

  @override
  String subjectTrimesterEyebrow(int n) {
    return 'TRIMESTRE $n';
  }

  @override
  String sequenceTabLabel(int n) {
    return 'S$n';
  }

  @override
  String get performanceLevelGood => 'Bon';

  @override
  String get performanceLevelMedium => 'Moyen';

  @override
  String get performanceLevelWeak => 'À revoir';

  @override
  String lessonLabel(int order) {
    return 'LEÇON $order';
  }

  @override
  String get lessonLinkedQuiz => 'Quiz lié';

  @override
  String lessonReadingTime(int duration) {
    return '$duration min de lecture';
  }

  @override
  String get lessonPractice => 'S\'exercer';

  @override
  String get lessonStartHere => 'Commence par cette leçon';

  @override
  String chapterLessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leçons',
      one: '1 leçon',
    );
    return '$_temp0';
  }

  @override
  String chapterExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercices',
      one: '1 exercice',
    );
    return '$_temp0';
  }

  @override
  String get chapterStudentsLabel => 'élèves';

  @override
  String get chapterTabLessons => 'Leçons';

  @override
  String get chapterTabExercises => 'Exercices';

  @override
  String get lessonsEmptyLabel => 'Aucune leçon disponible';

  @override
  String chapterStudentsUsingCount(int count) {
    return '$count élèves utilisent ce chapitre';
  }

  @override
  String chapterEyebrow(String subjectAbbrev, int chapterOrder) {
    return '$subjectAbbrev · CHAPITRE $chapterOrder';
  }

  @override
  String get chapterExercisesComingSoon => 'Exercices bientôt disponibles';

  @override
  String get chapterFabSummary => 'Résumé';

  @override
  String get chapterFabPractice => 'S\'exercer';

  @override
  String get chaptersEmptyLabel => 'Aucun chapitre disponible';

  @override
  String get imageUnavailableLabel => 'Image indisponible';

  @override
  String get audioUnavailableLabel => 'Audio indisponible';

  @override
  String get calloutDefinition => 'DÉFINITION';

  @override
  String get calloutTheorem => 'THÉORÈME';

  @override
  String get calloutDemonstration => 'DÉMONSTRATION';

  @override
  String get calloutProperty => 'PROPRIÉTÉ';

  @override
  String get calloutMethod => 'MÉTHODE';

  @override
  String get calloutWarning => 'ATTENTION';

  @override
  String get calloutRecap => 'À RETENIR';

  @override
  String get calloutExample => 'EXEMPLE';

  @override
  String get calloutFigure => 'FIGURE';

  @override
  String get calloutNote => 'NOTE';
}
