// Story 1.2 — Page de choix du sous-système (premier écran utilisateur).
//
// Affiche 2 boutons primaires plein largeur (« Francophone » / « Anglophone »),
// aucun défaut suggéré (EXPERIENCE.md Flow 1 étape 2). Au tap : persistance
// SharedPreferences directe (via `subSystemNotifierProvider.set`) + log +
// navigation vers `/dashboard`. Pas de popup de confirmation V1 (l'avertissement
// d'irreversibilite est dans le sous-titre de la page, sufficient pour ADR-006).
//
// La locale `MaterialApp` bascule automatiquement : `LocaleNotifier` watch
// `subSystemNotifierProvider` (cf. app.dart Story 1.2 T4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/sub_system.dart';
import '../providers.dart';

// Au-delà de ce breakpoint (dp), on contraint la largeur du contenu pour ne
// pas étirer les boutons en plein écran tablette (NFR-17 responsive).
const double _kTabletBreakpoint = 840;
const double _kTabletMaxContentWidth = 480;

class SubsystemChoicePage extends ConsumerStatefulWidget {
  const SubsystemChoicePage({super.key});

  @override
  ConsumerState<SubsystemChoicePage> createState() =>
      _SubsystemChoicePageState();
}

class _SubsystemChoicePageState extends ConsumerState<SubsystemChoicePage> {
  bool _isProcessing = false;

  Future<void> _confirmChoice(SubSystem subSystem) async {
    if (_isProcessing) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    // Persiste + met à jour le state in-memory.
    // Riverpod notifiera LocaleNotifier (bascule MaterialApp.locale) +
    // GoRouter (re-évaluation du redirect via refreshListenable T6).
    await ref.read(subSystemNotifierProvider.notifier).set(subSystem);

    // CLAUDE.md § Sécurité : on log un boolean, JAMAIS l'uid complet.
    // Defensif : si Firebase n'est pas initialise (test ou degraded mode
    // cf. providers.dart firebaseAvailableProvider), on skip la lecture
    // auth — pas bloquant pour le flow.
    var hasAuth = false;
    if (ref.read(firebaseAvailableProvider)) {
      try {
        hasAuth = ref.read(firebaseAuthProvider).currentUser?.uid != null;
      } catch (_) {
        // ignore: Firebase indisponible -> hasAuth reste false
      }
    }
    AppLogger.i(
      'Subsystem chosen: ${subSystem.id}, anonymous auth: '
      '${hasAuth ? "present" : "absent"}',
    );

    if (!mounted) return;
    // `go` (pas `push`) pour empêcher le back Android de revenir au choix.
    // Story 1.9 : /dashboard remplace /hello — la garde Story 1.5 redirige
    // vers /onboarding/profile/filiere car le profil est encore vide.
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth >= _kTabletBreakpoint
                ? _kTabletMaxContentWidth
                : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5.w,
                    vertical: AppSpacing.s8.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.subsystemChoiceTitle,
                        style: AppTypography.h2,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s4.h),
                      Text(
                        l10n.subsystemChoiceSubtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s12.h),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          label: l10n.subsystemFrancophone,
                          onPressed: _isProcessing
                              ? null
                              : () => _confirmChoice(SubSystem.francophone),
                        ),
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          label: l10n.subsystemAnglophone,
                          onPressed: _isProcessing
                              ? null
                              : () => _confirmChoice(SubSystem.anglophone),
                        ),
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
}
