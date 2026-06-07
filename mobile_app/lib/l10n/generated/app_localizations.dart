import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Nom de l'app affiché dans le titre système (lanceur, multitâche).
  ///
  /// In fr, this message translates to:
  /// **'Valide School'**
  String get appTitle;

  /// Page Hello d'amorçage (sentinelle Epic 0). Affiché en grand sur la home initiale.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {target}'**
  String helloValide(String target);

  /// Bouton principal d'avancement (onboarding, flow).
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// Bouton secondaire qui annule l'action en cours.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelLabel;

  /// Bouton de fermeture d'une modale ou d'un sheet.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeLabel;

  /// Bouton de confirmation neutre dans une alerte.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// Action de navigation arrière.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// Action de navigation vers l'étape suivante.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// Réponse positive à une question oui/non.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get confirmYes;

  /// Réponse négative à une question oui/non.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get confirmNo;

  /// Texte affiché pendant une opération courte (< 3 s).
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loadingLabel;

  /// Texte affiché sur le bouton primaire en état loading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi…'**
  String get sendingLabel;

  /// Texte d'un indicateur en fin de liste paginée.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loadingMore;

  /// Bouton de relance après échec.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryLabel;

  /// Suggestion à l'élève quand l'action ne peut pas aboutir maintenant.
  ///
  /// In fr, this message translates to:
  /// **'Réessaie plus tard'**
  String get tryAgain;

  /// Erreur fourre-tout quand la cause précise n'est pas exposable.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie ?'**
  String get errorGeneric;

  /// Erreur affichée quand le réseau est coupé. Rassure l'élève sur le cache offline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Tu peux continuer ce que tu as ouvert.'**
  String get errorNoConnection;

  /// Toast de confirmation après copie dans le presse-papier.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié.'**
  String get successCopied;

  /// Empty state neutre quand une liste est vide.
  ///
  /// In fr, this message translates to:
  /// **'Rien à afficher pour le moment.'**
  String get emptyStateGeneric;

  /// Titre d'écran 404 (deep link cassé, route inconnue).
  ///
  /// In fr, this message translates to:
  /// **'Page introuvable'**
  String get pageNotFound;

  /// Étiquette au-dessus du sélecteur de langue dans la page Hello sentinelle Story 0.21.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get helloLanguageLabel;

  /// Option français dans le sélecteur de langue.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get helloLanguageFr;

  /// Option anglais dans le sélecteur de langue.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get helloLanguageEn;

  /// Titre de l'écran bloquant affiché quand le catalogue Firestore est vide ET le cache offline est vide (1er lancement offline). Cf. Story 1.1c, UX-DR-24.
  ///
  /// In fr, this message translates to:
  /// **'En attente de connexion'**
  String get catalogueWaitingTitle;

  /// Sous-titre rassurant qui explique pourquoi une connexion est nécessaire au 1er lancement et invite à l'action.
  ///
  /// In fr, this message translates to:
  /// **'Pour démarrer, Valide doit se connecter une première fois. Vérifie ta connexion et réessaie.'**
  String get catalogueWaitingMessage;

  /// CTA primaire pour re-tenter le chargement du catalogue.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get catalogueWaitingRetry;

  /// Titre H2 de la page /onboarding/subsystem (Story 1.2). Tutoiement UX-DR-39.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta langue et ton programme'**
  String get subsystemChoiceTitle;

  /// Sous-titre court qui avertit du caractère immuable du choix (ADR-006).
  ///
  /// In fr, this message translates to:
  /// **'Tu ne pourras pas changer après.'**
  String get subsystemChoiceSubtitle;

  /// Label du bouton qui sélectionne le sous-système francophone (langue FR + curriculum MINESEC).
  ///
  /// In fr, this message translates to:
  /// **'Francophone'**
  String get subsystemFrancophone;

  /// Label du bouton qui sélectionne le sous-système anglophone (langue EN + curriculum Cameroon GCE).
  ///
  /// In fr, this message translates to:
  /// **'Anglophone'**
  String get subsystemAnglophone;

  /// Titre de la modale de confirmation qui s'affiche après tap sur Francophone/Anglophone.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer ton choix'**
  String get subsystemConfirmTitle;

  /// Corps de la modale de confirmation. Explicite l'irréversibilité (ADR-006 conséquence négative #2).
  ///
  /// In fr, this message translates to:
  /// **'Ce choix fixe la langue et le programme. Tu ne pourras pas changer après.'**
  String get subsystemConfirmBody;

  /// Label de progression du flow profil 3 étapes (Story 1.3).
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} sur {total}'**
  String onboardingStepLabel(int step, int total);

  /// Titre H2 de FiliereChoicePage (Story 1.3 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta filière'**
  String get onboardingFiliereTitle;

  /// Libellé filière générale (MINESEC / GCE général).
  ///
  /// In fr, this message translates to:
  /// **'Générale'**
  String get onboardingFiliereGenerale;

  /// Libellé filière technique (STI / STT / autres).
  ///
  /// In fr, this message translates to:
  /// **'Technique'**
  String get onboardingFiliereTechnique;

  /// Titre H2 de NiveauChoicePage (Story 1.3 AC3).
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton niveau'**
  String get onboardingNiveauTitle;

  /// Titre H2 de SerieChoicePage (Story 1.3 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta série'**
  String get onboardingSerieTitle;

  /// Sous-titre court de SerieChoicePage.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne la série qui correspond à ta classe.'**
  String get onboardingSerieSubtitle;

  /// Bandeau bandeau exam target en haut du récap (Story 1.3 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Tu prépares {examName}'**
  String onboardingRecapPrepareLabel(String examName);

  /// Bandeau si DerivedProfile.examTargets vide (ex. 6e francophone).
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'examen visé à ce niveau'**
  String get onboardingRecapNoExamLabel;

  /// Compteur pluralisé de matières dans le récap.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 matière} other{{count} matières}}'**
  String onboardingRecapSubjectsCount(int count);

  /// CTA primaire qui crée le doc users/{uid} Firestore (Story 1.3 AC6).
  ///
  /// In fr, this message translates to:
  /// **'C\'est ma classe'**
  String get onboardingRecapValidateCta;

  /// Lien discret affiché si DerivedProfile.canOptOut. Désactivé en V1, activé en Story 1.4.
  ///
  /// In fr, this message translates to:
  /// **'Retirer une matière'**
  String get onboardingRecapOptOutLink;

  /// Texte du bouton primaire pendant le set() Firestore (loading state).
  ///
  /// In fr, this message translates to:
  /// **'Création de ton profil…'**
  String get onboardingRecapCreatingLabel;

  /// Toast non bloquant si la création doc Firestore échoue (offline ou règles refusent).
  ///
  /// In fr, this message translates to:
  /// **'Profil sauvegardé localement, on retentera en ligne'**
  String get onboardingRecapFirestoreErrorToast;

  /// Message d'erreur si CatalogueFailure.noMatchingRule (Story 1.3 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe trouvée pour ce profil. Reviens en arrière et corrige tes choix.'**
  String get onboardingRecapNoMatchingRule;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
