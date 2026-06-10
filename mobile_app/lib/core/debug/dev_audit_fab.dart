// Dev audit toolkit — bouton FAB + bottom sheet pour reset le state utilisateur
// pendant un audit du parcours d'onboarding.
//
// Pas une feature production : visible en haut a droite du dashboard. Tap ->
// ouvre un BottomSheet avec 2 actions destructives (clear local + delete
// account) qui delegent au [DevAuditService] (cf. dev_audit_service.dart).
//
// Extrait de dashboard_page.dart en juin 2026 (CLAUDE.md regle 12 max-lines).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/onboarding/providers.dart';
import '../firebase/providers.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import 'dev_audit_service.dart';

/// Bouton flottant FAB.small rouge "bug" affiche en haut a droite du
/// dashboard. Tap -> ouvre le [_DevAuditSheet] avec les 2 actions de reset.
class DevAuditFab extends ConsumerWidget {
  const DevAuditFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final navigator = Navigator.of(context);
    try {
      await op(_buildService());
      // INVALIDATION CRITIQUE : prefs.clear() vide le storage mais les
      // Notifier Riverpod gardent leur state in-memory (build() ne re-lit
      // les prefs qu'une fois au demarrage). Sans invalidate, le router
      // redirect voit l'ancien subSystem en memoire -> renvoie a /filiere
      // au lieu de /onboarding/subsystem.
      // 3 providers consommes par evaluateRedirect (cf. app_router.dart) :
      ref.invalidate(subSystemNotifierProvider);
      ref.invalidate(onboardingFlowProvider);
      ref.invalidate(profileCompletionProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('$label OK')),
      );
      if (mounted) {
        navigator.pop();
        GoRouter.of(context).go('/');
      }
    } catch (e) {
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
