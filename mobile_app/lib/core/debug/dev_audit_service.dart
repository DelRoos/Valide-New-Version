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

  /// Vide SharedPreferences + cache Firestore + sign out FirebaseAuth.
  /// L'utilisateur redevient un visiteur anonyme frais au prochain boot.
  /// Le doc users/{uid} reste en place — utile pour conserver un compte
  /// existant entre 2 audits du parcours.
  Future<void> clearLocalAndSignOut() async {
    AppLogger.i('[DEV] clearLocalAndSignOut start');
    await logPerf(
      'dev.prefs.clear',
      () => _prefs.clear(),
    );
    await logPerf(
      'dev.firestore.terminate',
      () => _firestore.terminate(),
    );
    await logPerf(
      'dev.firestore.clearPersistence',
      () => _firestore.clearPersistence(),
    );
    await logPerf(
      'dev.auth.signOut',
      () => _auth.signOut(),
    );
    AppLogger.i('[DEV] clearLocalAndSignOut OK');
  }

  /// Delete doc users/{uid} puis delete le compte FirebaseAuth. Brutal — pas
  /// de grâce 7j. Conserve les eventuels school_requests et autres
  /// sous-collections (acceptable pour audit dev).
  ///
  /// Apres l'appel, [currentUser] est null. Le caller doit naviguer hors
  /// des ecrans qui assumaient un user authentifie.
  ///
  /// Throws [FirebaseAuthException] code `requires-recent-login` si le user
  /// n'a pas reauth recemment (rare en anonyme — Firebase n'exige pas
  /// reauth pour delete les comptes anonymes).
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w('[DEV] deleteAccount aborted: no current user');
      return;
    }
    final uid = user.uid;
    AppLogger.i('[DEV] deleteAccount start anonymous=${user.isAnonymous}');

    // 1. Delete doc users/{uid} (best effort — si rules refusent ou doc
    //    inexistant, on log et on continue : le delete Auth reste prioritaire).
    try {
      await logPerf(
        'dev.users.delete',
        () => _firestore.collection('users').doc(uid).delete(),
      );
    } catch (e) {
      AppLogger.w('[DEV] users/{uid} delete failed: $e');
    }

    // 2. Delete le compte FirebaseAuth. Peut throw requires-recent-login pour
    //    les comptes Google/Apple post-linkWithCredential. En anonyme, OK.
    await logPerf(
      'dev.auth.delete',
      () => user.delete(),
    );
    AppLogger.i('[DEV] deleteAccount OK uid=${uid.substring(0, 6)}...');
  }

  /// Action canonique du bouton dev : delete users/{uid} + delete Auth account
  /// + clear local prefs + clear Firestore cache. Apres ca, l'app redemarre
  /// avec une slate vierge — parfait pour re-tester le parcours onboarding
  /// from scratch.
  Future<void> deleteAccountAndClear() async {
    AppLogger.i('[DEV] deleteAccountAndClear start');
    try {
      await deleteAccount();
    } catch (e) {
      AppLogger.w('[DEV] deleteAccount step failed: $e (continuing)');
    }
    await clearLocalAndSignOut();
    AppLogger.i('[DEV] deleteAccountAndClear OK');
  }
}
