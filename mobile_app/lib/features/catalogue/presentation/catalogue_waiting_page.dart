// Écran bloquant « En attente de connexion » — Story 1.1c.
//
// Affiché par le redirect global du GoRouter quand
// `appStartupCatalogueCheckProvider` retourne `false` (Firestore vide ET cache
// offline vide — typique 1er lancement strictement hors-ligne).
//
// Pattern UX-DR-24 (loading/empty/error/offline). Réutilise `AppEmptyState`
// (Story 0.13) pour ne pas réinventer de widget custom.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/providers.dart';
import '../../../core/firebase/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';

class CatalogueWaitingPage extends ConsumerWidget {
  const CatalogueWaitingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: AppEmptyState(
          icon: LucideIcons.wifiOff,
          title: l.catalogueWaitingTitle,
          subtitle: l.catalogueWaitingMessage,
          ctaLabel: l.catalogueWaitingRetry,
          onCtaPressed: () => _onRetry(ref),
        ),
      ),
    );
  }

  /// Réessayer : (1) assure une session anonyme si le user a été signed out
  /// ou si le boot a couru avant que `signInAnonymously()` complete (race
  /// `_bootstrap` unawaited dans main.dart). Sans ça, les rules Firestore
  /// `read: if request.auth != null` refusent toutes les lectures catalogue
  /// et `hasNonEmptyCatalogue()` retourne false en boucle.
  /// (2) invalide le provider pour relancer le check.
  ///
  /// Defensif : si Firebase n'est pas initialise (tests widget, degraded
  /// mode Phase B pending), on skip l'auth et on invalide directement le
  /// provider. Pattern aligne sur subsystem_choice_page.dart:80.
  Future<void> _onRetry(WidgetRef ref) async {
    if (ref.read(firebaseAvailableProvider)) {
      try {
        final auth = ref.read(firebaseAuthProvider);
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
          AppLogger.i('CatalogueWaiting retry: signInAnonymously OK');
        }
      } catch (e) {
        AppLogger.w('CatalogueWaiting retry: signInAnonymously failed: $e');
      }
    }
    ref.invalidate(appStartupCatalogueCheckProvider);
  }
}
