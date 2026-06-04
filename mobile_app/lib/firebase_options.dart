// =====================================================================
// STUB — Story 0.6 Phase A
// =====================================================================
//
// Ce fichier est un STUB qui sera REMPLACE par le vrai
// `lib/firebase_options.dart` apres l'execution de :
//
//   cd mobile_app
//   flutterfire configure --project=valide-school-mvp \
//       --platforms=android,ios
//
// (cf. Story 0.6 Phase B — porteur uniquement, demande compte Firebase
// Console + auth Google interactive).
//
// Tant que Phase B n'est pas faite, `DefaultFirebaseOptions.currentPlatform`
// leve une exception EXPLICITE qui guide vers la procedure. L'app continue
// de build, mais l'init Firebase echoue en main.dart (try/catch silencieux)
// et tous les providers Firebase sont marques `unavailable`.
//
// NE PAS COMMITTER de credentials Firebase reels dans ce fichier. Quand
// Phase B sera faite, le vrai contenu sera genere par flutterfire CLI et
// remplacera ce stub. Les valeurs sont des identifiants publics (cf.
// Firebase doc "API keys are NOT secrets") donc OK a commit.
// =====================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Default [FirebaseOptions] pour la plateforme courante.
///
/// **Story 0.6 Phase A** : ce stub leve `UnsupportedError`. Une fois
/// Phase B faite (flutterfire configure), ce fichier sera regenere et
/// retournera les vraies options Android / iOS.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'firebase_options.dart est un STUB (Story 0.6 Phase A). '
      'Lance `flutterfire configure --project=valide-school-mvp '
      '--platforms=android,ios` pour le regenerer avec les vraies options. '
      'Plateforme detectee : $defaultTargetPlatform. '
      'En attendant, l\'init Firebase echoue silencieusement (try/catch '
      'dans main.dart) et les providers Firebase retournent `unavailable`.',
    );
  }

  /// Stub Android — sera regenere par flutterfire CLI.
  static FirebaseOptions get android {
    throw UnsupportedError(
      'firebase_options.dart STUB — flutterfire configure manquant '
      '(Story 0.6 Phase B). Plateforme : ${TargetPlatform.android}',
    );
  }

  /// Stub iOS — sera regenere par flutterfire CLI.
  static FirebaseOptions get ios {
    throw UnsupportedError(
      'firebase_options.dart STUB — flutterfire configure manquant '
      '(Story 0.6 Phase B). Plateforme : ${TargetPlatform.iOS}',
    );
  }
}
