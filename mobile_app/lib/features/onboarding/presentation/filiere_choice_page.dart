// Story 1.3 — Etape 1/3 du flow profil scolaire : choix filiere.
//
// 2 cartes cliquables (Generale / Technique) lues depuis Firestore via
// CatalogueRepository.watchFilieres() (filtre isActive == true).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/domain/models.dart';
import '../../../core/catalogue/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers.dart';
import 'onboarding_progress_header.dart';

class FiliereChoicePage extends ConsumerWidget {
  const FiliereChoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filieresAsync = ref.watch(filieresStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 720 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5.w,
                    vertical: AppSpacing.s6.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OnboardingProgressHeader(step: 1, total: 3),
                      SizedBox(height: AppSpacing.s5.h),
                      Text(
                        l10n.onboardingFiliereTitle,
                        style: AppTypography.h2,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s8.h),
                      Expanded(
                        child: filieresAsync.when(
                          data: (filieres) => _FilieresList(
                            filieres: filieres,
                            isTablet: isTablet,
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, st) => Center(
                            child: Text(
                              l10n.errorGeneric,
                              style: AppTypography.body.copyWith(
                                color: AppColors.danger,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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

/// FutureProvider — Story 1.13 refactor `StreamProvider` -> `FutureProvider`
/// suite à audit règle 10.g CLAUDE.md (catalogue statique → pas besoin de
/// stream actif, cache offline natif Firestore suffit). Le widget continue
/// à recevoir un `AsyncValue<List<Filiere>>` (API consumer-side inchangée).
final filieresStreamProvider = FutureProvider<List<Filiere>>((ref) {
  return ref.watch(catalogueRepositoryProvider).fetchFilieres();
});

class _FilieresList extends ConsumerWidget {
  const _FilieresList({required this.filieres, required this.isTablet});

  final List<Filiere> filieres;
  final bool isTablet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filieres.isEmpty) {
      // Cas tres rare : catalogue Firestore vide. Le router redirigera vers
      // /catalogue-waiting automatiquement (refreshListenable Story 1.1c),
      // mais on affiche aussi un message local au cas ou.
      return Center(
        child: Text(
          AppLocalizations.of(context).emptyStateGeneric,
          style: AppTypography.body,
        ),
      );
    }

    // Choisi la langue d'affichage selon le sous-systeme — par defaut FR
    // (le widget peut etre rendu avant que la locale soit completement
    // basculee, mais subSystem est garantee posee a ce stade Story 1.2).
    final subSystem = ref.watch(subSystemNotifierProvider);
    final langKey = subSystem?.languageCode ?? 'fr';

    final children = filieres
        .map(
          (f) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s4.h),
            child: AppCard(
              onTap: () {
                ref
                    .read(onboardingFlowProvider.notifier)
                    .selectFiliere(f.filiereId);
                GoRouter.of(context).go('/onboarding/profile/niveau');
              },
              child: Row(
                children: [
                  Icon(
                    f.filiereId == 'technique'
                        ? LucideIcons.wrench
                        : LucideIcons.graduationCap,
                    size: 32.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.s4.w),
                  Expanded(
                    child: Text(
                      f.name[langKey] ?? f.name['fr'] ?? f.filiereId,
                      style: AppTypography.h3,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 24.sp,
                    color: AppColors.mute2,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(growable: false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
