// Story E1bis-4 — Step body 5 du shell onboarding refonte.
//
// AUTH CHOICE. 3 boutons : Google, Apple (iOS only), Visiteur.
// Reutilise AccountLinkingNotifier (Story 1.6) pour Google/Apple.
// Visiteur = firebaseAuth.signInAnonymously().
//
// Post-auth : setAuthProvider(displayName) sur OnboardingNotifier qui
// transitionne vers step 6 (saisie nom) ou step 7 (skip si OAuth a fourni
// le displayName).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/platform/platform_capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/auth/social_auth_widgets.dart';
import '../../../../core/widgets/auth/social_brand_icons.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/account_linking_failure.dart';
import '../../domain/account_linking_state.dart';
import '../../domain/linked_account.dart';
import '../../domain/profile_failure.dart';
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

    ref.listen<AccountLinkingState>(accountLinkingNotifierProvider,
        (prev, next) {
      if (next is AccountLinkingSuccess) {
        AppLogger.i(
          'auth.step5 success provider=${next.account.provider.id} '
          'hasDisplayName=${next.account.displayName != null}',
        );
        _onSocialSignInSuccess(next.account);
      }
    });

    final isLoading = linkState.isLoading || _guestLoading;
    final isAppleAvailable = isAppleSignInAvailable;

    final socialErrorMessage = _errorMessage(linkState);

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

            // Erreur flush visiteur (bug 8 fix) : banniere + bouton retry dedie.
            if (_guestError != null) ...[
              AuthErrorBanner(
                message: _guestError!,
                onDismiss: () => setState(() => _guestError = null),
              ),
              SizedBox(height: AppSpacing.s2.h),
              AppButton.secondary(
                label: l10n.retryLabel,
                icon: LucideIcons.refreshCw,
                onPressed: isLoading ? null : _onGuestTap,
              ),
              SizedBox(height: AppSpacing.s3.h),
            ],

            // Erreur social (Google / Apple).
            if (socialErrorMessage != null && _guestError == null) ...[
              AuthErrorBanner(
                message: socialErrorMessage,
                onDismiss: () {
                  linkingNotifier.reset();
                  setState(() => _guestError = null);
                },
              ),
              SizedBox(height: AppSpacing.s3.h),
            ],

            SocialButton(
              label: l10n.onboardingAuthGoogleLabel,
              iconWidget: const GoogleBrandIcon(),
              loading: linkState is AccountLinkingLoading &&
                  linkState.provider == AccountProvider.google,
              onPressed: isLoading ? null : linkingNotifier.linkGoogle,
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.ink,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            SizedBox(height: AppSpacing.s3.h),

            if (isAppleAvailable) ...[
              SocialButton(
                label: l10n.onboardingAuthAppleLabel,
                iconWidget: const AppleBrandIcon(color: Colors.white),
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

  /// Post sign-in social : recupere le profil Firestore existant (si present)
  /// et hydrate le state onboarding. Si le profil est complet, le router
  /// redirige automatiquement vers /dashboard via profileCompletionProvider.
  /// Si partiel ou absent, continue le flow onboarding au bon step.
  ///
  /// Bug 2 fix : si le reseau est coupe, fetchProfileOnce() retourne
  /// networkUnavailable. On NE traite PAS silencieusement l'utilisateur comme
  /// nouveau — son profil existant pourrait etre ecrase au flush. On bloque
  /// avec un message retry. Sur toute autre erreur (permission, etc.), on
  /// continue comme nouveau user (le profil n'existait probablement pas).
  Future<void> _onSocialSignInSuccess(LinkedAccount account) async {
    final onboardingNotifier = ref.read(onboardingNotifierProvider.notifier);
    final repo = ref.read(userProfileRepositoryProvider);
    final result = await repo.fetchProfileOnce();
    if (!mounted) return;

    final provider = account.provider == AccountProvider.google
        ? OnboardingAuthProvider.google
        : OnboardingAuthProvider.apple;

    await result.fold(
      (failure) async {
        AppLogger.w(
          'auth.step5 fetchProfileOnce failed kind=${failure.kind.name}',
        );
        if (failure.kind == ProfileFailureKind.networkUnavailable) {
          // Reseau coupe : on ne sait pas si l'utilisateur a un profil existant.
          // Afficher un message retry — l'utilisateur retappera Google/Apple
          // quand la connexion sera retablie.
          AppLogger.w(
            'auth.step5 network unavailable -> block, show retry message',
          );
          if (mounted) {
            setState(() => _guestError =
                AppLocalizations.of(context).errorNetworkUnavailable);
          }
          // Reset le linking state pour que les boutons soient de nouveau actifs.
          ref.read(accountLinkingNotifierProvider.notifier).reset();
        } else {
          // Erreur technique non-reseau : le profil n'existe probablement pas
          // (permission-denied = doc absent, unknown = premiere connexion).
          // On continue comme nouveau user — risque faible.
          AppLogger.w(
            'auth.step5 non-network error -> proceed as new user',
          );
          onboardingNotifier.setAuthProvider(
            provider,
            displayName: account.displayName,
          );
        }
      },
      (data) async {
        if (data != null) {
          AppLogger.i('auth.step5 existing profile found -> hydrate');
          await onboardingNotifier.hydrateFromFirestore(
            data,
            oauthDisplayName: account.displayName,
          );
          // profileCompletionProvider + router gere le bounce /dashboard
          // si le profil est complet. Sinon, hydrateFromFirestore pose le
          // bon step de reprise.
        } else {
          AppLogger.i('auth.step5 no existing profile -> new user');
          onboardingNotifier.setAuthProvider(
            provider,
            displayName: account.displayName,
          );
        }
      },
    );
  }

  // Audit 2026-06-15 — Mapping via failure.kind (CLAUDE.md regle 13) :
  // - cancelled             : silencieux (l'utilisateur a ferme le picker OAuth).
  // - unknown provider_not_supported : le compte est lie a un autre provider.
  // - unknown (autres)      : on n'expose pas le message technique brut.
  // - autres                : failure.message est deja localise en francais.
  String? _errorMessage(AccountLinkingState state) {
    if (state is! AccountLinkingError) return null;
    final failure = state.failure;
    return switch (failure.kind) {
      AccountLinkingFailureKind.cancelled => null,
      AccountLinkingFailureKind.unknown =>
        (failure.message.startsWith('provider_not_supported:'))
            ? AppLocalizations.of(context).onboardingAuthProviderNotSupported
            : AppLocalizations.of(context).errorGenericTitle,
      _ => failure.message,
    };
  }

  /// Flow visiteur (decision produit 2026-06-13 + audit PR2 2026-06-13) :
  ///   1. Si currentUser est non-anonyme -> modale de confirmation
  ///      "Continuer en visiteur va effacer ton compte". Annule si refuse.
  ///   2. Si confirme : delete doc users/{uid} + delete user account (best
  ///      effort) -> evite orphan Firestore (avant ce PR, signOut laissait
  ///      le doc precedent vivant et inaccessible).
  ///   3. signInAnonymously() Firebase Auth (nouvel uid anonyme propre)
  ///   4. setAuthProvider(guest) — pose isVisitor=true sans transitionner
  ///   5. flush direct users/{uid} (profil minimal : trackId + levelId +
  ///      isAnonymous=true + displayName='' + pickedSubjects)
  ///   6. GoRouter.go('/dashboard')
  ///
  /// Pas de page success/celebration pour le visiteur : la celebration
  /// est reservee aux comptes permanents qui ont saisi nom + phone + ecole.
  Future<void> _onGuestTap() async {
    final auth = ref.read(firebaseAuthProvider);
    final current = auth.currentUser;
    final needsConfirm = current != null && !current.isAnonymous;

    if (needsConfirm) {
      final confirmed = await _showGuestSwitchConfirm();
      if (!mounted) return;
      if (confirmed != true) {
        AppLogger.i('auth.step5 guest switch canceled by user');
        return;
      }
    }

    setState(() {
      _guestLoading = true;
      _guestError = null;
    });
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    try {
      await _ensureFreshAnonymousSession(auth, current);
      if (!mounted) return;

      final notifier = ref.read(onboardingNotifierProvider.notifier);
      notifier.setAuthProvider(OnboardingAuthProvider.guest);

      // Flush direct (pas de page success pour visiteur).
      final flushService = ref.read(onboardingFlushServiceProvider);
      final state = ref.read(onboardingNotifierProvider);
      final result = await flushService.flush(state);
      if (!mounted) return;

      result.fold(
        (failure) {
          AppLogger.w(
            'auth.step5 guest flush failed code=${failure.code} '
            'message="${failure.message}"',
          );
          setState(() => _guestError = l10n.onboardingFlushError);
        },
        (_) {
          AppLogger.i('auth.step5 guest flush OK -> /dashboard');
          router.go('/dashboard');
        },
      );
    } catch (e, st) {
      AppLogger.w('auth.step5 guest failed: $e', error: e);
      AppLogger.w('auth.step5 guest stack: $st');
      if (!mounted) return;
      setState(() => _guestError = l10n.errorGenericTitle);
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  /// Audit PR2 — Modale de confirmation destructive avant de switcher d'un
  /// compte OAuth vers visiteur. Retourne `true` si l'utilisateur confirme.
  Future<bool?> _showGuestSwitchConfirm() async {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.onboardingGuestSwitchTitle),
          content: Text(l10n.onboardingGuestSwitchBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.onboardingGuestSwitchCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.onboardingGuestSwitchConfirm),
            ),
          ],
        );
      },
    );
  }

  /// Garantit une session anonyme propre : reuse si deja anonyme, sinon
  /// cleanup orphan (delete doc + delete account best effort) + nouveau
  /// signInAnonymously. Audit PR2 — avant ce PR, le simple signOut laissait
  /// les docs users/{uid_oauth} orphelins.
  Future<void> _ensureFreshAnonymousSession(
    FirebaseAuth auth,
    User? current,
  ) async {
    if (current == null) {
      await auth.signInAnonymously();
      AppLogger.i('auth.step5 guest signInAnonymously (no current user)');
      return;
    }
    if (current.isAnonymous) {
      AppLogger.i(
        'auth.step5 guest reuse existing anonymous session '
        'uid=${current.uid.substring(0, 6)}...',
      );
      return;
    }
    // currentUser non-anonyme : l'utilisateur a confirme via la modale.
    // Cleanup orphan avant signOut pour eviter de laisser un doc vivant
    // sans propriétaire actif.
    AppLogger.w(
      'auth.step5 guest currentUser non-anonymous '
      '(providers=${current.providerData.map((p) => p.providerId).toList()}) '
      '-> cleanup orphan + new anonymous session',
    );
    await _cleanupOrphanProfile(current);
    await auth.signOut();
    await auth.signInAnonymously();
    AppLogger.i('auth.step5 guest re-signInAnonymously OK');
  }

  /// Best effort : delete doc users/{uid} + delete user account. Les echecs
  /// sont logues mais non bloquants — l'objectif premier est de signOut +
  /// nouvelle session anonyme, le cleanup orphan est un bonus.
  ///
  /// Note : `user.delete()` peut throw `requires-recent-login` pour les
  /// comptes OAuth ayant linkWithCredential il y a longtemps. Dans ce cas
  /// on log et continue (signOut suivant ferme la session, le doc orphelin
  /// sera nettoye via une future maintenance backend).
  Future<void> _cleanupOrphanProfile(User user) async {
    final uid = user.uid;
    final firestore = ref.read(firestoreProvider);
    try {
      await firestore.collection('users').doc(uid).delete();
      AppLogger.i(
        'auth.step5 guest cleanup users/{uid} deleted '
        'uid=${uid.substring(0, 6)}...',
      );
    } catch (e) {
      AppLogger.w('auth.step5 guest users/{uid} delete failed: $e');
    }
    try {
      await user.delete();
      AppLogger.i('auth.step5 guest cleanup user account deleted');
    } catch (e) {
      AppLogger.w(
        'auth.step5 guest user.delete() failed (non-blocking): $e',
      );
    }
  }
}
