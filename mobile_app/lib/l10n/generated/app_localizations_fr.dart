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
  String get onboardingPickerObligatoryTitle => 'Matieres obligatoires';

  @override
  String get onboardingPickerOptionalTitle => 'Matieres optionnelles';

  @override
  String get onboardingPickerSeriesTitle => 'Choisis ta série';

  @override
  String get onboardingPickerTransversalesTitle => 'Transversales optionnelles';

  @override
  String get onboardingPickerProfessionalTitle =>
      'Matières professionnelles (obligatoires)';

  @override
  String get onboardingPickerRelatedTitle => 'Matieres connexes';

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
    return 'Bienvenue $name !';
  }

  @override
  String get dashboardWelcomeGuest => 'Bienvenue !';

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
  String get dashboardTabSubjects => 'Matières';

  @override
  String get dashboardTabActivities => 'Activités';

  @override
  String get dashboardTabProfile => 'Profil';

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
      'Programme academique classique (maths, sciences, lettres)';

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
  String onboardingPickerCounter(int count, int max) {
    return '$count/$max selectionnees';
  }

  @override
  String get onboardingPickerValidate => 'Valider mes matières';

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
      'En liant ton compte, tu retrouves ta progression sur n\'importe quel telephone et tu evites de tout perdre si tu changes d\'appareil.';

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
  String get onboardingPhoneTitle => 'Ton numero de telephone';

  @override
  String get onboardingPhoneSubtitle =>
      'Pour te contacter en cas de besoin. Optionnel.';

  @override
  String get onboardingPhoneSkipLabel => 'Passer pour l\'instant';

  @override
  String get onboardingPhoneSkipConfirmTitle => 'Passer cette etape ?';

  @override
  String get onboardingPhoneSkipConfirmMessage =>
      'Tu pourras ajouter ton numero plus tard depuis ton profil.';

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
      'Impossible de sauvegarder ton profil. Reessaie.';
}
