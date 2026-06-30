// Shell persistent de l'app — wrappé par StatefulShellRoute dans app_router.dart.
//
// Un seul Scaffold pour les 4 onglets (Accueil / Cours / Examen / Profil).
// La NavigationBar est fixe : seul le body change quand on switche d'onglet,
// sans animation de page (goBranch remplace context.go).
//
// Style design system : AppColors.card + AppColors.primary + AppColors.muted
// selon token tokens.dart (pas de thème Material 3 par défaut).
//
// Tailles en dp bruts (pas de ScreenUtil) : la nav bar est un élément
// à hauteur fixe et ne doit pas scaler avec la résolution de l'écran.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: navigationShell,
      bottomNavigationBar: _StyledNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          // Re-tap sur l'onglet actif = remonter à la racine de la branche.
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          _NavDest(icon: LucideIcons.house, label: l10n.dashboardTabHome),
          _NavDest(
              icon: LucideIcons.bookOpen, label: l10n.dashboardTabSubjects),
          _NavDest(
              icon: LucideIcons.graduationCap,
              label: l10n.dashboardTabActivities),
          _NavDest(icon: LucideIcons.user, label: l10n.dashboardTabProfile),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _StyledNavBar extends StatelessWidget {
  const _StyledNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavDest> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppElevation.soft,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppNavBar.height,
          child: Row(
            children: List.generate(destinations.length, (i) {
              final dest = destinations[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onDestinationSelected(i),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  splashColor: AppColors.primarySoft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: AppMotion.standard,
                        curve: AppMotion.emphasized,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4,
                          vertical: AppSpacing.s1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primarySoft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Icon(
                          dest.icon,
                          size: AppNavBar.iconSize,
                          color: selected ? AppColors.primary : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: AppNavBar.iconLabelGap),
                      Text(
                        dest.label,
                        style: AppTypography.caption.copyWith(
                          fontSize: AppNavBar.labelSize,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primary : AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
