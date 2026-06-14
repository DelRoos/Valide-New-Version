// Dev audit toolkit — bouton FAB + bottom sheet pour reset le state utilisateur
// pendant un audit du parcours d'onboarding.
//
// Pas une feature production : visible en haut a droite du dashboard UNIQUEMENT
// en build debug/profile. En release, retourne SizedBox.shrink() (audit
// BUG-DEVBADGE 2026-06-13). Tap -> ouvre un BottomSheet avec 2 actions
// destructives (clear local + delete account) qui delegent au [DevAuditService]
// (cf. dev_audit_service.dart).
//
// Extrait de dashboard_page.dart en juin 2026 (CLAUDE.md regle 12 max-lines).

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/onboarding/presentation/state/onboarding_providers.dart';
import '../../features/onboarding/providers.dart';
import '../firebase/providers.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'dev_audit_service.dart';

/// Bouton flottant FAB.small rouge "bug" affiche en haut a droite du
/// dashboard. Tap -> ouvre le [_DevAuditSheet] avec les 2 actions de reset.
///
/// Audit BUG-DEVBADGE 2026-06-13 — Retourne `SizedBox.shrink()` en build
/// release pour ne PAS exposer un bouton destructif aux vrais utilisateurs.
/// Le code reste compilé pour minimiser le risque de bit-rot (tests utilisent
/// le widget directement, hors mode release).
class DevAuditFab extends ConsumerWidget {
  const DevAuditFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kReleaseMode) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.s2.h),
      child: FloatingActionButton.small(
        heroTag: 'dev-audit-fab',
        backgroundColor: AppColors.danger,
        tooltip: 'Dev audit (reset / delete)',
        onPressed: () => _showSheet(context, ref),
        child: const Icon(LucideIcons.bug, color: Colors.white),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _DevAuditSheet(),
    );
  }
}

class _DevAuditSheet extends ConsumerStatefulWidget {
  const _DevAuditSheet();

  @override
  ConsumerState<_DevAuditSheet> createState() => _DevAuditSheetState();
}

class _DevAuditSheetState extends ConsumerState<_DevAuditSheet> {
  bool _busy = false;

  DevAuditService _buildService() {
    return DevAuditService(
      auth: ref.read(firebaseAuthProvider),
      firestore: ref.read(firestoreProvider),
      prefs: ref.read(sharedPreferencesProvider),
    );
  }

  Future<void> _run(
    String label,
    Future<void> Function(DevAuditService svc) op,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);

    // Audit 2026-06-13 — Le dev FAB faisait `await op` PUIS pop + go. Mais
    // pendant `op`, `user.delete()` declenche un signOut Firebase qui propage
    // a `currentUserProvider` (StreamProvider authStateChanges) -> router
    // refresh -> redirect `/dashboard` -> `/onboarding/v2` AVANT que op ne
    // termine. Resultat : le modal bottomsheet disparait, l'utilisateur
    // arrive sur step 0 mais voit l'app en train de finir la suppression
    // (loaders aleatoires).
    //
    // Fix : pop le bottomsheet immediatement + afficher un dialog bloquant
    // sur le rootNavigator (sur-toute-route) qui reste visible jusqu'a la
    // fin de op. Le user voit "Suppression en cours..." pendant ~3-4s,
    // puis arrivee propre sur step 0.
    sheetNavigator.pop();
    unawaited(showDialog<void>(
      context: rootNavigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const _DeletingDialog(),
    ));

    try {
      await op(_buildService());
      // INVALIDATION CRITIQUE : prefs.clear() vide le storage mais les
      // Notifier Riverpod gardent leur state in-memory. Sans invalidate, le
      // router redirect voit l'ancien subSystem en memoire.
      ref.invalidate(subSystemNotifierProvider);
      ref.invalidate(profileCompletionProvider);
      ref.invalidate(onboardingNotifierProvider);
      ref.invalidate(currentUserProvider);

      // Pop le dialog bloquant.
      if (rootNavigator.canPop()) rootNavigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$label OK — redemarrage flow depuis le choix de section',
          ),
        ),
      );

      // Nav DIRECT a /onboarding/v2 (l'auto-redirect aurait deja amene la,
      // mais on force pour garantir step 0 quel que soit l'etat du router).
      router.go('/onboarding/v2');
    } catch (e) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('$label FAIL: $e')),
      );
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dev audit — parcours onboarding',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.s2.h),
            const Text(
              'Outils de debug pour re-iterer le parcours. Operations '
              'destructives — confirme avant de tap.',
            ),
            SizedBox(height: AppSpacing.s4.h),
            AppButton.primary(
              label: _busy ? 'En cours...' : 'Vider cache + sign out',
              onPressed: _busy
                  ? null
                  : () => _run(
                        'Clear local',
                        (svc) => svc.clearLocalAndSignOut(),
                      ),
              icon: LucideIcons.eraser,
            ),
            SizedBox(height: AppSpacing.s2.h),
            AppButton.secondary(
              label: _busy ? 'En cours...' : 'Supprimer compte + tout vider',
              onPressed: _busy
                  ? null
                  : () => _run(
                        'Delete account',
                        (svc) => svc.deleteAccountAndClear(),
                      ),
              icon: LucideIcons.trash2,
            ),
            SizedBox(height: AppSpacing.s2.h),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Audit 2026-06-13 — Dialog bloquant affiche sur le rootNavigator pendant
/// la suppression compte/local. Bloque le retour au step 0 tant que les
/// operations Firestore + Auth ne sont pas terminees, evitant le flicker
/// de l'ancienne UX (modal pop premature + UI en cours de cleanup visible).
class _DeletingDialog extends StatelessWidget {
  const _DeletingDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36.w,
                height: 36.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: AppSpacing.s4.h),
              Text(
                'Suppression en cours...',
                style: AppTypography.bodyStrong.copyWith(fontSize: 15.sp),
              ),
              SizedBox(height: AppSpacing.s2.h),
              Text(
                'Patiente quelques secondes',
                style: AppTypography.body.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
