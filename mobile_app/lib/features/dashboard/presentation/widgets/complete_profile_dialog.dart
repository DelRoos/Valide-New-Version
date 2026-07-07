import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/platform_capabilities.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/auth/social_auth_widgets.dart';
import '../../../../core/widgets/auth/social_brand_icons.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/account_linking_failure.dart';
import '../../../onboarding/domain/account_linking_state.dart';
import '../../../onboarding/domain/linked_account.dart';
import '../../../onboarding/providers.dart';
import 'profile_setup_sheet.dart';

/// Dialogue de liaison Google/Apple pour visiteurs anonymes — déclenché via [guardAnonymous].
class CompleteProfileDialog extends ConsumerStatefulWidget {
  const CompleteProfileDialog._({this.onLinked});

  /// Callback post-linking (via postFrameCallback).
  final VoidCallback? onLinked;

  /// Affiche le dialogue ; [onLinked] est appelé après linking réussi.
  static Future<void> show(BuildContext context, {VoidCallback? onLinked}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (_) => CompleteProfileDialog._(onLinked: onLinked),
    );
  }

  /// Affiche le dialogue uniquement si l'utilisateur est anonyme.
  /// [onLinked] par défaut : _setupThenAct avec action vide (vérifie displayName
  /// + remet profileUpgradeInProgress à false sans navigation supplémentaire).
  static Future<void> showIfAnonymous(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onLinked,
  }) {
    final isAnonymous = ref.read(currentUserProvider).maybeWhen(
          data: (user) => user?.isAnonymous ?? true,
          orElse: () => true,
        );
    if (!isAnonymous) return Future.value();
    return show(
      context,
      onLinked: onLinked ?? () => _setupThenAct(context, ref, () {}),
    );
  }

  /// Garde : anonyme → dialogue linking ; sinon → [action]. orElse=false laisse passer pendant chargement auth.
  static Future<void> guardAnonymous(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback action,
  }) {
    final isAnonymous = ref.read(currentUserProvider).maybeWhen(
          data: (user) => user?.isAnonymous ?? false,
          orElse: () => false,
        );
    if (isAnonymous) {
      return show(
        context,
        // action passée directement — _setupThenAct dans AccountLinkingSuccess la
        // wrappera avec la vérification displayName + reset profileUpgradeInProgress.
        onLinked: () => _setupThenAct(context, ref, action),
      );
    }
    action();
    return Future.value();
  }

  /// Post-linking : si displayName vide → ProfileSetupSheet, puis [action].
  /// Remet profileUpgradeInProgress à false une fois l'action exécutée.
  static void _setupThenAct(
    BuildContext context,
    WidgetRef ref,
    VoidCallback action,
  ) {
    // Firebase Auth peut être vide si le compte Google n'a pas de displayName.
    // Fallback sur Firestore : _persistIdentity préserve l'ancien nom si Auth n'en fournit pas.
    final authName =
        ref.read(firebaseAuthProvider).currentUser?.displayName?.trim() ?? '';
    final firestoreName = ref.read(profileDataProvider).maybeWhen(
          data: (data) => (data?['displayName'] as String?)?.trim() ?? '',
          orElse: () => '',
        );
    final effectiveName = authName.isNotEmpty ? authName : firestoreName;
    AppLogger.d(
      'CompleteProfileDialog._setupThenAct: '
      'authName="${authName.isEmpty ? "(empty)" : "(set)"}" '
      'firestoreName="${firestoreName.isEmpty ? "(empty)" : "(set)"}"',
    );
    if (effectiveName.isEmpty) {
      if (!context.mounted) return;
      AppLogger.i('CompleteProfileDialog: displayName vide → ProfileSetupSheet');
      ProfileSetupSheet.show(context, displayName: '').then((_) {
        if (context.mounted) {
          AppLogger.d('CompleteProfileDialog: ProfileSetupSheet closed → action + upgradeInProgress=false');
          action();
          ref
              .read(profileUpgradeInProgressProvider.notifier)
              .setInProgress(false);
        }
      });
    } else {
      AppLogger.d('CompleteProfileDialog: displayName set → action + upgradeInProgress=false');
      action();
      ref.read(profileUpgradeInProgressProvider.notifier).setInProgress(false);
    }
  }

  @override
  ConsumerState<CompleteProfileDialog> createState() =>
      _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends ConsumerState<CompleteProfileDialog> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linkState = ref.watch(accountLinkingNotifierProvider);
    final linkingNotifier = ref.read(accountLinkingNotifierProvider.notifier);

    ref.listen<AccountLinkingState>(accountLinkingNotifierProvider,
        (prev, next) {
      AppLogger.d(
        'CompleteProfileDialog.listener: ${prev.runtimeType} → ${next.runtimeType} mounted=$mounted',
      );
      if (next is AccountLinkingSuccess) {
        AppLogger.i(
          'CompleteProfileDialog: AccountLinkingSuccess → pop + onLinked',
        );
        if (mounted) {
          // showDialog useRootNavigator:true → rootNavigator requis ; maybePop absorbe la race condition GoRouter si uid change avant le pop.
          Navigator.of(context, rootNavigator: true).maybePop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onLinked?.call();
          });
        }
        return;
      }
      if (next is AccountLinkingError) {
        // Linking échoué ou annulé — libérer le verrou router.
        AppLogger.w(
          'CompleteProfileDialog: AccountLinkingError '
          'kind=${next.failure.kind.name} → upgradeInProgress=false',
        );
        ref
            .read(profileUpgradeInProgressProvider.notifier)
            .setInProgress(false);
        final failure = next.failure;
        final msg = switch (failure.kind) {
          AccountLinkingFailureKind.cancelled => null,
          AccountLinkingFailureKind.unknown =>
            failure.message.startsWith('provider_not_supported:')
                ? l10n.onboardingAuthProviderNotSupported
                : l10n.errorFirestoreUnknown,
          _ => failure.message,
        };
        if (msg != null && mounted) setState(() => _errorMessage = msg);
      }
    });

    final isLoading = linkState.isLoading;

    return AppDialogCard(
      title: l10n.completeProfileDialogTitle,
      onClose: () {
        // Fermeture manuelle sans linking — libérer le verrou si posé.
        AppLogger.d('CompleteProfileDialog: onClose → upgradeInProgress=false');
        ref
            .read(profileUpgradeInProgressProvider.notifier)
            .setInProgress(false);
        Navigator.of(context, rootNavigator: true).maybePop();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
              ),
              child: Icon(
                LucideIcons.userRound,
                size: AppIconSize.xl8,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.s4.h),
          Text(
            l10n.completeProfileDialogBody,
            style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: AppSpacing.s2.h),
            Text(
              _errorMessage!,
              style:
                  AppTypography.caption.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: AppSpacing.s5.h),
          SocialButton(
            label: l10n.onboardingAuthGoogleLabel,
            iconWidget: const GoogleBrandIcon(),
            loading: linkState is AccountLinkingLoading &&
                linkState.provider == AccountProvider.google,
            onPressed: isLoading
                ? null
                : () {
                    setState(() => _errorMessage = null);
                    // Verrou router : empêche guard profil-incomplet de rediriger
                    // vers /onboarding pendant la transition isAnonymous→false.
                    AppLogger.i('CompleteProfileDialog: linkGoogle → upgradeInProgress=true');
                    ref
                        .read(profileUpgradeInProgressProvider.notifier)
                        .setInProgress(true);
                    linkingNotifier.linkGoogle();
                  },
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.ink,
            border: Border.all(color: AppColors.border, width: AppBorderWidth.hairline),
          ),
          if (isAppleSignInAvailable) ...[
            SizedBox(height: AppSpacing.s3.h),
            SocialButton(
              label: l10n.onboardingAuthAppleLabel,
              iconWidget: const AppleBrandIcon(color: Colors.white),
              loading: linkState is AccountLinkingLoading &&
                  linkState.provider == AccountProvider.apple,
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() => _errorMessage = null);
                      AppLogger.i('CompleteProfileDialog: linkApple → upgradeInProgress=true');
                      ref
                          .read(profileUpgradeInProgressProvider.notifier)
                          .setInProgress(true);
                      linkingNotifier.linkApple();
                    },
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              border: null,
            ),
          ],
        ],
      ),
    );
  }
}
