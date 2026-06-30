// Story 1.10 — Providers Riverpod feature account (suppression / annulation
// compte FR-7).
//
// 5 providers exposes :
//   1. accountDeletionRepositoryProvider — impl Cloud Functions + Firebase (lazy)
//   2. accountDeletionStatusNotifierProvider — state machine UI
//   3. _sessionStartProvider — timestamp du boot pour l'auto-canceller
//   4. autoAccountDeletionCancellerProvider — annule auto au boot si
//      deletionRequestedAt anterieur a la session courante
//
// Pattern anti-boucle : autoAccountDeletionCanceller compare au sessionStart
// pour eviter d'annuler immediatement apres un request user dans la meme session.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import '../onboarding/providers.dart';
import 'data/account_deletion_repository_impl.dart';
import 'domain/account_deletion_failure.dart';
import 'domain/account_deletion_repository.dart';
import 'domain/account_deletion_status.dart';

/// Repository de la suppression compte. Lazy.
final accountDeletionRepositoryProvider =
    Provider<AccountDeletionRepository>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return AccountDeletionRepositoryImpl(
    ref.watch(cloudFunctionsProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    googleSignIn: () => googleSignIn.authenticate(
      scopeHint: const ['email', 'profile'],
    ),
  );
});

/// State machine UI : idle -> requesting/cancelling/deleting -> états finaux.
class AccountDeletionStatusNotifier extends Notifier<AccountDeletionStatus> {
  @override
  AccountDeletionStatus build() => const AccountDeletionStatus.idle();

  Future<void> requestDeletion() async {
    if (state.isLoading) return;
    state = const AccountDeletionStatus.requesting();
    final result =
        await ref.read(accountDeletionRepositoryProvider).requestAccountDeletion();
    state = result.fold(
      (failure) => AccountDeletionStatus.error(failure),
      (_) => const AccountDeletionStatus.requested(),
    );
  }

  Future<void> cancelDeletion() async {
    if (state.isLoading) return;
    state = const AccountDeletionStatus.cancelling();
    final result =
        await ref.read(accountDeletionRepositoryProvider).cancelAccountDeletion();
    state = result.fold(
      (failure) => AccountDeletionStatus.error(failure),
      (_) => const AccountDeletionStatus.cancelled(),
    );
  }

  /// Suppression immediate : nettoie le draft local, supprime Firestore + Auth.
  /// En cas de succes, transite vers `deleted` — l'UI doit naviguer vers '/'.
  /// En cas de `requiresRecentLogin`, transite vers `requiresReauth` pour que
  /// l'UI propose le bouton Google sans fermer la modale.
  Future<void> deleteNow() async {
    if (state.isLoading) return;
    state = const AccountDeletionStatus.deleting();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      AppLogger.w('SharedPreferences clear failed on account delete: $e');
    }
    final result =
        await ref.read(accountDeletionRepositoryProvider).deleteAccountNow();
    state = result.fold(
      (failure) {
        if (failure.kind == AccountDeletionFailureKind.requiresRecentLogin) {
          return const AccountDeletionStatus.requiresReauth();
        }
        return AccountDeletionStatus.error(failure);
      },
      (_) => const AccountDeletionStatus.deleted(),
    );
  }

  /// Re-authentifie via Google puis retente la suppression.
  /// Si l'utilisateur annule le flux Google, retourne en `requiresReauth`
  /// pour qu'il puisse réessayer. En cas d'erreur grave → `error`.
  Future<void> reauthAndDeleteNow() async {
    if (state.isLoading) return;
    state = const AccountDeletionStatus.reauthing();
    final reauthResult =
        await ref.read(accountDeletionRepositoryProvider).reauthenticateWithGoogle();
    if (reauthResult.isLeft()) {
      state = reauthResult.fold(
        (failure) {
          if (failure.kind == AccountDeletionFailureKind.requiresRecentLogin) {
            // Annulation par l'utilisateur → revenir au choix reauth.
            return const AccountDeletionStatus.requiresReauth();
          }
          return AccountDeletionStatus.error(failure);
        },
        (_) => throw StateError('impossible'),
      );
      return;
    }
    // Reauth réussie → retenter la suppression.
    final deleteResult =
        await ref.read(accountDeletionRepositoryProvider).deleteAccountNow();
    state = deleteResult.fold(
      (failure) => AccountDeletionStatus.error(failure),
      (_) => const AccountDeletionStatus.deleted(),
    );
  }

  /// Retour à idle après consommation d'une erreur ou d'un succès.
  void reset() {
    state = const AccountDeletionStatus.idle();
  }

  /// Cas mauvais compte Google : repasse en requiresReauth sans fermer le dialogue.
  void resetToReauth() {
    state = const AccountDeletionStatus.requiresReauth();
  }
}

final accountDeletionStatusNotifierProvider =
    NotifierProvider<AccountDeletionStatusNotifier, AccountDeletionStatus>(
  AccountDeletionStatusNotifier.new,
);

/// Timestamp du boot. Utilise par l'auto-canceller pour distinguer un
/// `deletionRequestedAt` ancien (anterieur a la session, faut auto-cancel)
/// d'un fraichement pose par l'utilisateur dans la session courante (ne pas
/// auto-cancel — l'utilisateur vient de le faire expres).
final _sessionStartProvider = Provider<DateTime>((ref) => DateTime.now());

/// Provider qui amorce l'auto-cancel au boot. A lire au demarrage de l'app
/// (cf. main.dart ou ValideApp root) pour qu'il commence a ecouter le stream
/// `userProfileRepository.watchProfile()`.
///
/// Heuristique : si `deletionRequestedAt` est anterieur au sessionStart,
/// c'est une demande d'une session passee, l'utilisateur revient -> on annule
/// automatiquement. Si posterieur, c'est dans la session courante (l'user
/// vient de tap "Confirmer") -> on ne touche pas.
final autoAccountDeletionCancellerProvider = Provider<void>((ref) {
  final sessionStart = ref.watch(_sessionStartProvider);
  bool alreadyHandled = false;

  final repo = ref.watch(userProfileRepositoryProvider);
  final sub = repo.watchProfile().listen((data) async {
    if (alreadyHandled) return;
    if (data == null) return;
    final ts = data['deletionRequestedAt'];
    if (ts is! Timestamp) return;
    if (ts.toDate().isAfter(sessionStart)) return; // request en cours
    alreadyHandled = true;
    AppLogger.i('Auto-cancelling account deletion at boot');
    await ref.read(accountDeletionRepositoryProvider).cancelAccountDeletion();
  });
  ref.onDispose(sub.cancel);
});
