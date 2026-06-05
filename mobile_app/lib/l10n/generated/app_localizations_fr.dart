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
}
