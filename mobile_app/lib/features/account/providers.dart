// Story 1.10 — Providers Riverpod feature account (suppression / annulation
// compte FR-7).
//
// 4 providers exposes :
//   1. accountDeletionRepositoryProvider — impl Cloud Functions (lazy)
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

import '../../core/firebase/providers.dart';
import '../../core/logging/app_logger.dart';
import '../onboarding/providers.dart';
import 'data/account_deletion_repository_impl.dart';
import 'domain/account_deletion_repository.dart';
import 'domain/account_deletion_status.dart';

/// Repository Cloud Functions de la suppression compte. Lazy.
final accountDeletionRepositoryProvider =
    Provider<AccountDeletionRepository>((ref) {
  return AccountDeletionRepositoryImpl(ref.watch(cloudFunctionsProvider));
});

/// State machine UI : idle -> requesting/cancelling -> requested/cancelled/error.
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

  /// Reset vers idle (utile apres avoir consomme un toast d'erreur ou un
  /// succes pour permettre une nouvelle tentative).
  void reset() {
    state = const AccountDeletionStatus.idle();
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
