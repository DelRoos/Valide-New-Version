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
          onCtaPressed: () =>
              ref.invalidate(appStartupCatalogueCheckProvider),
        ),
      ),
    );
  }
}
