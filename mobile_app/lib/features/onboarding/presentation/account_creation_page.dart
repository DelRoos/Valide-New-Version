// Story 1.6 AC1/AC4/AC5/AC6 — Page de creation de compte Google/Apple.
//
// Affichee post-recap (Story 1.3, route /onboarding/account). 2 boutons
// primaires pleine largeur : Google + Apple. Pas de tri par plateforme
// (ADR-011 + UX-research). Pas de bouton "skip" V1.
//
// Pattern : `ref.listen<AccountLinkingState>` reagit aux transitions du
// notifier. Loading -> bouton tap affiche spinner. Success -> nav /hello.
// Error (cancelled) -> silencieux. Error (network) -> toast. Error
// (conflict) -> AlertDialog. Error (alreadyLinked) -> toast info.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/account_linking_failure.dart';
import '../domain/account_linking_state.dart';
import '../domain/linked_account.dart';
import '../providers.dart';

class AccountCreationPage extends ConsumerWidget {
  const AccountCreationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Reaction aux transitions de state (success / error).
    ref.listen<AccountLinkingState>(
      accountLinkingNotifierProvider,
      (prev, next) => _handleStateChange(context, ref, l10n, next),
    );

    final state = ref.watch(accountLinkingNotifierProvider);
    final loadingProvider = state is AccountLinkingLoading
        ? state.provider
        : null;
    final anyLoading = loadingProvider != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 480 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5.w,
                    vertical: AppSpacing.s6.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.onboardingAccountTitle,
                        style: AppTypography.h2,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      Text(
                        l10n.onboardingAccountSubtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.inkSoft,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s8.h),
                      AppButton.primary(
                        label: l10n.onboardingAccountGoogleCta,
                        icon: LucideIcons.globe,
                        loading: loadingProvider == AccountProvider.google,
                        onPressed: anyLoading
                            ? null
                            : () => ref
                                .read(accountLinkingNotifierProvider.notifier)
                                .linkGoogle(),
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      AppButton.primary(
                        label: l10n.onboardingAccountAppleCta,
                        icon: LucideIcons.apple,
                        loading: loadingProvider == AccountProvider.apple,
                        onPressed: anyLoading
                            ? null
                            : () => ref
                                .read(accountLinkingNotifierProvider.notifier)
                                .linkApple(),
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      // Bouton secondaire : skip la creation de compte
                      // Google/Apple et continuer en anonyme. La session
                      // Firebase Anonymous est deja active (Story 0.6 boot
                      // + Story 1.3 createProfile). Le doc users/{uid} est
                      // deja cree -> on passe directement a l'etape suivante
                      // du flow (school picker Story 1.7).
                      AppButton.secondary(
                        label: l10n.onboardingAccountGuestCta,
                        onPressed: anyLoading
                            ? null
                            : () => _onContinueAsGuest(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Skip la creation de compte Google/Apple et continue le flow en
  /// anonyme. La session Firebase Anonymous reste active (uid inchange).
  /// Nav vers la prochaine etape du flow (school picker Story 1.7).
  void _onContinueAsGuest(BuildContext context) {
    // CLAUDE.md regle 4 (logs) : on log juste la decision, pas d'uid.
    AppLogger.i('Account linking skipped (guest mode)');
    GoRouter.of(context).go('/onboarding/school');
  }

  void _handleStateChange(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AccountLinkingState next,
  ) {
    if (next is AccountLinkingSuccess) {
      // Story 1.7 — apres creation compte, on demande la liaison ecole
      // optionnelle avant d'arriver au dashboard.
      GoRouter.of(context).go('/onboarding/school');
      return;
    }
    if (next is AccountLinkingError) {
      switch (next.failure) {
        case AccountLinkingFailure() when next.failure.toString().contains(
              'cancelled',
            ):
          // AC4 — annulation utilisateur : silencieux. Reset pour permettre
          // un nouvel essai sans bloquer le state en error.
          ref.read(accountLinkingNotifierProvider.notifier).reset();
          break;
        case AccountLinkingFailure() when next.failure.toString().contains(
              'network',
            ):
          AppToast.show(
            context,
            message: l10n.onboardingAccountNetworkErrorToast,
            tone: ToastTone.warning,
          );
          ref.read(accountLinkingNotifierProvider.notifier).reset();
          break;
        case AccountLinkingFailure() when next.failure.toString().contains(
              'credentialAlreadyInUse',
            ):
          _showConflictDialog(context, ref, l10n);
          break;
        case AccountLinkingFailure() when next.failure.toString().contains(
              'alreadyLinked',
            ):
          AppToast.show(
            context,
            message: l10n.onboardingAccountAlreadyLinkedToast,
            tone: ToastTone.info,
          );
          ref.read(accountLinkingNotifierProvider.notifier).reset();
          break;
        default:
          AppToast.show(
            context,
            message: l10n.errorGeneric,
            tone: ToastTone.warning,
          );
          ref.read(accountLinkingNotifierProvider.notifier).reset();
      }
    }
  }

  void _showConflictDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onboardingAccountConflictTitle),
        content: Text(l10n.onboardingAccountConflictBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(accountLinkingNotifierProvider.notifier).reset();
            },
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }
}
