// Story 1.9 — Bottom tab bar Material 3 partage par DashboardPage et
// PlaceholderTabPage. Pattern V1 : chaque page expose son propre Scaffold
// avec son `bottomNavigationBar`, pas de StatefulShellRoute (refactor possible
// Epic 2 quand les onglets auront du state interne).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _routes = ['/dashboard', '/matieres', '/activites', '/profil'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        if (i == currentIndex) return;
        GoRouter.of(context).go(_routes[i]);
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(LucideIcons.house),
          label: l10n.dashboardTabHome,
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.bookOpen),
          label: l10n.dashboardTabSubjects,
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.dumbbell),
          label: l10n.dashboardTabActivities,
        ),
        NavigationDestination(
          icon: const Icon(LucideIcons.user),
          label: l10n.dashboardTabProfile,
        ),
      ],
    );
  }
}
