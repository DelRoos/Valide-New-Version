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
  String get subsystemChoiceTitle => 'Choisis ta langue et ton programme';

  @override
  String get subsystemChoiceSubtitle => 'Tu ne pourras pas changer après.';

  @override
  String get subsystemFrancophone => 'Francophone';

  @override
  String get subsystemAnglophone => 'Anglophone';

  @override
  String get subsystemConfirmTitle => 'Confirmer ton choix';

  @override
  String get subsystemConfirmBody =>
      'Ce choix fixe la langue et le programme. Tu ne pourras pas changer après.';

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
  String get onboardingRecapModifyLink => 'Modifier mes matières';
}
