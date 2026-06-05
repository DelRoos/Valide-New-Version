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
