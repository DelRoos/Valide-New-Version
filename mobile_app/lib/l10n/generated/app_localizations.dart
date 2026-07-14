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

  /// Erreur explicite quand FirebaseException code=permission-denied. Cause probable : auth perdu (signOut) ou doc users/{uid} dans un etat incoherent. Action utilisateur : re-lancer l'app force un signInAnonymously frais.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Re-lance l\'app pour rafraîchir.'**
  String get errorPermissionDenied;

  /// Erreur explicite quand FirebaseException code=unavailable ou network-related. Affichee en toast warning.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifie ton réseau et réessaie.'**
  String get errorNetworkUnavailable;

  /// Fallback toast quand FirebaseException avec code non geré (autre que permission-denied / unavailable).
  ///
  /// In fr, this message translates to:
  /// **'Erreur technique. Réessaie dans un instant.'**
  String get errorFirestoreUnknown;

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

  /// Titre H2 de la page /onboarding/subsystem (Story 1.2). Wording MINESEC : 'section' = francophone/anglophone (vs 'programme' qui evoquait la programmation informatique).
  ///
  /// In fr, this message translates to:
  /// **'Tu fais quelle section ?'**
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

  /// Titre de la modale de confirmation qui s'affiche après tap sur Francophone/Anglophone. Wording camerounais : 'section' = francophone/anglophone au MINESEC.
  ///
  /// In fr, this message translates to:
  /// **'Tu fais quelle section ?'**
  String get subsystemConfirmTitle;

  /// Corps de la modale de confirmation. Explicite l'irréversibilité (ADR-006 conséquence négative #2) de manière courte et directe.
  ///
  /// In fr, this message translates to:
  /// **'Choix définitif : langue (FR/EN) + cursus scolaire.'**
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

  /// Toast non bloquant affiché quand l'utilisateur tente d'ouvrir un deep link métier (cours, exercice, dashboard) avec un profil incomplet. Cf. Story 1.5 garde nav profil-incomplet FR-4. RÉSERVÉE pour usage futur (Story 1.9 dashboard ou Epic 2 lessons) — pas appelée par Story 1.5 elle-même.
  ///
  /// In fr, this message translates to:
  /// **'Termine ton profil pour continuer.'**
  String get profileGuardIncompleteToast;

  /// Titre H2 de SubjectsOptOutPage (Story 1.4 FR-3). Tutoiement, ton direct.
  ///
  /// In fr, this message translates to:
  /// **'Choisis tes matières'**
  String get onboardingOptOutTitle;

  /// Sous-titre explicatif de SubjectsOptOutPage (Story 1.4).
  ///
  /// In fr, this message translates to:
  /// **'Décoche celles que tu ne présentes pas.'**
  String get onboardingOptOutSubtitle;

  /// Compteur en bas de SubjectsOptOutPage : N matières cochées sur total. Pluralisé ICU.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Tu présentes 1 matière sur {total}} other{Tu présentes {count} matières sur {total}}}'**
  String onboardingOptOutTakingCount(int count, int total);

  /// Bouton primaire de SubjectsOptOutPage. Disabled si N==0.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get onboardingOptOutValidateCta;

  /// Titre H2 de SubjectsPickerPage mode free_with_obligatory (Story 1.15 FR-3 mode panier O-Level).
  ///
  /// In fr, this message translates to:
  /// **'Choisis tes matières'**
  String get onboardingPickerTitle;

  /// Sous-titre de SubjectsPickerPage mode panier (Story 1.15).
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne les matières que tu présentes à ton examen.'**
  String get onboardingPickerSubtitle;

  /// Story E1bis-3 — Titre section matieres obligatoires picker.
  ///
  /// In fr, this message translates to:
  /// **'Matières obligatoires'**
  String get onboardingPickerObligatoryTitle;

  /// Story E1bis-3 — Titre section matieres optionnelles picker.
  ///
  /// In fr, this message translates to:
  /// **'Matières optionnelles'**
  String get onboardingPickerOptionalTitle;

  /// Story E1bis-3 — Titre section selection serie dans le picker.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta série'**
  String get onboardingPickerSeriesTitle;

  /// Titre H3 section matières transversales optionnelles mode series_plus_optional A-Level (Story 1.16). Computer Science, ICT, Religious Studies, Commerce ajoutables jusqu'à max 5 total.
  ///
  /// In fr, this message translates to:
  /// **'Transversales optionnelles'**
  String get onboardingPickerTransversalesTitle;

  /// Titre H3 section Professional Subjects (lockées) mode tve_picker TVEE (Story 1.17). Ex. pour ELET : Electrotechnique theory, Electrotechnique practical, Electrical machines.
  ///
  /// In fr, this message translates to:
  /// **'Matières professionnelles (obligatoires)'**
  String get onboardingPickerProfessionalTitle;

  /// Story E1bis-3 — Titre section matieres connexes tvePicker.
  ///
  /// In fr, this message translates to:
  /// **'Matières connexes'**
  String get onboardingPickerRelatedTitle;

  /// Titre H3 section Other Subjects mode tve_picker TVEE (Story 1.17). Mix : EN+FR lockées + matières culturelles au choix (Hist/Geo/RS).
  ///
  /// In fr, this message translates to:
  /// **'Autres matières'**
  String get onboardingPickerOtherTitle;

  /// Compteur live mode free_with_obligatory. Couleur primaire si valide, danger sinon (Story 1.15).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Tu présentes 1/{max} matière} other{Tu présentes {count}/{max} matières}}'**
  String onboardingPickerCounterLive(int count, int max);

  /// Toast warning sur tap matière obligatoire (Story 1.15 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Cette matière est obligatoire et ne peut pas être retirée.'**
  String get onboardingPickerErrorObligatoryToast;

  /// Bouton primaire SubjectsPickerPage mode panier. Disabled hors [min, max] (Story 1.15).
  ///
  /// In fr, this message translates to:
  /// **'Valider mon choix'**
  String get onboardingPickerValidateCta;

  /// Lien sur ProfileRecapPage quand optedOutSubjects non vide (Story 1.4). Remplace onboardingRecapOptOutLink quand au moins une matière a déjà été retirée.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mes matières'**
  String get onboardingRecapModifyLink;

  /// Titre H2 AccountCreationPage (Story 1.6 FR-5). Tutoiement, direct.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte'**
  String get onboardingAccountTitle;

  /// Sous-titre explicatif AccountCreationPage (Story 1.6).
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde tes progrès, reprends sur n\'importe quel appareil.'**
  String get onboardingAccountSubtitle;

  /// CTA Google sign-in. Toujours visible, cross-platform (ADR-011).
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get onboardingAccountGoogleCta;

  /// CTA Apple sign-in. Toujours visible, cross-platform (sign_in_with_apple supporte Android via OAuth web).
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get onboardingAccountAppleCta;

  /// CTA secondaire AccountCreationPage : skip la creation de compte Google/Apple et continuer le flow en anonyme (session anonymous Firebase deja active). Le doc users/{uid} est deja cree (Story 1.3), seule la liaison Google/Apple est skippee. L'utilisateur reste anonyme jusqu'a une eventuelle creation de compte ulterieure.
  ///
  /// In fr, this message translates to:
  /// **'Continuer en mode visiteur'**
  String get onboardingAccountGuestCta;

  /// Toast warning si OAuth ou linkWithCredential echoue pour cause reseau (AC6).
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifie ta connexion et réessaie.'**
  String get onboardingAccountNetworkErrorToast;

  /// Titre AlertDialog si credential-already-in-use (AC5). Story 1.6 V1 : flow switch differe en 1.6bis.
  ///
  /// In fr, this message translates to:
  /// **'Compte déjà utilisé'**
  String get onboardingAccountConflictTitle;

  /// Body AlertDialog conflit (AC5). Avertit l'utilisateur de la perte de profil.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est déjà lié à un autre profil Valide. Si tu te connectes avec, tu perdras ton profil actuel.'**
  String get onboardingAccountConflictBody;

  /// Toast info si provider-already-linked (l'utilisateur a deja lie ce provider).
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà un compte.'**
  String get onboardingAccountAlreadyLinkedToast;

  /// Story E1bis-6 — Titre H1 step 8 school search.
  ///
  /// In fr, this message translates to:
  /// **'Tu es dans quelle école ?'**
  String get onboardingSchoolTitle;

  /// Story E1bis-6 — Sous-titre step 8.
  ///
  /// In fr, this message translates to:
  /// **'Recherche ton école. Si elle n\'est pas listée, tu peux la proposer.'**
  String get onboardingSchoolSubtitle;

  /// Placeholder TextField recherche ecole.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher mon école…'**
  String get onboardingSchoolSearchPlaceholder;

  /// Etat vide quand la recherche ne renvoie rien (AC4).
  ///
  /// In fr, this message translates to:
  /// **'Aucune école trouvée pour « {query} ».'**
  String onboardingSchoolEmptyTitle(String query);

  /// CTA primaire dans l'etat vide pour demander l'ajout d'une ecole absente.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter mon école'**
  String get onboardingSchoolAddCta;

  /// Titre de la modale d'ajout d'ecole (AC4).
  ///
  /// In fr, this message translates to:
  /// **'Demander l\'ajout de mon école'**
  String get onboardingSchoolAddDialogTitle;

  /// Label champ Nom (obligatoire) dans la modale d'ajout.
  ///
  /// In fr, this message translates to:
  /// **'Nom de ton école'**
  String get onboardingSchoolAddDialogNameLabel;

  /// Label champ Ville (obligatoire) dans la modale d'ajout.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get onboardingSchoolAddDialogCityLabel;

  /// Label champ Region (optionnel) dans la modale d'ajout.
  ///
  /// In fr, this message translates to:
  /// **'Région (optionnel)'**
  String get onboardingSchoolAddDialogRegionLabel;

  /// Label groupe radio Sous-systeme (Story 1.5.c) dans la modale d'ajout.
  ///
  /// In fr, this message translates to:
  /// **'Sous-système (optionnel)'**
  String get onboardingSchoolAddDialogSubSystemLabel;

  /// Option radio Sous-systeme francophone (Story 1.5.c).
  ///
  /// In fr, this message translates to:
  /// **'Francophone'**
  String get onboardingSchoolAddDialogSubSystemFrancophone;

  /// Option radio Sous-systeme anglophone (Story 1.5.c).
  ///
  /// In fr, this message translates to:
  /// **'Anglophone'**
  String get onboardingSchoolAddDialogSubSystemAnglophone;

  /// Option radio Sous-systeme bilingue/multi-langues (Story 1.5.c).
  ///
  /// In fr, this message translates to:
  /// **'Bilingue'**
  String get onboardingSchoolAddDialogSubSystemBoth;

  /// Option radio par defaut quand l'utilisateur ne connait pas le sous-systeme (Story 1.5.c).
  ///
  /// In fr, this message translates to:
  /// **'Je ne sais pas'**
  String get onboardingSchoolAddDialogSubSystemUnknown;

  /// CTA primaire de la modale d'ajout. Disabled si nom ou ville vides.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get onboardingSchoolAddDialogSubmitCta;

  /// Toast info apres soumission d'une demande d'ajout.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée, on revient vers toi.'**
  String get onboardingSchoolAddRequestSentToast;

  /// Bouton secondaire pleine largeur (AC5).
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape'**
  String get onboardingSchoolSkipCta;

  /// Toast info apres tap Skip (AC5).
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras lier ton école plus tard dans Profil.'**
  String get onboardingSchoolSkipToast;

  /// Badge sur chaque card ecole. Confirme que l'ecole a ete validee par admin.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get onboardingSchoolValidatedBadge;

  /// Toast warning si update schoolId echoue (reseau/rule).
  ///
  /// In fr, this message translates to:
  /// **'Erreur, vérifie ta connexion et réessaie.'**
  String get onboardingSchoolGenericErrorToast;

  /// Titre du Hero DashboardPage avec prenom (Story 2.3 AC1 — remplace 'Bienvenue' Story 1.9). Prenom = displayName.split(' ').first.
  ///
  /// In fr, this message translates to:
  /// **'Salut, {name} 👋'**
  String dashboardWelcomeWithName(String name);

  /// Titre du Hero DashboardPage sans prenom (visiteur ou displayName vide) — Story 2.3 AC1.
  ///
  /// In fr, this message translates to:
  /// **'Salut 👋'**
  String get dashboardWelcomeGuest;

  /// Sous-titre du Hero avec libelle d'examen (Story 1.9 AC1). examLabel = examTargets[0].name[lang].
  ///
  /// In fr, this message translates to:
  /// **'Voici tes matières — tu prépares le {exam}'**
  String dashboardSubtitleWithExam(String exam);

  /// Sous-titre du Hero sans exam (cas 6e francophone ou Form 1 anglophone) — Story 1.9 AC1.
  ///
  /// In fr, this message translates to:
  /// **'Voici tes matières.'**
  String get dashboardSubtitleNoExam;

  /// Badge en haut a droite du Hero quand currentUser.isAnonymous == true (Story 1.9 AC3).
  ///
  /// In fr, this message translates to:
  /// **'Visiteur'**
  String get dashboardGuestBadge;

  /// Texte de l'encadre invite compte en bas du dashboard pour visiteur (Story 1.9 AC3).
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte pour sauvegarder ta progression'**
  String get dashboardGuestInviteText;

  /// Bouton secondaire de l'encadre invite compte → /onboarding/account (Story 1.9 AC3).
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get dashboardGuestInviteCta;

  /// Empty state du dashboard quand effective.data([]) ou derivedProfile.Left — Story 1.9 AC5.
  ///
  /// In fr, this message translates to:
  /// **'Termine ton profil pour voir tes matières.'**
  String get dashboardEmptyStateText;

  /// CTA de l'empty state → /onboarding/profile/filiere (Story 1.9 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Continuer mon onboarding'**
  String get dashboardEmptyStateCta;

  /// Texte affiche sur les PlaceholderTabPage des onglets non implementes V1 + SubjectDetailPlaceholderPage (Story 1.9 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get dashboardComingSoon;

  /// Label onglet 0 du bottom tab bar (Story 1.9 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get dashboardTabHome;

  /// Label onglet 1 du bottom tab bar — contenu cours/matières.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get dashboardTabSubjects;

  /// Titre AppBar de la page Cours (/courses) — liste les matières de l'élève en grille.
  ///
  /// In fr, this message translates to:
  /// **'Mes cours'**
  String get coursesPageTitle;

  /// CTA du banner recommandation sur la page Cours.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get coursesStartLesson;

  /// Titre du banner recommandation — générique jusqu'à implémentation du moteur de recommandation.
  ///
  /// In fr, this message translates to:
  /// **'Reprends là où tu t\'es arrêté'**
  String get coursesRecommendedBannerTitle;

  /// Titre de la section liste des matières sur la tab Cours.
  ///
  /// In fr, this message translates to:
  /// **'Mes matières'**
  String get coursesSectionTitle;

  /// Compteur chapitres terminés/total sur une carte matière.
  ///
  /// In fr, this message translates to:
  /// **'{total, plural, =1{{done}/{total} chapitre} other{{done}/{total} chapitres}}'**
  String coursesChaptersOf(int done, int total);

  /// Chip trimestre courant dans le banner Cours.
  ///
  /// In fr, this message translates to:
  /// **'📚 Trimestre {n}'**
  String coursesTermChip(int n);

  /// Progression chapitres du trimestre.
  ///
  /// In fr, this message translates to:
  /// **'{total, plural, =1{{done} chapitre sur {total} terminé} other{{done} chapitres sur {total} terminés}}'**
  String coursesTermChaptersProgress(int done, int total);

  /// CTA du banner trimestre — ouvre la leçon recommandée par le moteur (mock : première matière tant que le moteur n'est pas branché).
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la leçon'**
  String get coursesTermCtaLabel;

  /// Label onglet 2 du bottom tab bar — révisions et examens.
  ///
  /// In fr, this message translates to:
  /// **'Examen'**
  String get dashboardTabActivities;

  /// Label onglet 3 du bottom tab bar (Story 1.9 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get dashboardTabProfile;

  /// Titre AppBar onglet Examens.
  ///
  /// In fr, this message translates to:
  /// **'Examens'**
  String get examsPageTitle;

  /// Chip exam cible dans le banner countdown.
  ///
  /// In fr, this message translates to:
  /// **'🎯  BAC 2026'**
  String get examsCountdownChip;

  /// Headline du banner countdown (fake, sera dynamique).
  ///
  /// In fr, this message translates to:
  /// **'4 mois restants'**
  String get examsCountdownHeadline;

  /// Sous-titre du banner countdown.
  ///
  /// In fr, this message translates to:
  /// **'Continue à réviser chaque jour'**
  String get examsCountdownSubtitle;

  /// Progression globale de préparation.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% préparé'**
  String examsCountdownPrepared(int pct);

  /// Label 'mois' sous le chiffre de countdown.
  ///
  /// In fr, this message translates to:
  /// **'mois'**
  String get examsCountdownMonths;

  /// Compteur exercices faits/total.
  ///
  /// In fr, this message translates to:
  /// **'{total, plural, =1{{done}/{total} exercice} other{{done}/{total} exercices}}'**
  String examsExercisesOf(int done, int total);

  /// Titre d'un folder séquence sur la tab Examens (S1..S6).
  ///
  /// In fr, this message translates to:
  /// **'Séquence {n}'**
  String examsFolderSequenceTitle(int n);

  /// Chip 'en cours' sur le folder de la séquence pédagogique actuelle.
  ///
  /// In fr, this message translates to:
  /// **'en cours'**
  String get examsFolderSequenceCurrent;

  /// Compteur sujets terminés/total sur un folder séquence.
  ///
  /// In fr, this message translates to:
  /// **'{total, plural, =1{{done}/{total} sujet} other{{done}/{total} sujets}}'**
  String examsFolderSujetsOf(int done, int total);

  /// Compteur annales terminées/total sur le folder Sujets d'examen.
  ///
  /// In fr, this message translates to:
  /// **'{total, plural, =1{{done}/{total} annale} other{{done}/{total} annales}}'**
  String examsFolderAnnalesOf(int done, int total);

  /// Titre du folder 'Sujets d'examen' (annales nationales) pour les classes d'examen (3e/Terminale/GCE).
  ///
  /// In fr, this message translates to:
  /// **'Sujets d\'examen'**
  String get examsFolderExamTitle;

  /// Titre de la section qui contient le folder 'Sujets d'examen'.
  ///
  /// In fr, this message translates to:
  /// **'Autres épreuves'**
  String get examsFolderExamSectionTitle;

  /// Titre du bottom sheet picker matière (déclenché depuis un folder séquence).
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta matière'**
  String get examsMatierePickerTitle;

  /// Placeholder du champ recherche du picker matière (affiché si > 8 matières).
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une matière…'**
  String get examsMatierePickerSearchHint;

  /// État vide du picker matière quand la recherche ne matche rien.
  ///
  /// In fr, this message translates to:
  /// **'Aucune matière ne correspond'**
  String get examsMatierePickerEmpty;

  /// Eyebrow du header de la page Sujets d'examen scopée à une séquence.
  ///
  /// In fr, this message translates to:
  /// **'Séquence {n}'**
  String examSujetsHeaderEyebrow(int n);

  /// Ligne de résumé sous le header : total exercices terminés vs total (tous sujets confondus dans la séquence/matière).
  ///
  /// In fr, this message translates to:
  /// **'{done}/{total} exercices terminés'**
  String examSujetsSummary(int done, int total);

  /// Titre de la section liste des sujets disponibles pour cette (matière, séquence).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} sujet disponible} other{{count} sujets disponibles}}'**
  String examSujetsSectionTitle(int count);

  /// Badge affiché sur une card sujet non commencée.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get examSujetCardMetaNew;

  /// État vide de la page Sujets d'examen.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sujet disponible pour cette séquence'**
  String get examSujetsEmpty;

  /// Label du filtre année sur la page Sujets d'examen.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get examSujetsFilterYearLabel;

  /// Label du filtre école sur la page Sujets d'examen.
  ///
  /// In fr, this message translates to:
  /// **'École'**
  String get examSujetsFilterSchoolLabel;

  /// Chip 'Toutes' pour désactiver un filtre (année ou école).
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get examSujetsFilterAll;

  /// Chip d'école pour les sujets sans source (composition interne, harmonisée, etc.).
  ///
  /// In fr, this message translates to:
  /// **'Non renseignée'**
  String get examSujetsFilterSchoolUnknown;

  /// Label du bouton dropdown 'Toutes les écoles' quand aucun filtre n'est actif.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les écoles'**
  String get examSujetsFilterSchoolAllChip;

  /// Titre du bottom sheet picker école.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par école'**
  String get examSujetsFilterSchoolSheetTitle;

  /// Placeholder du champ recherche dans le picker école.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une école…'**
  String get examSujetsFilterSchoolSheetSearchHint;

  /// État vide du picker école quand la recherche ne matche rien.
  ///
  /// In fr, this message translates to:
  /// **'Aucune école ne correspond'**
  String get examSujetsFilterSchoolSheetEmpty;

  /// Label affiché à droite du slider année : période choisie.
  ///
  /// In fr, this message translates to:
  /// **'{minYear}–{maxYear}'**
  String examSujetsFilterYearRange(int minYear, int maxYear);

  /// Label estampillé au centre du preview quand le sujet est une épreuve officielle (BEPC blanc, BAC blanc, annales MINESEC).
  ///
  /// In fr, this message translates to:
  /// **'EXAMEN'**
  String get examSujetCardExamLabel;

  /// Label court 'moyenne' précédant la note moyenne dans la ligne stats du sujet.
  ///
  /// In fr, this message translates to:
  /// **'moy'**
  String get examSujetCardAvgLabel;

  /// Label 'meilleure note' précédant la note la plus haute obtenue sur ce sujet dans la communauté.
  ///
  /// In fr, this message translates to:
  /// **'meilleure'**
  String get examSujetCardMaxLabel;

  /// Label 'pire note' précédant la note la plus basse obtenue sur ce sujet dans la communauté.
  ///
  /// In fr, this message translates to:
  /// **'pire'**
  String get examSujetCardMinLabel;

  /// Compteur de participants ayant traité le sujet.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun participant pour l\'\'instant} =1{{count} participant} other{{count} participants}}'**
  String examSujetCardParticipantsCount(int count);

  /// Format d'une note affichée sur 20 (échelle scolaire camerounaise).
  ///
  /// In fr, this message translates to:
  /// **'{score}/20'**
  String examSujetCardScoreOver20(String score);

  /// Bouton compact pour effacer tous les filtres actifs (année + école) sur la page Sujets d'examen.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get examSujetsResetFilters;

  /// Titre du tab profil.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profilePageTitle;

  /// Label colonne streak (jours consécutifs) dans les stats profil.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get profileStreak;

  /// Label colonne leçons complétées dans les stats profil.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get profileLessons;

  /// Label colonne score moyen dans les stats profil.
  ///
  /// In fr, this message translates to:
  /// **'Score moy.'**
  String get profileAvgScore;

  /// Unité jours sous le compteur streak.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get profileDays;

  /// Label colonne nombre de matières dans les stats profil.
  ///
  /// In fr, this message translates to:
  /// **'Matières'**
  String get profileSubjects;

  /// Label colonne examens ciblés dans les stats profil.
  ///
  /// In fr, this message translates to:
  /// **'Examens'**
  String get profileExams;

  /// Titre de la section Mon parcours dans le profil.
  ///
  /// In fr, this message translates to:
  /// **'Mon parcours'**
  String get profileSectionCourses;

  /// Titre de la section Réglages dans le profil.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get profileSectionSettings;

  /// Titre de la section Compte dans le profil.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileSectionAccount;

  /// Item menu Mon abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Mon abonnement'**
  String get profileMenuSubscription;

  /// Item menu Mes résultats.
  ///
  /// In fr, this message translates to:
  /// **'Mes résultats'**
  String get profileMenuResults;

  /// Item menu sélection langue.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileMenuLanguage;

  /// Item menu notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get profileMenuNotifications;

  /// Item menu vers /profil/settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get profileMenuAccount;

  /// Item menu déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileMenuSignOut;

  /// Titre bannière guest sur le profil.
  ///
  /// In fr, this message translates to:
  /// **'Continue avec un compte'**
  String get profileGuestTitle;

  /// Sous-titre bannière guest sur le profil.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde ta progression et rejoins le classement.'**
  String get profileGuestSubtitle;

  /// Titre du dialogue non-dismissible affiché aux visiteurs anonymes sur la tab Profil.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mon profil'**
  String get completeProfileDialogTitle;

  /// Corps du dialogue Compléter mon profil.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton profil pour sauvegarder ta progression et accéder à toutes les fonctionnalités.'**
  String get completeProfileDialogBody;

  /// Titre du sélecteur de langue dans le profil.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get languagePickerTitle;

  /// Option langue française dans le sélecteur.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageOptionFrench;

  /// Option langue anglaise dans le sélecteur.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get languageOptionEnglish;

  /// Story E1bis-2bis — Titre H1 step 0 sub-system choice (microcopie alignee template t.sysTitle).
  ///
  /// In fr, this message translates to:
  /// **'Quelle section suis-tu ?'**
  String get onboardingSubSystemTitle;

  /// Story E1bis-2 — Sous-titre step 0 sub-system choice.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton système scolaire pour démarrer.'**
  String get onboardingSubSystemSubtitle;

  /// Story E1bis-2 — Label SelectionCard Francophone step 0.
  ///
  /// In fr, this message translates to:
  /// **'Francophone'**
  String get onboardingSubSystemFrancophone;

  /// Story E1bis-2bis — Description sous le label Francophone, aide l'eleve a se reperer. Audit 2026-06-13 : explicite la plage de niveaux.
  ///
  /// In fr, this message translates to:
  /// **'De la 6ᵉ à la Terminale · BEPC, Probatoire, BAC'**
  String get onboardingSubSystemFrancophoneDesc;

  /// Story E1bis-2 — Label SelectionCard Anglophone step 0.
  ///
  /// In fr, this message translates to:
  /// **'Anglophone'**
  String get onboardingSubSystemAnglophone;

  /// Story E1bis-2bis — Description sous le label Anglophone, aide l'eleve a se reperer. Audit 2026-06-13 : explicite la plage de niveaux.
  ///
  /// In fr, this message translates to:
  /// **'De Form 1 à Upper Sixth · GCE O-Level, A-Level'**
  String get onboardingSubSystemAnglophoneDesc;

  /// Story E1bis-2 — Label CTA OnboardingCtaFooter step 0.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get onboardingContinue;

  /// Story E1bis-2 — Titre display step 1 hero intro.
  ///
  /// In fr, this message translates to:
  /// **'Apprends à ton rythme, à ton niveau.'**
  String get heroIntroTitle;

  /// Story E1bis-2 — Sous-titre step 1 hero intro.
  ///
  /// In fr, this message translates to:
  /// **'Cours, exercices, et un assistant IA toujours disponible.'**
  String get heroIntroSubtitle;

  /// Story E1bis-2 — Feature card 1 titre (Cours).
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get heroIntroFeatureCoursesTitle;

  /// Story E1bis-2 — Feature card 1 description.
  ///
  /// In fr, this message translates to:
  /// **'Tout le programme, expliqué simplement.'**
  String get heroIntroFeatureCoursesDesc;

  /// Story E1bis-2 — Feature card 2 titre (Exercices).
  ///
  /// In fr, this message translates to:
  /// **'Exercices'**
  String get heroIntroFeatureExercisesTitle;

  /// Story E1bis-2 — Feature card 2 description.
  ///
  /// In fr, this message translates to:
  /// **'Entraîne-toi avec correction immédiate.'**
  String get heroIntroFeatureExercisesDesc;

  /// Story E1bis-2 — Feature card 3 titre (Chat IA).
  ///
  /// In fr, this message translates to:
  /// **'Chat IA'**
  String get heroIntroFeatureChatTitle;

  /// Story E1bis-2 — Feature card 3 description.
  ///
  /// In fr, this message translates to:
  /// **'Pose toutes tes questions, à toute heure.'**
  String get heroIntroFeatureChatDesc;

  /// Story E1bis-2 — Label CTA OnboardingCtaFooter step 1 hero intro.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti'**
  String get heroIntroCta;

  /// Story E1bis-3 — Titre H1 step 2 track choice (Generale / Technique).
  ///
  /// In fr, this message translates to:
  /// **'Quelle filière suis-tu ?'**
  String get onboardingTrackTitle;

  /// Story E1bis-3 — Sous-titre step 2 track choice.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le type d\'enseignement que tu veux suivre.'**
  String get onboardingTrackSubtitle;

  /// Story E1bis-3 — Description sous SelectionCard track generale.
  ///
  /// In fr, this message translates to:
  /// **'Programme académique classique (maths, sciences, lettres)'**
  String get onboardingTrackHintGeneral;

  /// Story E1bis-3 — Description sous SelectionCard track technique.
  ///
  /// In fr, this message translates to:
  /// **'Programme professionnel (industriel, commercial, tertiaire)'**
  String get onboardingTrackHintTechnique;

  /// Story E1bis-3 — Titre H1 step 3 level choice.
  ///
  /// In fr, this message translates to:
  /// **'Tu es en quelle classe ?'**
  String get onboardingLevelTitle;

  /// Story E1bis-3 — Sous-titre step 3 level choice.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne ton niveau actuel pour adapter le contenu.'**
  String get onboardingLevelSubtitle;

  /// Audit 2026-06-14 — Titre H1 step 4 vue derived (recap). Avant : 'Quelles matieres etudies-tu ?' qui sous-entendait une selection ; maintenant le user ne choisit plus les matieres, c'est purement un resume de la classe + matieres derivees.
  ///
  /// In fr, this message translates to:
  /// **'Ta classe'**
  String get onboardingStreamSubjectsTitle;

  /// Audit 2026-06-14 — Sous-titre step 4 vue derived, factuel + bienveillant.
  ///
  /// In fr, this message translates to:
  /// **'Voici les matières que tu vas étudier.'**
  String get onboardingStreamSubjectsSubtitle;

  /// Audit 2026-06-14 — Label pour la ligne sub-system dans le recap banner step 4.
  ///
  /// In fr, this message translates to:
  /// **'Section'**
  String get onboardingRecapLabelSection;

  /// Audit 2026-06-14 — Label pour la ligne track dans le recap banner step 4.
  ///
  /// In fr, this message translates to:
  /// **'Filière'**
  String get onboardingRecapLabelTrack;

  /// Audit 2026-06-14 — Label pour la ligne level dans le recap banner step 4.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get onboardingRecapLabelLevel;

  /// Audit 2026-06-14 — Label pour la ligne stream/serie dans le recap banner step 4.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get onboardingRecapLabelStream;

  /// Audit 2026-06-14 — Label pour la ligne examen(s) vise(s) dans le recap banner step 4 (BAC, BEPC, Probatoire, GCE...).
  ///
  /// In fr, this message translates to:
  /// **'Examen'**
  String get onboardingRecapLabelExam;

  /// Audit BUG-01 — Titre fallback affiche quand le catalogue Firestore ne contient aucune serie pour le niveau choisi (probable desync seed).
  ///
  /// In fr, this message translates to:
  /// **'Aucune série disponible'**
  String get onboardingStreamPickerEmptyTitle;

  /// Audit BUG-01 — Body fallback streams.length==0.
  ///
  /// In fr, this message translates to:
  /// **'Pour ce niveau, aucune série n\'est encore configurée. Essaie un autre niveau, ou réessaie dans quelques minutes.'**
  String get onboardingStreamPickerEmptyBody;

  /// Audit BUG-01 — CTA retry fallback streams empty.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get onboardingStreamPickerEmptyRetry;

  /// Audit 2026-06-14 — CTA primaire empty state : revient au step 3 (level choice). Couvre le cas du draft stale (levelId persiste qui n'existe plus dans le catalogue actuel) ou le cas seed gap legitime.
  ///
  /// In fr, this message translates to:
  /// **'Changer de niveau'**
  String get onboardingStreamPickerEmptyChangeLevel;

  /// Audit 2026-06-14 — Titre fallback step 3 quand trackId pose mais 0 niveaux actifs match. Cas : anglo + technique (TVE non seede en MVP).
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe pour cette filière'**
  String get onboardingLevelEmptyForTrackTitle;

  /// Audit 2026-06-14 — Body fallback step 3 trackId set + 0 niveaux. Guide vers back step 2.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe n\'est encore disponible pour cette filière. Change de filière pour continuer.'**
  String get onboardingLevelEmptyForTrackBody;

  /// Audit 2026-06-14 — CTA primaire qui fait notifier.back() (step 3 -> 2).
  ///
  /// In fr, this message translates to:
  /// **'Changer de filière'**
  String get onboardingLevelEmptyForTrackChangeTrack;

  /// Audit BUG-03 — Texte affiche sous le spinner pendant le fetch du catalogue Firestore.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get onboardingLoaderLabel;

  /// No description provided for @onboardingGroupLv2.
  ///
  /// In fr, this message translates to:
  /// **'Langue Vivante 2'**
  String get onboardingGroupLv2;

  /// No description provided for @onboardingGroupLv3.
  ///
  /// In fr, this message translates to:
  /// **'Langue Vivante 3'**
  String get onboardingGroupLv3;

  /// No description provided for @onboardingGroupOlevelOptions.
  ///
  /// In fr, this message translates to:
  /// **'Matière O-Level'**
  String get onboardingGroupOlevelOptions;

  /// No description provided for @onboardingGroupAlevelOptions.
  ///
  /// In fr, this message translates to:
  /// **'Matière A-Level'**
  String get onboardingGroupAlevelOptions;

  /// No description provided for @onboardingGroupGeneric.
  ///
  /// In fr, this message translates to:
  /// **'matière'**
  String get onboardingGroupGeneric;

  /// No description provided for @onboardingGroupPickHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisis 1'**
  String get onboardingGroupPickHint;

  /// Story E1bis-3 — Hint section optionnelles (ex: Choisis jusqu'à 3).
  ///
  /// In fr, this message translates to:
  /// **'Choisis jusqu\'à {count}'**
  String onboardingPickerChooseUpTo(int count);

  /// Story E1bis-3 — Badge compteur picker (ex. 6/11 selectionnees).
  ///
  /// In fr, this message translates to:
  /// **'{count}/{max} sélectionnées'**
  String onboardingPickerCounter(int count, int max);

  /// Story E1bis-3 — Label CTA validation picker.
  ///
  /// In fr, this message translates to:
  /// **'Valider mes matières'**
  String get onboardingPickerValidate;

  /// Story E1bis-3 — CTA final step 4 : crée un compte anonyme et navigue vers le dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Commencer à réviser'**
  String get onboardingStartRevising;

  /// Story E1bis-3 — Message erreur chargement catalogue Firestore.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le catalogue. Vérifie ta connexion et réessaie.'**
  String get errorCatalogueLoading;

  /// Story E1bis-3 — Message erreur catalogue vide (cas marginal).
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnee disponible. Reessaie plus tard.'**
  String get errorCatalogueEmpty;

  /// Titre H2 de l'ecran ErrorRetryView quand le device est hors ligne.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion'**
  String get errorOfflineTitle;

  /// Titre H2 de l'ecran ErrorRetryView quand une lecture serveur echoue.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible'**
  String get errorLoadingTitle;

  /// Titre H2 de l'ecran ErrorRetryView pour les erreurs generiques non identifiees.
  ///
  /// In fr, this message translates to:
  /// **'Oups, quelque chose a coince'**
  String get errorGenericTitle;

  /// Texte du bandeau global offline affiche en haut de l'app tant que la connectivite est absente.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get offlineBannerMessage;

  /// Story E1bis-4 — Titre H1 step 5 auth choice.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte'**
  String get onboardingAuthTitle;

  /// Story E1bis-4 — Sous-titre step 5.
  ///
  /// In fr, this message translates to:
  /// **'Une seule étape pour sauvegarder ton progrès et ton profil.'**
  String get onboardingAuthSubtitle;

  /// Story E1bis-4 — Bouton OAuth Google.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get onboardingAuthGoogleLabel;

  /// Story E1bis-4 — Bouton OAuth Apple (iOS seulement).
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get onboardingAuthAppleLabel;

  /// Story E1bis-4 — Separateur visuel entre OAuth et visiteur.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get onboardingAuthOrLabel;

  /// Story E1bis-4 — Bouton visiteur (signInAnonymously).
  ///
  /// In fr, this message translates to:
  /// **'Continuer en visiteur'**
  String get onboardingAuthGuestLabel;

  /// Story E1bis-4 — Message erreur user cancel OAuth.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulee.'**
  String get onboardingAuthErrorCanceled;

  /// Story E1bis-4 — Message erreur credential-already-in-use.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est déjà lié à un autre profil.'**
  String get onboardingAuthErrorConflict;

  /// Audit PR2 — Titre modale de confirmation quand l'user authentifie tape Continuer en visiteur.
  ///
  /// In fr, this message translates to:
  /// **'Continuer en visiteur ?'**
  String get onboardingGuestSwitchTitle;

  /// Audit PR2 — Body modale de confirmation switch OAuth -> Visiteur.
  ///
  /// In fr, this message translates to:
  /// **'Tu es connecte avec un compte. Continuer en visiteur supprimera ton profil actuel et tu repartiras de zero.'**
  String get onboardingGuestSwitchBody;

  /// Audit PR2 — CTA destructive modale switch visiteur.
  ///
  /// In fr, this message translates to:
  /// **'Effacer et continuer'**
  String get onboardingGuestSwitchConfirm;

  /// Audit PR2 — CTA annulation modale switch visiteur.
  ///
  /// In fr, this message translates to:
  /// **'Garder mon compte'**
  String get onboardingGuestSwitchCancel;

  /// Audit PR5 — Titre bottomsheet upgrade visiteur -> compte permanent.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder ton compte'**
  String get accountUpgradeSheetTitle;

  /// Audit PR5 — Body bottomsheet upgrade.
  ///
  /// In fr, this message translates to:
  /// **'En liant ton compte, tu retrouves ta progression sur n\'importe quel téléphone et tu évites de tout perdre si tu changes d\'appareil.'**
  String get accountUpgradeSheetBody;

  /// Audit PR5 — Snackbar success upgrade.
  ///
  /// In fr, this message translates to:
  /// **'Compte sauvegarde ✨'**
  String get accountUpgradeSuccess;

  /// Story E1bis-5 — Titre H1 step 6 name input.
  ///
  /// In fr, this message translates to:
  /// **'Comment tu t\'appelles ?'**
  String get onboardingNameTitle;

  /// Story E1bis-5 — Sous-titre step 6.
  ///
  /// In fr, this message translates to:
  /// **'Ton prénom (ou un surnom) suffit.'**
  String get onboardingNameSubtitle;

  /// Story E1bis-5 — Placeholder input nom.
  ///
  /// In fr, this message translates to:
  /// **'Ton prénom'**
  String get onboardingNamePlaceholder;

  /// Story E1bis-5 — Erreur validation < 2 chars.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 2 caracteres.'**
  String get onboardingNameTooShort;

  /// Story E1bis-5 — Erreur validation > 50 chars.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 50 caracteres.'**
  String get onboardingNameTooLong;

  /// Story E1bis-5 — Titre H1 step 7 phone input.
  ///
  /// In fr, this message translates to:
  /// **'Ton numéro de téléphone'**
  String get onboardingPhoneTitle;

  /// Story E1bis-5 — Sous-titre step 7.
  ///
  /// In fr, this message translates to:
  /// **'Pour te contacter en cas de besoin. Optionnel.'**
  String get onboardingPhoneSubtitle;

  /// Story E1bis-5 — Bouton skip step 7.
  ///
  /// In fr, this message translates to:
  /// **'Passer pour l\'instant'**
  String get onboardingPhoneSkipLabel;

  /// Story E1bis-5 — Titre dialog skip phone.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape ?'**
  String get onboardingPhoneSkipConfirmTitle;

  /// Story E1bis-5 — Message dialog skip phone.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras ajouter ton numéro plus tard depuis ton profil.'**
  String get onboardingPhoneSkipConfirmMessage;

  /// Story E1bis-5 — CTA confirm skip phone.
  ///
  /// In fr, this message translates to:
  /// **'Oui, passer'**
  String get onboardingPhoneSkipConfirmYes;

  /// Story E1bis-5 — CTA refuser skip phone.
  ///
  /// In fr, this message translates to:
  /// **'Non, ajouter'**
  String get onboardingPhoneSkipConfirmNo;

  /// Story E1bis-5 — Erreur validation numero.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide. Format : +237 6XX XXX XXX'**
  String get onboardingPhoneInvalid;

  /// Story E1bis-6 — Placeholder champ recherche ecole.
  ///
  /// In fr, this message translates to:
  /// **'Nom de ton école'**
  String get onboardingSchoolPlaceholder;

  /// Story E1bis-6 — Template CTA ajouter ecole custom.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter \"{name}\"'**
  String onboardingSchoolAddTemplate(String name);

  /// Story E1bis-6 — Bandeau warning offline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Tu peux quand meme proposer l\'ajout.'**
  String get onboardingSchoolOfflineWarning;

  /// Story E1bis-6 — Bouton skip step 8.
  ///
  /// In fr, this message translates to:
  /// **'Passer pour l\'instant'**
  String get onboardingSchoolSkipLabel;

  /// Story E1bis-7 — Titre celebration step 9.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Valide !'**
  String get onboardingSuccessTitle;

  /// Story E1bis-7 — Sous-titre celebration.
  ///
  /// In fr, this message translates to:
  /// **'Ton profil est pret. On y va ?'**
  String get onboardingSuccessSubtitle;

  /// Story E1bis-7 — CTA fin celebration.
  ///
  /// In fr, this message translates to:
  /// **'Decouvrir mon dashboard'**
  String get onboardingSuccessCta;

  /// Story E1bis-7 — Erreur ecriture Firestore.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde impossible. Vérifie ta connexion et réessaie.'**
  String get onboardingFlushError;

  /// Bug 5 — Utilisateur Apple qui tente de se connecter Google sur Android, ou vice-versa.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est lié à un autre service (Apple ou Google). Reconnecte-toi avec le même service que lors de ton inscription.'**
  String get onboardingAuthProviderNotSupported;

  /// Story E1bis-7 — Titre dialog benefices compte.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est cree !'**
  String get onboardingSuccessDialogTitle;

  /// Story E1bis-7 — Sous-titre dialog benefices.
  ///
  /// In fr, this message translates to:
  /// **'Avec Valide, tu peux :'**
  String get onboardingSuccessDialogSubtitle;

  /// Story E1bis-7 — Benefice 1 dialog succes.
  ///
  /// In fr, this message translates to:
  /// **'Suivre ta progression semaine apres semaine'**
  String get onboardingSuccessBenefit1;

  /// Story E1bis-7 — Benefice 2 dialog succes.
  ///
  /// In fr, this message translates to:
  /// **'Acceder aux classements de ta classe et ton ecole'**
  String get onboardingSuccessBenefit2;

  /// Story E1bis-7 — Benefice 3 dialog succes.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des exercices adaptes a ton niveau'**
  String get onboardingSuccessBenefit3;

  /// Story E1bis-7 — CTA dialog benefices.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingSuccessDialogCta;

  /// Step 0 — bouton principal pour un utilisateur qui reinstalle sur un nouveau telephone.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un compte'**
  String get onboardingHaveAccount;

  /// Step 1 — CTA principal pour demarrer l'onboarding classique.
  ///
  /// In fr, this message translates to:
  /// **'Je n\'ai pas encore de compte'**
  String get onboardingNoAccount;

  /// Bouton secondaire sur le placeholder de l'onglet Profil qui nav vers /profil/settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get dashboardTabSettingsCta;

  /// Titre AppBar ProfileSettingsPage (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profileSettingsTitle;

  /// Titre de la section info compte sur ProfileSettingsPage (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get profileSettingsAccountSection;

  /// Titre de la section danger zone (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Zone de danger'**
  String get profileSettingsDangerSection;

  /// CTA danger qui ouvre la modale de confirmation suppression (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get profileSettingsDeleteCta;

  /// Texte explicatif sous la section danger zone (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible après 7 jours.'**
  String get profileSettingsDeleteSubtitle;

  /// Message info affiché aux visiteurs Anonymous Auth (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Crée d\'abord un compte permanent pour pouvoir le supprimer'**
  String get profileSettingsVisitorMessage;

  /// Bouton secondary pour visiteur vers /onboarding/account (Story 1.10 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get profileSettingsCreateAccountCta;

  /// Fallback affiché dans la section Mon compte quand l'email n'est pas disponible (Apple Sign-In email masqué).
  ///
  /// In fr, this message translates to:
  /// **'Compte lié'**
  String get profileSettingsLinkedAccount;

  /// Titre du dialog de confirmation de déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get signOutConfirmTitle;

  /// Corps du dialog de confirmation de déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras te reconnecter à tout moment avec ton compte Google ou Apple.'**
  String get signOutConfirmBody;

  /// Bouton danger dans le dialog de confirmation déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la déconnexion'**
  String get signOutConfirmCta;

  /// Titre AlertDialog de confirmation suppression (Story 1.10 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Es-tu sûr ?'**
  String get accountDeletionConfirmTitle;

  /// Corps AlertDialog confirmation suppression immédiate (irréversible).
  ///
  /// In fr, this message translates to:
  /// **'Ton compte et toutes tes données seront définitivement supprimés. Cette action est irréversible.'**
  String get accountDeletionConfirmBody;

  /// Bouton danger dans la modale confirmation (Story 1.10 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get accountDeletionConfirmCta;

  /// Toast info apres succes requestAccountDeletion (Story 1.10 AC4). {date} = J+7 format DD/MM/YYYY.
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée. Reconnecte-toi avant le {date} pour annuler.'**
  String accountDeletionRequestedToast(String date);

  /// Texte banner warning sur DashboardPage si deletionRequestedAt non null (Story 1.10 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera supprimé le {date}. Toucher pour annuler.'**
  String accountDeletionScheduledBanner(String date);

  /// Titre AlertDialog d'annulation suppression depuis banner dashboard (Story 1.10 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression ?'**
  String get accountDeletionCancelConfirmTitle;

  /// Corps AlertDialog annulation (Story 1.10 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Ton compte ne sera plus supprimé. Tu peux toujours en demander la suppression plus tard.'**
  String get accountDeletionCancelConfirmBody;

  /// Bouton primary qui déclenche cancelAccountDeletion (Story 1.10 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler la suppression'**
  String get accountDeletionCancelConfirmCta;

  /// Bouton secondary qui ferme la modale sans annuler (Story 1.10 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Non, garder la suppression'**
  String get accountDeletionKeepDeletionCta;

  /// Toast info apres succes manuel cancelAccountDeletion (Story 1.10 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Suppression annulée.'**
  String get accountDeletionCancelledToast;

  /// Toast info apres auto-cancel au boot (Story 1.10 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est de nouveau actif.'**
  String get accountDeletionAutoCancelledToast;

  /// Toast warning si Cloud Function non deployée côté backend (Story 1.10 fallback graceful).
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité bientôt disponible.'**
  String get accountDeletionNotAvailableToast;

  /// Toast warning quand Firebase Auth exige une re-authentification récente avant deleteAccountNow.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Reconnecte-toi et réessaie.'**
  String get accountDeletionRecentLoginToast;

  /// Toast warning quand l'utilisateur se reconnecte avec un mauvais compte Google lors du reauth (user-mismatch).
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas le bon compte Google. Reconnecte-toi avec le compte lié à cette application.'**
  String get accountDeletionWrongAccountToast;

  /// Titre de la modale de re-authentification avant suppression de compte.
  ///
  /// In fr, this message translates to:
  /// **'Vérification requise'**
  String get accountDeletionReauthTitle;

  /// Corps de la modale de re-authentification avant suppression (requiresRecentLogin).
  ///
  /// In fr, this message translates to:
  /// **'Ta session a expiré. Reconnecte-toi avec Google pour confirmer la suppression de ton compte.'**
  String get accountDeletionReauthBody;

  /// Titre de la section Objectif du jour du dashboard (Story 2.3 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Objectif du jour'**
  String get dashboardDailyGoalTitle;

  /// Description de la tâche quotidienne hardcodée (Story 2.3 AC2 — remplacée par Firestore en Story 2.4).
  ///
  /// In fr, this message translates to:
  /// **'Faire 1 quiz + lire 1 leçon'**
  String get dashboardDailyGoalTask;

  /// Bouton CTA de l'objectif du jour (Story 2.3 AC2).
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get dashboardDailyGoalCta;

  /// Titre de la section Historique récent du dashboard (Story 2.3 AC3).
  ///
  /// In fr, this message translates to:
  /// **'Historique récent'**
  String get dashboardHistoryTitle;

  /// Titre de la section Recommandé IA du dashboard (Story 2.3 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Recommandé pour toi'**
  String get dashboardRecommendedTitle;

  /// Badge tag IA sur la carte Recommandé (Story 2.3 AC4).
  ///
  /// In fr, this message translates to:
  /// **'IA personnalisé'**
  String get dashboardRecommendedAiTag;

  /// CTA secondaire Leçon sur la carte Recommandé (Story 2.3 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Leçon · {min} min'**
  String dashboardRecommendedLessonCta(int min);

  /// CTA secondaire Quiz sur la carte Recommandé (Story 2.3 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Quiz · {count} q'**
  String dashboardRecommendedQuizCta(int count);

  /// Titre de la section Mes matières du dashboard enrichi (Story 2.3 AC5 — remplace onboardingRecapSubjectsCount).
  ///
  /// In fr, this message translates to:
  /// **'Mes matières'**
  String get dashboardMySubjectsTitle;

  /// Label de la stat classement dans le hero dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get dashboardHeroRankLabel;

  /// Label de la stat progression globale dans le hero dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get dashboardHeroProgressLabel;

  /// Titre de la section objectifs quotidiens sur le dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs du jour'**
  String get dashboardObjectivesTitle;

  /// Niveau de maîtrise faible affiché sur la tuile matière.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get dashboardSubjectLevelPoor;

  /// Niveau de maîtrise moyen affiché sur la tuile matière.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get dashboardSubjectLevelAverage;

  /// Niveau de maîtrise bon affiché sur la tuile matière.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get dashboardSubjectLevelGood;

  /// Lien 'Voir tout' à droite du titre d'une section du dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get dashboardSeeAll;

  /// Chip nombre de matières dans le hero du dashboard.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 matière} other{{n} matières}}'**
  String dashboardHeroSubjectChip(int n);

  /// Badge niveau faible (0-33%) sur les cartes matières du dashboard (Story 2.3 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get dashboardLevelWeak;

  /// Badge niveau moyen (34-66%) sur les cartes matières du dashboard (Story 2.3 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get dashboardLevelMedium;

  /// Badge niveau fort (67-100%) sur les cartes matières du dashboard (Story 2.3 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get dashboardLevelStrong;

  /// Titre de la section Classement du dashboard (Story 2.3 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get dashboardRankingTitle;

  /// Texte gain hebdomadaire dans la section Classement (Story 2.3 AC6).
  ///
  /// In fr, this message translates to:
  /// **'+{n} places cette semaine'**
  String dashboardRankingWeeklyGain(int n);

  /// Message de rang dans la section Classement du dashboard (Story 2.3 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Tu es {rank}e en {subject}. Continue !'**
  String dashboardRankingPositionMessage(int rank, String subject);

  /// Bouton 'Modifier' sur le ProfileHeader pour ouvrir le sheet d'édition du profil (Story A.1 AC1).
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get profileEditButton;

  /// Titre du bottom sheet d'édition displayName + téléphone (Story A.1 AC1).
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get profileEditSheetTitle;

  /// Toast succès après sauvegarde du nom et/ou téléphone (Story A.1 AC5).
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour.'**
  String get profileEditSuccess;

  /// Titre du bottom sheet d'édition du profil scolaire (Story A.3).
  ///
  /// In fr, this message translates to:
  /// **'Changer de classe'**
  String get profileEditSchoolTitle;

  /// Label étape 1 (sélection du niveau) du sheet édition profil scolaire (Story A.3).
  ///
  /// In fr, this message translates to:
  /// **'Quelle est ta classe ?'**
  String get profileEditSchoolLevelLabel;

  /// Label étape 2 (sélection de la série) du sheet édition profil scolaire (Story A.3).
  ///
  /// In fr, this message translates to:
  /// **'Quelle est ta spécialité ?'**
  String get profileEditSchoolStreamLabel;

  /// Label étape 3 (récap/ajustement matières) du sheet édition profil scolaire (Story A.3).
  ///
  /// In fr, this message translates to:
  /// **'Tes matières'**
  String get profileEditSchoolSubjectsLabel;

  /// Label bouton pendant sauvegarde du profil scolaire (Story A.3).
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour…'**
  String get profileEditSchoolSaving;

  /// Label du champ nom dans le bottom sheet d'édition du profil.
  ///
  /// In fr, this message translates to:
  /// **'Prénom ou surnom'**
  String get profileEditNameLabel;

  /// Label générique du bouton de sauvegarde dans les formulaires d'édition.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveLabel;

  /// Titre du sheet de complétion de profil affiché après linkage Google/Apple (nom + téléphone).
  ///
  /// In fr, this message translates to:
  /// **'Finalise ton compte'**
  String get profileSetupSheetTitle;

  /// Label de la section téléphone dans le ProfileSetupSheet post-linking.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone (optionnel)'**
  String get profileSetupPhoneLabel;

  /// Titre de la bannière d'alerte quand deletionRequestedAt est posé sur le compte.
  ///
  /// In fr, this message translates to:
  /// **'Suppression programmée'**
  String get profileDeletionPendingTitle;

  /// Corps de la bannière suppression en attente. {date} = J+7 format DD/MM/YYYY.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera définitivement supprimé le {date}. Reconnecte-toi avant cette date pour annuler.'**
  String profileDeletionPendingSubtitle(String date);

  /// Item menu 'Mon école' dans la section Compte du profil — ouvre le sheet de changement d'école (Story A.1 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Mon école'**
  String get profileMenuSchool;

  /// Item menu 'Ma classe' dans la section Compte du profil — ouvre SchoolProfileEditSheet (Story A.3).
  ///
  /// In fr, this message translates to:
  /// **'Ma classe'**
  String get profileMenuClass;

  /// Label item menu nom dans la section Compte — affiché en permanence, valeur en sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Mon nom'**
  String get profileMenuName;

  /// Sous-titre item menu nom quand displayName est absent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter mon nom'**
  String get profileMenuAddName;

  /// Label item menu numéro dans la section Compte — affiché en permanence, valeur en sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Mon numéro'**
  String get profileMenuPhone;

  /// Sous-titre item menu numéro quand phoneNumber est absent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter mon numéro'**
  String get profileMenuAddPhone;

  /// Titre du bottom sheet de recherche/changement d'école (Story A.1 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'école'**
  String get profileSchoolSheetTitle;

  /// Toast succès après changement d'école (Story A.1 AC6).
  ///
  /// In fr, this message translates to:
  /// **'École mise à jour.'**
  String get profileSchoolUpdateSuccess;

  /// Bouton secondaire dans le sheet d'école pour retirer l'école liée (Story A.1 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Retirer mon école'**
  String get profileSchoolRemove;

  /// Toast info affiché quand un item de menu non implémenté est touché (Story A.1 AC7 — stubs).
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get featureComingSoon;

  /// Titre de la page profil public (utilisé dans l'AppBar / _BackBar sur les states erreur ou not-found).
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get publicProfilePageTitle;

  /// Titre de la section stats sur la page profil public d'un pair (Story A.2 AC4).
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get publicProfileStatsTitle;

  /// Unité du badge leçons lues sur le profil public (Story A.2 AC4).
  ///
  /// In fr, this message translates to:
  /// **'leçons lues'**
  String get publicProfileLessonsRead;

  /// Unité du badge quiz réussis sur le profil public (Story A.2 AC4).
  ///
  /// In fr, this message translates to:
  /// **'quiz réussis'**
  String get publicProfileQuizPassed;

  /// Titre état vide quand le doc Firestore users/{uid} n'existe pas (Story A.2 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Profil introuvable'**
  String get publicProfileNotFound;

  /// Sous-titre état vide profil introuvable (Story A.2 AC7).
  ///
  /// In fr, this message translates to:
  /// **'Ce profil n\'existe pas ou a été supprimé.'**
  String get publicProfileNotFoundSubtitle;

  /// Titre de la page quiz (AppBar).
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get quizPageTitle;

  /// Titre du dialog de confirmation de sortie du quiz.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le quiz ?'**
  String get quizQuitDialogTitle;

  /// Corps du dialog de sortie du quiz.
  ///
  /// In fr, this message translates to:
  /// **'Ta progression sera perdue.'**
  String get quizQuitDialogBody;

  /// Bouton danger pour quitter le quiz et perdre la progression.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quizQuitLabel;

  /// Compteur de progression affiché sous l'AppBar du quiz.
  ///
  /// In fr, this message translates to:
  /// **'Question {n} sur {total}'**
  String quizProgressLabel(int n, int total);

  /// Titre de résultat quand le score est ≥ 80%.
  ///
  /// In fr, this message translates to:
  /// **'Excellent !'**
  String get quizResultExcellent;

  /// Titre de résultat quand le score est entre 60% et 79%.
  ///
  /// In fr, this message translates to:
  /// **'Bon travail !'**
  String get quizResultGoodJob;

  /// Titre de résultat quand le score est entre 40% et 59%.
  ///
  /// In fr, this message translates to:
  /// **'Continue d\'étudier'**
  String get quizResultKeepStudying;

  /// Titre de résultat quand le score est inférieur à 40%.
  ///
  /// In fr, this message translates to:
  /// **'Revois le cours !'**
  String get quizResultReviewLesson;

  /// Badge pourcentage de réponses correctes sur l'écran de résultat.
  ///
  /// In fr, this message translates to:
  /// **'{pct}% de réponses correctes'**
  String quizResultCorrectPct(int pct);

  /// Bouton pour voir le détail des réponses depuis l'écran de résultat.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes réponses'**
  String get quizResultReviewAnswers;

  /// Bouton principal pour rejouer le quiz.
  ///
  /// In fr, this message translates to:
  /// **'Rejouer'**
  String get quizResultReplay;

  /// Lien retour vers la fiche/leçon depuis l'écran de résultat.
  ///
  /// In fr, this message translates to:
  /// **'Retour au cours'**
  String get quizResultBackToCourse;

  /// Titre de l'écran de revue des réponses du quiz.
  ///
  /// In fr, this message translates to:
  /// **'Mes réponses — {score} / {total}'**
  String quizReviewTitle(int score, int total);

  /// Bouton pour revenir à l'écran de résultat depuis la revue.
  ///
  /// In fr, this message translates to:
  /// **'Retour au résultat'**
  String get quizReviewBack;

  /// CTA en bas de la fiche de révision pour lancer le quiz du chapitre.
  ///
  /// In fr, this message translates to:
  /// **'S\'exercer sur ce chapitre'**
  String get fichePracticeChapter;

  /// Titre du sheet plein écran de la fiche de lecture (résumé du chapitre).
  ///
  /// In fr, this message translates to:
  /// **'Fiche de lecture'**
  String get ficheTitle;

  /// État vide affiché quand la fiche n'est pas encore disponible pour ce chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Fiche bientôt disponible'**
  String get ficheComingSoon;

  /// Étiquette affichée en en-tête d'un bloc tableau dans le contenu pédagogique.
  ///
  /// In fr, this message translates to:
  /// **'TABLEAU'**
  String get tableLabel;

  /// Titre principal de l'onglet quiz chapitre (avant de démarrer).
  ///
  /// In fr, this message translates to:
  /// **'Teste tes connaissances'**
  String get quizTabTitle;

  /// Sous-titre descriptif de l'onglet quiz chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Un quiz personnalisé sur ce chapitre'**
  String get quizTabSubtitle;

  /// CTA bouton pour démarrer le quiz du chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Commencer le quiz'**
  String get quizTabStart;

  /// Bouton d'aide dans le quiz et titre du sheet de notion associée.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'aide'**
  String get quizNeedHelp;

  /// Bouton CTA affiché à la dernière question du quiz pour naviguer vers les résultats.
  ///
  /// In fr, this message translates to:
  /// **'Voir le résultat'**
  String get quizSeeResult;

  /// Bouton CTA entre les questions du quiz pour avancer à la suivante.
  ///
  /// In fr, this message translates to:
  /// **'Question suivante'**
  String get quizNextQuestion;

  /// Message affiché quand aucune notion n'est disponible pour l'aide dans le quiz.
  ///
  /// In fr, this message translates to:
  /// **'Relis le cours pour retrouver cette notion.'**
  String get quizNoNotionHint;

  /// État vide affiché quand aucune question quiz n'est disponible pour cette leçon/chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Questions bientôt disponibles'**
  String get quizQuestionsComingSoon;

  /// Label de la barre de progression dans le header d'une matière.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get subjectProgress;

  /// Label eyebrow du nombre de chapitres dans le header matière (ex. '8 CHAPITRES').
  ///
  /// In fr, this message translates to:
  /// **'CHAPITRES'**
  String get subjectChaptersLabel;

  /// Eyebrow du header matière indiquant le trimestre courant (mock : n=1).
  ///
  /// In fr, this message translates to:
  /// **'TRIMESTRE {n}'**
  String subjectTrimesterEyebrow(int n);

  /// Label court d'un onglet séquence (S1, S2, ...).
  ///
  /// In fr, this message translates to:
  /// **'S{n}'**
  String sequenceTabLabel(int n);

  /// Chip niveau bon (score quiz >= 70%).
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get performanceLevelGood;

  /// Chip niveau moyen (score quiz 40-69%).
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get performanceLevelMedium;

  /// Chip niveau faible (score quiz < 40%).
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get performanceLevelWeak;

  /// Étiquette eyebrow du numéro de leçon dans la liste des leçons.
  ///
  /// In fr, this message translates to:
  /// **'LEÇON {order}'**
  String lessonLabel(int order);

  /// Indicateur dans la tuile de leçon signalant qu'un quiz est associé.
  ///
  /// In fr, this message translates to:
  /// **'Quiz lié'**
  String get lessonLinkedQuiz;

  /// Pill de durée de lecture estimée d'une leçon.
  ///
  /// In fr, this message translates to:
  /// **'{duration} min de lecture'**
  String lessonReadingTime(int duration);

  /// CTA bouton pour lancer le quiz d'une leçon depuis la vue contenu.
  ///
  /// In fr, this message translates to:
  /// **'S\'exercer'**
  String get lessonPractice;

  /// Suggestion affichée sur la première leçon non commencée d'un chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Commence par cette leçon'**
  String get lessonStartHere;

  /// Nombre de leçons dans une card chapitre, avec pluriel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 leçon} other{{count} leçons}}'**
  String chapterLessonCount(int count);

  /// Nombre d'exercices dans une card chapitre, avec pluriel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 exercice} other{{count} exercices}}'**
  String chapterExerciseCount(int count);

  /// Suffixe du compteur d'élèves dans une card chapitre (ex. '1 234 élèves').
  ///
  /// In fr, this message translates to:
  /// **'élèves'**
  String get chapterStudentsLabel;

  /// Label de l'onglet Leçons dans la page chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get chapterTabLessons;

  /// Label de l'onglet Exercices dans la page chapitre.
  ///
  /// In fr, this message translates to:
  /// **'Exercices'**
  String get chapterTabExercises;

  /// Message affiché quand un chapitre ne contient aucune leçon.
  ///
  /// In fr, this message translates to:
  /// **'Aucune leçon disponible'**
  String get lessonsEmptyLabel;

  /// Pied de liste du tab Leçons : nombre d'élèves qui ont commencé ce chapitre.
  ///
  /// In fr, this message translates to:
  /// **'{count} élèves utilisent ce chapitre'**
  String chapterStudentsUsingCount(int count);

  /// Texte eyebrow du header chapitre (ex. 'MATHS · CHAPITRE 3').
  ///
  /// In fr, this message translates to:
  /// **'{subjectAbbrev} · CHAPITRE {chapterOrder}'**
  String chapterEyebrow(String subjectAbbrev, int chapterOrder);

  /// Placeholder du tab Exercices quand le contenu n'est pas encore disponible.
  ///
  /// In fr, this message translates to:
  /// **'Exercices bientôt disponibles'**
  String get chapterExercisesComingSoon;

  /// Label du FAB secondaire qui ouvre le bottom sheet du résumé de chapitre (fiche de révision).
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get chapterFabSummary;

  /// Label du FAB principal qui route vers le quiz du chapitre.
  ///
  /// In fr, this message translates to:
  /// **'S\'exercer'**
  String get chapterFabPractice;

  /// Message vide quand une matière n'a pas encore de chapitres.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chapitre disponible'**
  String get chaptersEmptyLabel;

  /// Message d'erreur affiché quand une image du contenu pédagogique ne peut pas être chargée.
  ///
  /// In fr, this message translates to:
  /// **'Image indisponible'**
  String get imageUnavailableLabel;

  /// Message d'erreur affiché quand un bloc audio du contenu pédagogique ne peut pas être chargé.
  ///
  /// In fr, this message translates to:
  /// **'Audio indisponible'**
  String get audioUnavailableLabel;

  /// Label du callout pédagogique de type définition.
  ///
  /// In fr, this message translates to:
  /// **'DÉFINITION'**
  String get calloutDefinition;

  /// Label du callout pédagogique de type théorème.
  ///
  /// In fr, this message translates to:
  /// **'THÉORÈME'**
  String get calloutTheorem;

  /// Label du callout pédagogique de type démonstration.
  ///
  /// In fr, this message translates to:
  /// **'DÉMONSTRATION'**
  String get calloutDemonstration;

  /// Label du callout pédagogique de type propriété.
  ///
  /// In fr, this message translates to:
  /// **'PROPRIÉTÉ'**
  String get calloutProperty;

  /// Label du callout pédagogique de type méthode.
  ///
  /// In fr, this message translates to:
  /// **'MÉTHODE'**
  String get calloutMethod;

  /// Label du callout pédagogique de type avertissement.
  ///
  /// In fr, this message translates to:
  /// **'ATTENTION'**
  String get calloutWarning;

  /// Label du callout pédagogique de type à retenir / résumé.
  ///
  /// In fr, this message translates to:
  /// **'À RETENIR'**
  String get calloutRecap;

  /// Label du callout pédagogique de type exemple.
  ///
  /// In fr, this message translates to:
  /// **'EXEMPLE'**
  String get calloutExample;

  /// Label du callout pédagogique de type figure.
  ///
  /// In fr, this message translates to:
  /// **'FIGURE'**
  String get calloutFigure;

  /// Label par défaut pour un callout pédagogique de type inconnu.
  ///
  /// In fr, this message translates to:
  /// **'NOTE'**
  String get calloutNote;
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
