// Story 1.10 — Page parametres du compte (FR-7).
//
// Affiche :
//   - Section "Mon compte" : email + provider icone (lecture firebaseAuth)
//   - Section "Zone de danger" : bouton suppression -> modale -> requestAccountDeletion
//   - Visiteur Anonymous : message info + CTA vers /onboarding/account
//
// Pattern Riverpod : ref.listen sur accountDeletionStatusNotifier pour fermer
// la modale et afficher le toast au resultat (Story 1.6 pattern).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/firebase/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/account_deletion_status.dart';
import '../providers.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  BuildContext? _dialogContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;

    // ref.listen : reagit aux transitions du status notifier.
    ref.listen<AccountDeletionStatus>(
      accountDeletionStatusNotifierProvider,
      (prev, next) {
        switch (next) {
          case AccountDeletionStatusRequested():
            _closeDialogIfOpen();
            final scheduledFor = DateTime.now().add(const Duration(days: 7));
            final formatted = DateFormat('dd/MM/yyyy').format(scheduledFor);
            AppToast.show(
              context,
              message: l10n.accountDeletionRequestedToast(formatted),
              tone: ToastTone.info,
            );
            // Reset apres consommation pour eviter de redeclencher.
            ref.read(accountDeletionStatusNotifierProvider.notifier).reset();
          case AccountDeletionStatusError(:final failure):
            _closeDialogIfOpen();
            final asString = failure.toString();
            String message;
            if (asString.contains('functionNotFound') ||
                asString.contains('bient')) {
              message = l10n.accountDeletionNotAvailableToast;
            } else if (asString.contains('network') ||
                asString.contains('connexion')) {
              message = l10n.errorNoConnection;
            } else {
              message = l10n.errorGeneric;
            }
            AppToast.show(context, message: message, tone: ToastTone.warning);
            ref.read(accountDeletionStatusNotifierProvider.notifier).reset();
          default:
            break;
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(l10n.profileSettingsTitle, style: AppTypography.h3),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => GoRouter.of(context).go('/profil'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s5.w,
            vertical: AppSpacing.s4.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileSettingsAccountSection,
                style: AppTypography.eyebrow,
              ),
              SizedBox(height: AppSpacing.s2.h),
              _AccountInfoCard(user: user, isAnonymous: isAnonymous),
              SizedBox(height: AppSpacing.s6.h),
              if (isAnonymous)
                _VisitorMessage()
              else
                _DangerZone(
                  onTapDelete: () => _showDeleteConfirmDialog(context, l10n),
                ),
            ],
          ),
        ),
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
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return Consumer(
          builder: (consumerContext, ref, _) {
            final status = ref.watch(accountDeletionStatusNotifierProvider);
            final isLoading = status.isLoading;
            return AlertDialog(
              title: Text(l10n.accountDeletionConfirmTitle),
              content: Text(l10n.accountDeletionConfirmBody),
              actions: [
                AppButton.secondary(
                  label: l10n.cancelLabel,
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
                AppButton.danger(
                  label: l10n.accountDeletionConfirmCta,
                  loading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(accountDeletionStatusNotifierProvider.notifier)
                          .requestDeletion(),
                ),
              ],
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
  const _AccountInfoCard({required this.user, required this.isAnonymous});

  // Type loose pour eviter d'importer firebase_auth ici (presentation layer).
  final dynamic user;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final providerLabel = _providerLabel(user);
    final email = isAnonymous ? null : user?.email as String?;
    final displayValue = email ?? l10n.profileSettingsLinkedAccount;

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      child: Row(
        children: [
          Icon(_providerIcon(user), size: 28.sp, color: AppColors.primary),
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
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileSettingsDeleteSubtitle,
                style: AppTypography.body.copyWith(color: AppColors.dangerInk),
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

class _VisitorMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.s4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 24.sp,
                color: AppColors.sky,
              ),
              SizedBox(width: AppSpacing.s2.w),
              Expanded(
                child: Text(
                  l10n.profileSettingsVisitorMessage,
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s4.h),
          AppButton.secondary(
            label: l10n.profileSettingsCreateAccountCta,
            onPressed: () => GoRouter.of(context).go('/onboarding/account'),
          ),
        ],
      ),
    );
  }
}
