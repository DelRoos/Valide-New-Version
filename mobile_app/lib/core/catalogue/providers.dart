// Providers Riverpod du catalogue scolaire — Story 1.1c.
//
// 3 providers exposés :
//   - catalogueRepositoryProvider : injection Firestore via firestoreProvider
//   - catalogueProvider : StreamProvider<CatalogueSnapshot> (combine les 6 streams)
//   - appStartupCatalogueCheckProvider : FutureProvider<bool> pour le redirect
//                                        global app_router

import 'dart:async';

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

/// Snapshot agrégé des 6 collections, mis à jour à chaque émission d'un des
/// sous-streams. Utilisé par les widgets qui consomment toute la matrice
/// catalogue (ex. Story 1.3 flow profil 3 étapes).
///
/// Implémentation : combine manuellement les 6 streams via subscriptions +
/// `StreamController` interne. Évite d'ajouter rxdart juste pour
/// `CombineLatestStream`.
final catalogueProvider = StreamProvider<CatalogueSnapshot>((ref) {
  final repo = ref.watch(catalogueRepositoryProvider);
  final controller = StreamController<CatalogueSnapshot>();
  var snap = const CatalogueSnapshot.empty();

  void emit() {
    if (!controller.isClosed) controller.add(snap);
  }

  final subs = <StreamSubscription>[
    repo.watchFilieres().listen((list) {
      snap = snap.copyWith(filieres: list);
      emit();
    }, onError: controller.addError),
    repo.watchNiveaux().listen((list) {
      snap = snap.copyWith(niveaux: list);
      emit();
    }, onError: controller.addError),
    repo.watchSeries().listen((list) {
      snap = snap.copyWith(series: list);
      emit();
    }, onError: controller.addError),
    repo.watchSubjects().listen((list) {
      snap = snap.copyWith(subjects: list);
      emit();
    }, onError: controller.addError),
    repo.watchExamTargets().listen((list) {
      snap = snap.copyWith(examTargets: list);
      emit();
    }, onError: controller.addError),
    repo.watchDerivationRules().listen((list) {
      snap = snap.copyWith(derivationRules: list);
      emit();
    }, onError: controller.addError),
  ];

  ref.onDispose(() async {
    for (final s in subs) {
      await s.cancel();
    }
    await controller.close();
  });

  return controller.stream;
});

/// Vrai si au moins 1 `derivation_rule` active existe (catalogue prêt à
/// servir), faux sinon (offline + cache vide). Lu par le redirect global du
/// GoRouter pour rediriger vers `/catalogue-waiting` au boot si nécessaire.
final appStartupCatalogueCheckProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(catalogueRepositoryProvider);
  return repo.hasNonEmptyCatalogue();
});
