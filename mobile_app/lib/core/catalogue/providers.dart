// Providers Riverpod du catalogue scolaire — Story 1.1c + refactor Story 1.13.
//
// 3 providers exposés :
//   - catalogueRepositoryProvider : injection Firestore via firestoreProvider
//   - catalogueProvider : FutureProvider<CatalogueSnapshot> (charge 6
//                         collections en parallèle, 1 read par doc initial)
//   - appStartupCatalogueCheckProvider : FutureProvider<bool> pour le redirect
//                                        global app_router
//
// **Story 1.13 — refactor `StreamProvider` → `FutureProvider`** :
// Cohérent CLAUDE.md règle 10.g + BASE-DE-DONNEES.md audit 2026-06-09.
// Le catalogue est statique (1-2× admin update / an). Plus économique de lire
// 1× au boot + cache offline natif Firestore que d'écouter 6 streams en
// permanence. Économie estimée ~80 % reads à 10k users (600k → 110k reads/mois).
//
// Pour forcer un refresh runtime (cas marginal — admin Console active une
// nouvelle série pendant la session) : `ref.invalidate(catalogueProvider)`.
// En V1 pas de bouton UI : redémarrer l'app suffit.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/providers.dart';
import 'data/catalogue_repository_firestore_impl.dart';
import 'domain/catalogue_repository.dart';
import 'domain/models.dart';

/// Repository — lazy, injection `FirebaseFirestore` via `firestoreProvider`
/// (cf. `core/firebase/providers.dart`).
final catalogueRepositoryProvider = Provider<CatalogueRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CatalogueRepositoryFirestoreImpl(firestore);
});

/// Snapshot agrégé des 6 collections, chargé en parallèle au 1er watch via
/// `Future.wait` (6 reads paralles → max(reads) latence). Sert ensuite depuis
/// le cache Riverpod jusqu'à `ref.invalidate(...)` explicite.
///
/// Utilisé par les widgets qui consomment toute la matrice catalogue (ex.
/// Story 1.3 flow profil 3 étapes — SubSystemChoicePage, NiveauChoicePage,
/// SerieChoicePage). Le widget reçoit un `AsyncValue<CatalogueSnapshot>` —
/// API consumer-side **inchangée** par le refactor v1 → v2.
final catalogueProvider = FutureProvider<CatalogueSnapshot>((ref) async {
  final repo = ref.watch(catalogueRepositoryProvider);
  // 6 fetchXxx() en parallèle — max(reads) latence vs sum(reads) séquentiel.
  // Cache offline natif Firestore servira les requêtes suivantes instantanément.
  final results = await Future.wait<dynamic>([
    repo.fetchFilieres(),
    repo.fetchNiveaux(),
    repo.fetchSeries(),
    repo.fetchSubjects(),
    repo.fetchExamTargets(),
    repo.fetchDerivationRules(),
  ]);
  return CatalogueSnapshot(
    filieres: results[0] as List<Filiere>,
    niveaux: results[1] as List<Niveau>,
    series: results[2] as List<Serie>,
    subjects: results[3] as List<Subject>,
    examTargets: results[4] as List<ExamTarget>,
    derivationRules: results[5] as List<DerivationRule>,
  );
});

/// Vrai si au moins 1 `derivation_rule` active existe (catalogue prêt à
/// servir), faux sinon (offline + cache vide). Lu par le redirect global du
/// GoRouter pour rediriger vers `/catalogue-waiting` au boot si nécessaire.
///
/// Audit 2026-06-14 — Attend `firebaseReadyProvider` avant d'instancier
/// `catalogueRepositoryProvider`. Sans ce gate, le router (qui watch ce
/// provider via `ref.listen` dans `app_router.dart`) declenchait la creation
/// de `firestoreProvider` AVANT que `Firebase.initializeApp()` ne resolve
/// (~2.9s en parallele de `runApp`), provoquant `[core/no-app]`. L'erreur
/// se propageait dans le routing initial — masquee par les bypass de `/`
/// et `/splash` mais polluait les logs et faisait perdre le precharge.
final appStartupCatalogueCheckProvider = FutureProvider<bool>((ref) async {
  final firebaseReady = await ref.watch(firebaseReadyProvider.future);
  if (!firebaseReady) return false;
  final repo = ref.watch(catalogueRepositoryProvider);
  return repo.hasNonEmptyCatalogue();
});
