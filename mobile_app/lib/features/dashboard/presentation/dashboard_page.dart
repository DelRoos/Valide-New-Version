// Story 1.9 — Dashboard skeleton (FR-10 partiel).
//
// Premier ecran metier post-onboarding. Pure presentation : on consomme
//   - firebaseAuthProvider.currentUser?.isAnonymous -> banner upgrade
//   - userProfileRepositoryProvider.watchProfile() -> displayName
//   - userSubjectsProvider -> matieres derivees du profil
//
// Composants UI extraits dans widgets/ (CLAUDE.md regle 12 max-lines) :
//   - DashboardHero (banniere haut)
//   - DashboardSubjectsArea (grid + skeleton + empty)
//   - DashboardGuestInviteCard (carte upgrade visiteur -> compte permanent)
//   - DevAuditFab (FAB outil dev, dans core/debug/)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/debug/dev_audit_fab.dart';
import '../../../core/firebase/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/domain/account_deletion_status.dart';
import '../../account/providers.dart';
import '../../onboarding/providers.dart';
import 'widgets/dashboard_guest_invite_card.dart';
import 'widgets/dashboard_hero.dart';
import 'widgets/dashboard_subjects_area.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Audit NEW-BUG-17 — watch currentUserProvider (StreamProvider sur
    // authStateChanges) au lieu de firebaseAuthProvider (statique) pour que
    // l'upgrade visiteur -> compte permanent rebuild le dashboard et masque
    // automatiquement DashboardGuestInviteCard.
    final isAnonymous = ref.watch(currentUserProvider).maybeWhen(
          data: (user) => user?.isAnonymous ?? true,
          orElse: () => true,
        );

    final profileStream =
        ref.watch(userProfileRepositoryProvider).watchProfile();

    // Story 1.10 — feedback toast post-cancel deletion (manuel ou auto).
    ref.listen<AccountDeletionStatus>(
      accountDeletionStatusNotifierProvider,
      (prev, next) {
        if (next is AccountDeletionStatusCancelled) {
          AppToast.show(
            context,
            message: l10n.accountDeletionCancelledToast,
            tone: ToastTone.info,
          );
          ref.read(accountDeletionStatusNotifierProvider.notifier).reset();
        } else if (next is AccountDeletionStatusError) {
          final asString = next.failure.toString();
          final message = asString.contains('functionNotFound') ||
                  asString.contains('bient')
              ? l10n.accountDeletionNotAvailableToast
              : (asString.contains('network') ||
                      asString.contains('connexion'))
                  ? l10n.errorNoConnection
                  : l10n.errorGeneric;
          AppToast.show(context, message: message, tone: ToastTone.warning);
          ref.read(accountDeletionStatusNotifierProvider.notifier).reset();
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<Map<String, dynamic>?>(
                  stream: profileStream,
                  builder: (context, snap) {
                    final data = snap.data;
                    final displayName = data?['displayName'] as String?;
                    final firstName =
                        (displayName != null && displayName.isNotEmpty)
                            ? displayName.split(' ').first
                            : null;
                    final deletionTs = data?['deletionRequestedAt'];
                    final scheduledFor = deletionTs is Timestamp
                        ? deletionTs.toDate().add(const Duration(days: 7))
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (scheduledFor != null)
                          _DeletionBanner(scheduledFor: scheduledFor),
                        DashboardHero(
                          firstName: firstName,
                          examLabel: null,
                          isAnonymous: isAnonymous,
                        ),
                      ],
                    );
                  },
                ),
                const Expanded(
                  child: DashboardSubjectsArea(),
                ),
              ],
            ),
            if (isAnonymous)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s4.w,
                    AppSpacing.s2.h,
                    AppSpacing.s4.w,
                    AppSpacing.s3.h,
                  ),
                  child: const DashboardGuestInviteCard(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: const DevAuditFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}

/// Story 1.10 — Banner warning affiché en haut du Dashboard quand
/// `users/{uid}.deletionRequestedAt` est posé. Tap ouvre la modale d'annulation.
class _DeletionBanner extends ConsumerWidget {
  const _DeletionBanner({required this.scheduledFor});

  final DateTime scheduledFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formatted = DateFormat('dd/MM/yyyy').format(scheduledFor);
    return Material(
      color: AppColors.warningSoft,
      child: InkWell(
        onTap: () => _showCancelDeletionDialog(context, ref, l10n),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            AppSpacing.s3.h,
            AppSpacing.s4.w,
            AppSpacing.s3.h,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.triangleAlert,
                color: AppColors.warningInk,
                size: 22.sp,
              ),
              SizedBox(width: AppSpacing.s3.w),
              Expanded(
                child: Text(
                  l10n.accountDeletionScheduledBanner(formatted),
                  style: AppTypography.meta.copyWith(
                    color: AppColors.warningInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDeletionDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (consumerContext, ref, _) {
            final status = ref.watch(accountDeletionStatusNotifierProvider);
            final isLoading = status.isLoading;
            return AlertDialog(
              title: Text(l10n.accountDeletionCancelConfirmTitle),
              content: Text(l10n.accountDeletionCancelConfirmBody),
              actions: [
                AppButton.secondary(
                  label: l10n.accountDeletionKeepDeletionCta,
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                AppButton.primary(
                  label: l10n.accountDeletionCancelConfirmCta,
                  loading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () async {
                          await ref
                              .read(
                                accountDeletionStatusNotifierProvider.notifier,
                              )
                              .cancelDeletion();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
