// Audit PR5 2026-06-13 — Bottomsheet d'upgrade visiteur -> compte permanent.
//
// Le visiteur (compte Firebase anonymous) a un uid stable et un doc
// users/{uid} avec son profil scolaire. linkWithCredential() Google/Apple
// preserve l'uid : le doc est intact, seul `isAnonymous` passe a false +
// `authProvider` se pose.
//
// Reutilise `accountLinkingNotifierProvider` (Story 1.6) qui appelle
// `linkWithCredential` cote repo. Pas de signOut + signIn (qui aurait
// donne un nouvel uid et perdu le profil).
//
// Apres succes : snackbar + close. Le DashboardPage va automatiquement
// masquer DashboardGuestInviteCard (isAnonymous=false propage via
// firebaseAuthProvider.currentUser).

import 'package:flutter/material.dart';

import '../../../../core/platform/platform_capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/auth/social_brand_icons.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/account_linking_failure.dart';
import '../../../onboarding/domain/account_linking_state.dart';
import '../../../onboarding/domain/linked_account.dart';
import '../../../onboarding/presentation/state/onboarding_providers.dart';
import '../../../onboarding/presentation/state/onboarding_state.dart';
import '../../../onboarding/providers.dart';

/// Ouvre le bottomsheet d'upgrade. Retourne `true` si l'utilisateur a
/// reussi le link (Google ou Apple), `false`/null sinon.
Future<bool?> showAccountUpgradeSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => const _AccountUpgradeSheet(),
  );
}

class _AccountUpgradeSheet extends ConsumerStatefulWidget {
  const _AccountUpgradeSheet();

  @override
  ConsumerState<_AccountUpgradeSheet> createState() =>
      _AccountUpgradeSheetState();
}

class _AccountUpgradeSheetState extends ConsumerState<_AccountUpgradeSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linkState = ref.watch(accountLinkingNotifierProvider);
    final notifier = ref.read(accountLinkingNotifierProvider.notifier);

    ref.listen<AccountLinkingState>(accountLinkingNotifierProvider,
        (prev, next) {
      if (next is AccountLinkingSuccess) {
        AppLogger.i(
          'account.upgrade success provider=${next.account.provider.id} '
          '-> starting identity completion (steps 6-9)',
        );

        // upgradeInProgress a déjà été posé true par le onPressed du bouton,
        // AVANT l'appel linkGoogle/linkApple. Le router n'a donc pas pu
        // auto-rediriger /dashboard -> /onboarding/v2 pendant l'auth.
        // Positionner le notifier au step 6 (saisie nom) avec le
        // displayName OAuth pré-rempli si disponible.
        ref.read(onboardingNotifierProvider.notifier).setAuthProvider(
              next.account.provider == AccountProvider.google
                  ? OnboardingAuthProvider.google
                  : OnboardingAuthProvider.apple,
              displayName: next.account.displayName,
            );

        // Pop le sheet puis naviguer vers le flow de completion d'identité.
        if (context.mounted) {
          Navigator.of(context).pop();
          GoRouter.of(context).go('/onboarding/v2');
        }
      } else if (next is AccountLinkingError) {
        // Annulation ou erreur : réinitialiser le flag pour que le router
        // reprenne ses gardes normales.
        ref
            .read(profileUpgradeInProgressProvider.notifier)
            .setInProgress(false);
      }
    });

    final isLoading = linkState.isLoading;
    final errorMessage = _errorMessage(linkState, l10n);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s5.w,
          AppSpacing.s4.h,
          AppSpacing.s5.w,
          AppSpacing.s5.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.s4.h),
            Icon(LucideIcons.shieldCheck,
                size: 40.sp, color: AppColors.primary),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              l10n.accountUpgradeSheetTitle,
              style: AppTypography.h2.copyWith(fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s2.h),
            Text(
              l10n.accountUpgradeSheetBody,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            if (errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(AppSpacing.s3.w),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  errorMessage,
                  style: AppTypography.body.copyWith(
                    color: AppColors.danger,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s3.h),
            ],
            AppButton.primary(
              label: l10n.onboardingAuthGoogleLabel,
              iconWidget: const GoogleBrandIcon(),
              loading: linkState is AccountLinkingLoading &&
                  linkState.provider == AccountProvider.google,
              onPressed: isLoading
                  ? null
                  : () {
                      // Poser le flag AVANT linkGoogle pour que le router
                      // bypasse le guard profil-incomplet (Check 4) quand
                      // signInWithCredential change l'uid courant.
                      ref
                          .read(profileUpgradeInProgressProvider.notifier)
                          .setInProgress(true);
                      notifier.linkGoogle();
                    },
            ),
            if (isAppleSignInAvailable) ...[
              SizedBox(height: AppSpacing.s2.h),
              AppButton.secondary(
                label: l10n.onboardingAuthAppleLabel,
                iconWidget: const AppleBrandIcon(color: Colors.black),
                loading: linkState is AccountLinkingLoading &&
                    linkState.provider == AccountProvider.apple,
                onPressed: isLoading
                    ? null
                    : () {
                        ref
                            .read(profileUpgradeInProgressProvider.notifier)
                            .setInProgress(true);
                        notifier.linkApple();
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _errorMessage(AccountLinkingState state, AppLocalizations l10n) {
    if (state is! AccountLinkingError) return null;
    final failure = state.failure;
    return switch (failure.kind) {
      AccountLinkingFailureKind.cancelled => null,
      AccountLinkingFailureKind.unknown => l10n.errorGenericTitle,
      _ => failure.message,
    };
  }
}
