// Section compte intégrée dans la tab Profil.
//
// Affiche (pour utilisateurs authentifiés uniquement) :
//   - Info compte : email + icône provider (Google / Apple / anonyme)
//   - Bannière suppression en attente (si deletionRequestedAt est posé)
//   - Zone de danger : bouton "Supprimer mon compte" → dialog → deleteNow()
//
// Suppression immédiate (deleteNow) : efface SharedPreferences + Firestore
// users/{uid} + Firebase Auth user. En cas de succès → go('/').
// En cas de requires-recent-login → toast "Session expirée. Reconnecte-toi."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../account/domain/account_deletion_failure.dart';
import '../../../account/domain/account_deletion_status.dart';
import '../../../account/providers.dart';
import '../../../onboarding/providers.dart';

class ProfileAccountSection extends ConsumerStatefulWidget {
  const ProfileAccountSection({super.key});

  @override
  ConsumerState<ProfileAccountSection> createState() =>
      _ProfileAccountSectionState();
}

class _ProfileAccountSectionState
    extends ConsumerState<ProfileAccountSection> {
  BuildContext? _dialogContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // currentUserProvider ecoute authStateChanges() -> rebuild apres linkGoogle
    // / signInWithCredential, contrairement a firebaseAuthProvider.currentUser
    // (lecture synchrone, ne reagit pas aux changements d'auth).
    final user = ref.watch(currentUserProvider).maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );
    final isAnonymous = user?.isAnonymous ?? true;
    final scheduledFor = ref.watch(deletionScheduledForProvider);

    ref.listen<AccountDeletionStatus>(
      accountDeletionStatusNotifierProvider,
      (prev, next) {
        switch (next) {
          case AccountDeletionStatusDeleted():
            _closeDialogIfOpen();
            ref
                .read(profileUpgradeInProgressProvider.notifier)
                .setInProgress(false);
            if (context.mounted) GoRouter.of(context).go('/');

          case AccountDeletionStatusError(:final failure):
            _closeDialogIfOpen();
            final message = switch (failure.kind) {
              AccountDeletionFailureKind.requiresRecentLogin =>
                l10n.accountDeletionRecentLoginToast,
              AccountDeletionFailureKind.functionNotFound =>
                l10n.accountDeletionNotAvailableToast,
              AccountDeletionFailureKind.network => l10n.errorNoConnection,
              AccountDeletionFailureKind.unknown => l10n.errorGeneric,
            };
            AppToast.show(context, message: message, tone: ToastTone.warning);
            // Ne pas reset() pour requiresRecentLogin : le rollback dans le repo
            // restaure le doc Firestore de facon async (Platform Channel).
            // Garder l'etat error comme bouclier routeur (isDeletionActive) le
            // temps que profileCompletionProvider recoive le callback Firestore
            // et emette complete. L'utilisateur re-tape "Supprimer" pour retenter,
            // ce qui transite vers deleting et efface l'etat error.
            if (failure.kind != AccountDeletionFailureKind.requiresRecentLogin) {
              ref
                  .read(accountDeletionStatusNotifierProvider.notifier)
                  .reset();
            }

          default:
            break;
        }
      },
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w,
        AppSpacing.s5.h,
        AppSpacing.s4.w,
        AppSpacing.s8.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileSettingsAccountSection,
              style: AppTypography.eyebrow),
          SizedBox(height: AppSpacing.s2.h),
          _AccountInfoCard(user: user),
          if (scheduledFor != null) ...[
            SizedBox(height: AppSpacing.s3.h),
            _DeletionPendingBanner(scheduledFor: scheduledFor),
          ],
          if (!isAnonymous) ...[
            SizedBox(height: AppSpacing.s4.h),
            _DangerZone(
              onTapDelete: () => _showDeleteConfirmDialog(context, l10n),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext outerContext,
    AppLocalizations l10n,
  ) async {
    await showDialog<void>(
      context: outerContext,
      barrierDismissible: false,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return Consumer(
          builder: (_, ref, _) {
            final status = ref.watch(accountDeletionStatusNotifierProvider);
            final isLoading = status.isLoading;
            return AppDialogCard(
              title: l10n.accountDeletionConfirmTitle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.accountDeletionConfirmBody,
                    style: AppTypography.body.copyWith(
                      color: AppColors.inkSoft,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s6.h),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.cancelLabel,
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                      SizedBox(width: AppSpacing.s3.w),
                      Expanded(
                        child: AppButton.danger(
                          label: l10n.accountDeletionConfirmCta,
                          loading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () => ref
                                  .read(accountDeletionStatusNotifierProvider
                                      .notifier)
                                  .deleteNow(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _dialogContext = null;
  }

  void _closeDialogIfOpen() {
    final dialogCtx = _dialogContext;
    if (dialogCtx != null && Navigator.of(dialogCtx).canPop()) {
      Navigator.of(dialogCtx).pop();
      _dialogContext = null;
    }
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user});

  // Type loose pour éviter d'importer firebase_auth dans la couche présentation.
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAnonymous = user?.isAnonymous ?? true;
    final email = isAnonymous ? null : user?.email as String?;
    final displayValue = email ?? l10n.profileSettingsLinkedAccount;
    final providerLabel = _providerLabel(user);

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      child: Row(
        children: [
          Icon(_providerIcon(user), size: AppIconSize.xl3, color: AppColors.primary),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (providerLabel != null) ...[
                  SizedBox(height: AppSpacing.s1.h),
                  Text(providerLabel, style: AppTypography.meta),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _providerIcon(dynamic user) {
    if (user == null) return LucideIcons.user;
    final providers = (user.providerData as List?) ?? const [];
    if (providers.any((p) => p.providerId == 'google.com')) {
      return LucideIcons.globe;
    }
    if (providers.any((p) => p.providerId == 'apple.com')) {
      return LucideIcons.apple;
    }
    return LucideIcons.user;
  }

  String? _providerLabel(dynamic user) {
    if (user == null) return null;
    final providers = (user.providerData as List?) ?? const [];
    if (providers.any((p) => p.providerId == 'google.com')) return 'Google';
    if (providers.any((p) => p.providerId == 'apple.com')) return 'Apple';
    return null;
  }
}

class _DeletionPendingBanner extends StatelessWidget {
  const _DeletionPendingBanner({required this.scheduledFor});

  final DateTime scheduledFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatted = DateFormat('dd/MM/yyyy').format(scheduledFor);
    return Container(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle,
              size: AppIconSize.md, color: AppColors.warningInk),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileDeletionPendingTitle,
                  style: AppTypography.bodyStrong
                      .copyWith(color: AppColors.warningInk),
                ),
                SizedBox(height: AppSpacing.s1.h),
                Text(
                  l10n.profileDeletionPendingSubtitle(formatted),
                  style: AppTypography.body
                      .copyWith(color: AppColors.warningInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onTapDelete});

  final VoidCallback onTapDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.profileSettingsDangerSection,
          style: AppTypography.eyebrow.copyWith(color: AppColors.dangerInk),
        ),
        SizedBox(height: AppSpacing.s2.h),
        Container(
          padding: EdgeInsets.all(AppSpacing.s4.w),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border:
                Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileSettingsDeleteSubtitle,
                style:
                    AppTypography.body.copyWith(color: AppColors.dangerInk),
              ),
              SizedBox(height: AppSpacing.s4.h),
              AppButton.danger(
                label: l10n.profileSettingsDeleteCta,
                icon: LucideIcons.trash2,
                onPressed: onTapDelete,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
