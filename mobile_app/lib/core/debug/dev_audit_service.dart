// Dev audit toolkit — service utilitaire pour reset l'etat utilisateur
// pendant un audit du parcours d'onboarding.
//
// Pas une feature production : exposee uniquement via le bouton dev du
// dashboard. Operations destructives, le caller doit confirmer avant d'appeler.
//
// 3 actions :
//   - clearLocalAndSignOut() : vide SharedPreferences + Firestore cache offline
//     + sign out FirebaseAuth -> l'app redemarre comme un visiteur frais
//   - deleteAccount() : delete doc users/{uid} + delete FirebaseAuth account
//     (brutal, pas de grâce 7j Story 1.10 — adapte pour audit dev)
//   - deleteAccountAndClear() : combine les 2 (action canonique du bouton)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import '../logging/perf_logger.dart';

class DevAuditService {
  DevAuditService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _auth = auth,
        _firestore = firestore,
        _prefs = prefs;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  /// Vide SharedPreferences + sign out FirebaseAuth, puis re-signInAnonymously
  /// immediatement pour que les rules Firestore (qui exigent
  /// `request.auth != null` pour lire le catalogue) ne refusent pas le premier
  /// read. Sans ce re-sign-in, l'app retombe sur `CatalogueWaitingPage` car
  /// `hasNonEmptyCatalogue()` echoue sur permission-denied.
  ///
  /// Le doc users/{uid} de l'eventuel compte precedent reste en place —
  /// le re-sign-in cree un NOUVEL uid anonyme. Utile pour tester le parcours
  /// onboarding depuis l'etat « visiteur frais » sans toucher au compte.
  ///
  /// NB : `firestore.terminate()` + `firestore.clearPersistence()` ont ete
  /// volontairement retires. Apres terminate, toute query suivante throw
  /// jusqu'au restart de l'app (cf. Firestore SDK doc) — incompatible avec
  /// un audit interactif "clear puis re-test". Le nouvel uid anonyme suffit :
  /// les rules `request.auth.uid` empechent de lire le cache offline du
  /// precedent user, donc pas de fuite.
  Future<void> clearLocalAndSignOut() async {
    AppLogger.i('[DEV] clearLocalAndSignOut start');
    await logPerf(
      'dev.prefs.clear',
      () => _prefs.clear(),
    );
    // Audit 2026-06-13 — Verification explicite que le draft onboarding est
    // bien parti (prefs.clear() devrait l'avoir fait, on confirme + log).
    // Sans ce log, un draft residuel ferait silencieusement loadFromPersistence
    // restaurer un cursus que le user pensait avoir efface.
    final residualSubsystem = _prefs.getString('onboarding.subsystem');
    final residualDraft = _prefs.getString('onboarding.draft');
    AppLogger.i(
      '[DEV] prefs cleared. residual subsystem=$residualSubsystem '
      'draft=${residualDraft == null ? "<null>" : "<present!>"}',
    );
    await logPerf(
      'dev.auth.signOut',
      () => _auth.signOut(),
    );
    // Re-sign-in anonyme : sinon les reads catalogue echouent en
    // permission-denied -> CatalogueWaitingPage affichee meme avec reseau OK.
    await logPerf(
      'dev.auth.signInAnonymously',
      () => _auth.signInAnonymously(),
    );
    final newUid = _auth.currentUser?.uid;
    AppLogger.i(
      '[DEV] clearLocalAndSignOut OK newUid=${newUid?.substring(0, 6)}...',
    );
  }

  /// Supprime le doc Firestore users/{uid} puis le compte FirebaseAuth.
  ///
  /// Comportement selon le type de compte :
  ///
  /// - **Anonyme** (`isAnonymous=true`) : `user.delete()` fonctionne toujours
  ///   sans reauth. Firebase n'exige pas de session recente pour les comptes
  ///   anonymes.
  ///
  /// - **Non-anonyme** (Google/Apple, `isAnonymous=false`) : `user.delete()`
  ///   peut lever `requires-recent-login` si le dernier signIn est trop ancien.
  ///   Dans ce cas on log + on retourne sans delete Auth (le caller
  ///   `deleteAccountAndClear()` fait ensuite un `signOut()` + `signInAnonymously()`).
  ///   Le doc Firestore est deja supprime (etape 1) — `profileCompletionProvider`
  ///   retournera `filiereMissing` au prochain lancement -> router reste dans
  ///   l'onboarding pour un re-test propre. Si l'utilisateur re-tente le meme
  ///   Google auth au step 5, `_linkOrSignIn` (repo AccountLinking) recupere
  ///   la session via `signInWithCredential` fallback.
  ///
  /// Conserve les eventuelles sous-collections (school_requests, etc.) —
  /// acceptable pour audit dev, pas une suppression RGPD complete.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w('[DEV] deleteAccount aborted: no current user');
      return;
    }
    final uid = user.uid;
    final isAnonymous = user.isAnonymous;
    final rawProviders = user.providerData.map((p) => p.providerId).join(',');
    final providers = rawProviders.isEmpty ? 'none' : rawProviders;
    AppLogger.i(
      '[DEV] deleteAccount start anonymous=$isAnonymous providers=$providers',
    );

    // 1. Suppression doc Firestore users/{uid} — best effort.
    //    C'est l'etape CRITIQUE pour le re-test : sans ce delete, le prochain
    //    launch verrait un profil complet et irait directement au dashboard
    //    meme si le compte Auth est ressorti de la suppression.
    try {
      await logPerf(
        'dev.users.delete',
        () => _firestore.collection('users').doc(uid).delete(),
      );
      AppLogger.i('[DEV] users/{uid} deleted uid=${uid.substring(0, 6)}...');
    } catch (e) {
      AppLogger.w('[DEV] users/{uid} delete failed: $e');
    }

    // 2. Suppression du compte FirebaseAuth.
    if (isAnonymous) {
      // Anonyme : delete toujours possible sans reauth.
      await logPerf('dev.auth.delete', () => user.delete());
      AppLogger.i(
        '[DEV] deleteAccount (anonymous) OK uid=${uid.substring(0, 6)}...',
      );
    } else {
      // Non-anonyme (Google/Apple) : delete peut necessiter reauth recente.
      try {
        await logPerf('dev.auth.delete', () => user.delete());
        AppLogger.i(
          '[DEV] deleteAccount ($providers) OK uid=${uid.substring(0, 6)}...',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Reauth interactif non disponible dans le contexte dev FAB.
          // Retour sans delete Auth — le caller fait signOut() ensuite.
          // Le doc Firestore est deja parti (etape 1), donc le prochain
          // profileCompletionProvider verra filiereMissing -> onboarding.
          AppLogger.w(
            '[DEV] deleteAccount: requires-recent-login ($providers) '
            '— Auth account NOT deleted, Firestore doc gone. '
            'signOut handled by deleteAccountAndClear()',
          );
          return;
        }
        rethrow;
      }
    }
  }

  /// Action canonique du bouton dev : delete users/{uid} + delete Auth account
  /// + clear local prefs + clear Firestore cache. Apres ca, l'app redemarre
  /// avec une slate vierge — parfait pour re-tester le parcours onboarding
  /// from scratch.
  ///
  /// Audit 2026-06-14 — `prefs.clear()` est lance AVANT `deleteAccount()`.
  /// Justification : `user.delete()` declenche un signOut Firebase qui propage
  /// au currentUserProvider -> router refresh -> redirect /onboarding/v2 ->
  /// OnboardingShell mount -> loadFromPersistence dans un postFrameCallback.
  /// Si les prefs n'ont pas ete clean avant, le shell restaure l'ancien
  /// draft (subSystem + step + level + serie) -> user atterrit a step 3-4
  /// au lieu de step 0. En clearing avant, le shell load des prefs vides ->
  /// state reste au default (step 0). Cf. log "fail-safe (filiereMissing)
  /// reason=auth-missing subSystem=francophone" 2026-06-14.
  Future<void> deleteAccountAndClear() async {
    AppLogger.i('[DEV] deleteAccountAndClear start');

    // 1. Clear prefs EN PREMIER. Le redirect post-signOut va monter un
    //    OnboardingShell vierge.
    await logPerf('dev.prefs.clear.early', () => _prefs.clear());
    AppLogger.i('[DEV] prefs cleared early (before delete account)');

    // 2. Delete users/{uid} + Auth account. user.delete() signOut implicite
    //    -> router redirect -> shell mount (sur prefs vides).
    try {
      await deleteAccount();
    } catch (e) {
      AppLogger.w('[DEV] deleteAccount step failed: $e (continuing)');
    }

    // 3. Re-signInAnonymously pour que les rules Firestore ne refusent pas
    //    les reads du catalogue (cf. `clearLocalAndSignOut` doc). `signOut`
    //    avant le `signInAnonymously` est idempotent — `user.delete()` a
    //    deja desauthenticate ; ce `signOut` est defensif si delete a echoue.
    await logPerf('dev.auth.signOut', () => _auth.signOut());
    await logPerf('dev.auth.signInAnonymously', () => _auth.signInAnonymously());
    final newUid = _auth.currentUser?.uid;
    AppLogger.i('[DEV] deleteAccountAndClear OK newUid=${newUid?.substring(0, 6)}...');
  }
}
