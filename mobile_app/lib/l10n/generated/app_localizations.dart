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
  /// **'Matieres obligatoires'**
  String get onboardingPickerObligatoryTitle;

  /// Story E1bis-3 — Titre section matieres optionnelles picker.
  ///
  /// In fr, this message translates to:
  /// **'Matieres optionnelles'**
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
  /// **'Matieres connexes'**
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

  /// Titre du Hero DashboardPage avec prenom (Story 1.9 AC1). Prenom = displayName.split(' ').first.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue {name} !'**
  String dashboardWelcomeWithName(String name);

  /// Titre du Hero DashboardPage sans prenom (visiteur ou displayName vide) — Story 1.9 AC1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
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

  /// Label onglet 1 du bottom tab bar (Story 1.9 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Matières'**
  String get dashboardTabSubjects;

  /// Label onglet 2 du bottom tab bar (Story 1.9 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get dashboardTabActivities;

  /// Label onglet 3 du bottom tab bar (Story 1.9 AC6).
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get dashboardTabProfile;

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

  /// Story E1bis-2bis — Description sous le label Francophone, aide l'eleve a se reperer.
  ///
  /// In fr, this message translates to:
  /// **'Programme officiel camerounais (BEPC, Probatoire, BAC)'**
  String get onboardingSubSystemFrancophoneDesc;

  /// Story E1bis-2 — Label SelectionCard Anglophone step 0.
  ///
  /// In fr, this message translates to:
  /// **'Anglophone'**
  String get onboardingSubSystemAnglophone;

  /// Story E1bis-2bis — Description sous le label Anglophone, aide l'eleve a se reperer.
  ///
  /// In fr, this message translates to:
  /// **'GCE O-Level vers A-Level (programme anglophone)'**
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
  /// **'Programme academique classique (maths, sciences, lettres)'**
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

  /// Story E1bis-3 — Titre H1 step 4 stream + subjects picker.
  ///
  /// In fr, this message translates to:
  /// **'Quelles matières étudies-tu ?'**
  String get onboardingStreamSubjectsTitle;

  /// Story E1bis-3 — Sous-titre step 4.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne ta série et tes matières pour personnaliser tes cours.'**
  String get onboardingStreamSubjectsSubtitle;

  /// Audit BUG-01 — Titre fallback affiche quand le catalogue Firestore ne contient aucune serie pour le niveau choisi (probable desync seed).
  ///
  /// In fr, this message translates to:
  /// **'Aucune série disponible'**
  String get onboardingStreamPickerEmptyTitle;

  /// Audit BUG-01 — Body fallback streams.length==0.
  ///
  /// In fr, this message translates to:
  /// **'Pour ce niveau, aucune série n\'est encore configurée. Réessaie dans quelques minutes ou contacte l\'équipe Valide.'**
  String get onboardingStreamPickerEmptyBody;

  /// Audit BUG-01 — CTA retry fallback streams empty.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get onboardingStreamPickerEmptyRetry;

  /// Story E1bis-3 — Badge compteur picker (ex. 6/11 selectionnees).
  ///
  /// In fr, this message translates to:
  /// **'{count}/{max} selectionnees'**
  String onboardingPickerCounter(int count, int max);

  /// Story E1bis-3 — Label CTA validation picker.
  ///
  /// In fr, this message translates to:
  /// **'Valider mes matières'**
  String get onboardingPickerValidate;

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
  /// **'En liant ton compte, tu retrouves ta progression sur n\'importe quel telephone et tu evites de tout perdre si tu changes d\'appareil.'**
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
  /// **'Ton numero de telephone'**
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
  /// **'Passer cette etape ?'**
  String get onboardingPhoneSkipConfirmTitle;

  /// Story E1bis-5 — Message dialog skip phone.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras ajouter ton numero plus tard depuis ton profil.'**
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
  /// **'Impossible de sauvegarder ton profil. Reessaie.'**
  String get onboardingFlushError;
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
