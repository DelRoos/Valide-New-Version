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

/// Dialogue affiché automatiquement sur la tab Profil pour les visiteurs
/// anonymes. Propose de lier un compte Google ou Apple directement.
///
/// Dismissible par tap hors dialogue ou changement de tab — le visiteur
/// peut continuer à naviguer dans l'app. Ré-apparaît à chaque visite
/// de la tab Profil (piloté par ProfileTabPage._dialogShown reset en deactivate).
class CompleteProfileDialog extends ConsumerStatefulWidget {
  const CompleteProfileDialog._({this.onLinked});

  /// Callback exécuté (via postFrameCallback) après succès du linking.
  /// Permet à l'appelant de chaîner une action (compléter le profil,
  /// reprendre l'action bloquée, etc.).
  final VoidCallback? onLinked;

  /// Affiche le dialogue.
  ///
  /// [onLinked] est appelé juste après la fermeture du dialogue si le compte
  /// a bien été lié (AccountLinkingSuccess). Utiliser ce paramètre pour
  /// enchaîner une action (ex. ouvrir le bottom sheet d'édition de profil).
  static Future<void> show(BuildContext context, {VoidCallback? onLinked}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (_) => CompleteProfileDialog._(onLinked: onLinked),
    );
  }

  /// Affiche le dialogue uniquement si l'utilisateur est anonyme.
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
    return show(context, onLinked: onLinked);
  }

  /// Garde générique : si l'utilisateur est anonyme → dialogue ;
  /// sinon → exécute [action] immédiatement.
  ///
  /// Si le dialogue aboutit à un linking, [action] est exécutée une fois
  /// le dialogue fermé (postFrameCallback), assurant la continuité UX.
  ///
  /// orElse: () => false : pendant le chargement du stream auth, on laisse
  /// passer l'action plutôt que de bloquer — un utilisateur qui voit ses
  /// données de profil chargées est forcément authentifié.
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
      return show(context, onLinked: action);
    }
    action();
    return Future.value();
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
      if (next is AccountLinkingSuccess) {
        if (mounted) {
          // credential-already-in-use -> signInWithCredential peut changer
          // l'uid Firebase, ce qui déclenche un go('/onboarding') du routeur
          // avant que ce pop() s'exécute. GoRouter lève une assertion si sa
          // pile est vide — on absorbe silencieusement cette race condition.
          try {
            Navigator.of(context).pop();
          } catch (_) {
            AppLogger.d('CompleteProfileDialog: pop absorbed — GoRouter race condition');
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onLinked?.call();
          });
        }
        return;
      }
      if (next is AccountLinkingError) {
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
      onClose: () => Navigator.of(context).pop(),
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
