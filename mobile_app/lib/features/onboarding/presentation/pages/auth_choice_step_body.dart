// Story E1bis-4 — Step body 5 du shell onboarding refonte.
//
// AUTH CHOICE. 3 boutons : Google, Apple (iOS only), Visiteur.
// Reutilise AccountLinkingNotifier (Story 1.6) pour Google/Apple.
// Visiteur = firebaseAuth.signInAnonymously().
//
// Post-auth : setAuthProvider(displayName) sur OnboardingNotifier qui
// transitionne vers step 6 (saisie nom) ou step 7 (skip si OAuth a fourni
// le displayName).

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/account_linking_state.dart';
import '../../domain/linked_account.dart';
import '../../providers.dart';
import '../state/onboarding_providers.dart';
import '../state/onboarding_state.dart';

class AuthChoiceStepBody extends ConsumerStatefulWidget {
  const AuthChoiceStepBody({super.key});

  @override
  ConsumerState<AuthChoiceStepBody> createState() => _AuthChoiceStepBodyState();
}

class _AuthChoiceStepBodyState extends ConsumerState<AuthChoiceStepBody> {
  bool _guestLoading = false;
  String? _guestError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linkState = ref.watch(accountLinkingNotifierProvider);
    final linkingNotifier = ref.read(accountLinkingNotifierProvider.notifier);
    final onboardingNotifier =
        ref.read(onboardingNotifierProvider.notifier);

    ref.listen<AccountLinkingState>(accountLinkingNotifierProvider,
        (prev, next) {
      if (next is AccountLinkingSuccess) {
        AppLogger.i(
          'auth.step5 success provider=${next.account.provider.id} '
          'hasDisplayName=${next.account.displayName != null}',
        );
        onboardingNotifier.setAuthProvider(
          next.account.provider == AccountProvider.google
              ? OnboardingAuthProvider.google
              : OnboardingAuthProvider.apple,
          displayName: next.account.displayName,
        );
      }
    });

    final isLoading = linkState.isLoading || _guestLoading;
    final isAppleAvailable = !kIsWeb && Platform.isIOS;

    final errorMessage = _errorMessage(linkState) ?? _guestError;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.s6.h),
            Icon(LucideIcons.userPlus, size: 48.sp, color: AppColors.primary),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              l10n.onboardingAuthTitle,
              style: AppTypography.h1.copyWith(fontSize: 24.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              l10n.onboardingAuthSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s6.h),

            if (errorMessage != null) ...[
              _AuthErrorBanner(
                message: errorMessage,
                onDismiss: () {
                  linkingNotifier.reset();
                  setState(() => _guestError = null);
                },
              ),
              SizedBox(height: AppSpacing.s3.h),
            ],

            _SocialButton(
              label: l10n.onboardingAuthGoogleLabel,
              iconData: LucideIcons.globe,
              loading: linkState is AccountLinkingLoading &&
                  linkState.provider == AccountProvider.google,
              onPressed: isLoading ? null : linkingNotifier.linkGoogle,
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.ink,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            SizedBox(height: AppSpacing.s3.h),

            if (isAppleAvailable) ...[
              _SocialButton(
                label: l10n.onboardingAuthAppleLabel,
                iconData: LucideIcons.apple,
                loading: linkState is AccountLinkingLoading &&
                    linkState.provider == AccountProvider.apple,
                onPressed: isLoading ? null : linkingNotifier.linkApple,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                border: null,
              ),
              SizedBox(height: AppSpacing.s3.h),
            ],

            SizedBox(height: AppSpacing.s2.h),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.s3.w),
                  child: Text(
                    l10n.onboardingAuthOrLabel,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.inkSoft),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: AppSpacing.s3.h),
            AppButton.secondary(
              label: l10n.onboardingAuthGuestLabel,
              icon: LucideIcons.compass,
              loading: _guestLoading,
              onPressed: isLoading ? null : _onGuestTap,
            ),
            SizedBox(height: AppSpacing.s5.h),
          ],
        ),
      ),
    );
  }

  String? _errorMessage(AccountLinkingState state) {
    if (state is AccountLinkingError) {
      final l10n = AppLocalizations.of(context);
      // failure.message est la traduction FR du _AccountLinkingXxx. On
      // l'utilise tel quel (les sous-types sont prives donc on ne peut pas
      // pattern-matcher publiquement).
      return state.failure.message.isNotEmpty
          ? state.failure.message
          : l10n.errorGenericTitle;
    }
    return null;
  }

  Future<void> _onGuestTap() async {
    setState(() {
      _guestLoading = true;
      _guestError = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      final auth = ref.read(firebaseAuthProvider);
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        AppLogger.i('auth.step5 guest signInAnonymously OK');
      } else {
        AppLogger.i('auth.step5 guest reuse existing anonymous session');
      }
      if (!mounted) return;
      ref
          .read(onboardingNotifierProvider.notifier)
          .setAuthProvider(OnboardingAuthProvider.guest);
    } catch (e, st) {
      AppLogger.w('auth.step5 guest failed: $e', error: e);
      AppLogger.w('auth.step5 guest stack: $st');
      if (!mounted) return;
      setState(() => _guestError = l10n.errorGenericTitle);
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.iconData,
    required this.loading,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.border,
  });

  final String label;
  final IconData iconData;
  final bool loading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(foregroundColor),
                  ),
                )
              else
                Icon(iconData, color: foregroundColor, size: 22.sp),
              SizedBox(width: AppSpacing.s3.w),
              Text(
                label,
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: 16.sp,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.s3.w),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.triangleAlert,
              color: AppColors.danger, size: 20),
          SizedBox(width: AppSpacing.s2.w),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.danger,
                fontSize: 13.sp,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18),
            color: AppColors.danger,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
