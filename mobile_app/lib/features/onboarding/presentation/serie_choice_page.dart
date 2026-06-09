// Story 1.3 — Etape 3/3 du flow profil scolaire : choix serie.
//
// Liste des series filtrees par (subSystem, niveauId, filiereId). Layout
// conditionnel : <=5 series = AppPillTabs, >5 = GridView (cas Upper Sixth
// anglophone avec 13 series S1-S8 + A1-A5).

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
import '../domain/onboarding_flow_state.dart';
import '../providers.dart';
import '_serie_family.dart';
import 'onboarding_progress_header.dart';

const int _kPillTabsThreshold = 5;

class SerieChoicePage extends ConsumerWidget {
  const SerieChoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subSystem = ref.watch(subSystemNotifierProvider);
    final flow = ref.watch(onboardingFlowProvider);

    // Guard : si niveau manquant, redirect vers niveau.
    if (subSystem == null || flow.filiereId == null || flow.niveauId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).go('/onboarding/profile/niveau');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final seriesAsync = ref.watch(
      _seriesStreamProvider(
        _SeriesQuery(
          subSystem: subSystem.id,
          niveauId: flow.niveauId!,
          filiereId: flow.filiereId!,
        ),
      ),
    );

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
                      _BackBar(
                        onBack: () {
                          ref
                              .read(onboardingFlowProvider.notifier)
                              .backTo(OnboardingFlowStep.serie);
                          GoRouter.of(context)
                              .go('/onboarding/profile/niveau');
                        },
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      const OnboardingProgressHeader(step: 3, total: 3),
                      SizedBox(height: AppSpacing.s5.h),
                      Text(
                        l10n.onboardingSerieTitle,
                        style: AppTypography.h2,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s2.h),
                      Text(
                        l10n.onboardingSerieSubtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s6.h),
                      Expanded(
                        child: seriesAsync.when(
                          data: (series) => _SeriesPicker(
                            series: series,
                            langKey: subSystem.languageCode,
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

class _SeriesQuery {
  const _SeriesQuery({
    required this.subSystem,
    required this.niveauId,
    required this.filiereId,
  });
  final String subSystem;
  final String niveauId;
  final String filiereId;

  @override
  bool operator ==(Object other) =>
      other is _SeriesQuery &&
      other.subSystem == subSystem &&
      other.niveauId == niveauId &&
      other.filiereId == filiereId;

  @override
  int get hashCode => Object.hash(subSystem, niveauId, filiereId);
}

// Story 1.13 — refactor StreamProvider.family -> FutureProvider.family suite
// audit règle 10.g CLAUDE.md. AsyncValue consumer-side inchangé.
final _seriesStreamProvider =
    FutureProvider.family<List<Serie>, _SeriesQuery>((ref, query) {
  return ref.watch(catalogueRepositoryProvider).fetchSeries(
        subSystem: query.subSystem,
        niveauId: query.niveauId,
        filiereId: query.filiereId,
      );
});

class _SeriesPicker extends ConsumerWidget {
  const _SeriesPicker({required this.series, required this.langKey});

  final List<Serie> series;
  final String langKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (series.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).emptyStateGeneric,
          style: AppTypography.body,
        ),
      );
    }

    void onSelect(Serie s) {
      ref.read(onboardingFlowProvider.notifier).selectSerie(s.serieId);
      GoRouter.of(context).go('/onboarding/profile/recap');
    }

    // Story 1.14 — dispatch heuristique pour le cas Tle francophone générale
    // (12 sous-séries A1-A5/ABI/SH/AC/C/D/E/TI). Si ≥6 séries ET ≥50 % d'entre
    // elles ont une famille définie, on active le layout groupé par famille
    // avec headers + icônes Lucide. Sinon (Upper Sixth anglo S/A, Premiere
    // franco, TVEE, autres), on tombe sur le layout v1 ci-dessous.
    final familyCount =
        series.where((s) => serieFamilyFor(s.serieId) != null).length;
    if (series.length >= 6 && familyCount >= (series.length / 2).ceil()) {
      return _SeriesGroupedByFamily(
        series: series,
        langKey: langKey,
        onSelect: onSelect,
      );
    }

    // Layout conditionnel : <= 5 series, on affiche en grille de cartes
    // verticales pour respecter le pattern (PillTabs serait illisible si
    // les labels sont longs). > 5 series : GridView 3 colonnes compact.
    if (series.length <= _kPillTabsThreshold) {
      return ListView.separated(
        itemCount: series.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3.h),
        itemBuilder: (context, index) {
          final s = series[index];
          return AppCard(
            onTap: () => onSelect(s),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.name[langKey] ?? s.name['fr'] ?? s.serieId,
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
          );
        },
      );
    }

    // > 5 series : GridView 3 colonnes
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.s3.w,
        mainAxisSpacing: AppSpacing.s3.h,
        childAspectRatio: 1.4,
      ),
      itemCount: series.length,
      itemBuilder: (context, index) {
        final s = series[index];
        return AppCard(
          onTap: () => onSelect(s),
          padding: EdgeInsets.all(AppSpacing.s3.w),
          child: Center(
            child: Text(
              s.name[langKey] ?? s.name['fr'] ?? s.serieId,
              style: AppTypography.bodyStrong,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

/// Story 1.14 — Widget de regroupement visuel des sous-séries Tle franco
/// générale (12 sous-séries) par famille pédagogique avec headers Lucide.
///
/// Layout : `ListView` parent scrollable verticalement, pour chaque famille
/// avec ≥1 série on rend un header (icône + label bilingue) suivi d'une
/// `GridView` 3 cols compacte (shrinkWrap + NeverScrollable).
///
/// Cas catch-all : les séries hors mapping (ex. `francophone_terminale_a`
/// v1 DEPRECATED si encore `isActive: true`) sont rendues dans une dernière
/// section "Autres séries" sans icône — graceful pour rétrocompat.
class _SeriesGroupedByFamily extends StatelessWidget {
  const _SeriesGroupedByFamily({
    required this.series,
    required this.langKey,
    required this.onSelect,
  });

  final List<Serie> series;
  final String langKey;
  final void Function(Serie) onSelect;

  @override
  Widget build(BuildContext context) {
    // Grouper les séries par famille (preserve l'ordre d'entrée trié par
    // sortOrder côté repository — itération conserve l'insertion order).
    final Map<SerieFamily?, List<Serie>> grouped = {};
    for (final s in series) {
      final family = serieFamilyFor(s.serieId);
      grouped.putIfAbsent(family, () => []).add(s);
    }

    // Ordre fixe des familles (cf. EXPERIENCE.md Flow 1a Aïssatou).
    const orderedFamilies = [
      SerieFamily.lettres,
      SerieFamily.sciencesHumaines,
      SerieFamily.sciences,
      SerieFamily.sciencesTechniques,
    ];

    final children = <Widget>[];
    for (final family in orderedFamilies) {
      final familySeries = grouped[family];
      if (familySeries == null || familySeries.isEmpty) continue;
      children.add(_FamilySection(
        family: family,
        series: familySeries,
        langKey: langKey,
        onSelect: onSelect,
      ));
    }

    // Catch-all pour les séries hors mapping (famille == null) — placé en bas.
    final otherSeries = grouped[null];
    if (otherSeries != null && otherSeries.isNotEmpty) {
      children.add(_FamilySection(
        family: null,
        series: otherSeries,
        langKey: langKey,
        onSelect: onSelect,
      ));
    }

    return ListView(
      children: children,
    );
  }
}

class _FamilySection extends StatelessWidget {
  const _FamilySection({
    required this.family,
    required this.series,
    required this.langKey,
    required this.onSelect,
  });

  /// `null` pour la section catch-all "Autres séries".
  final SerieFamily? family;
  final List<Serie> series;
  final String langKey;
  final void Function(Serie) onSelect;

  @override
  Widget build(BuildContext context) {
    final String headerLabel = family != null
        ? (langKey == 'en' ? family!.labelEn : family!.labelFr)
        : (langKey == 'en'
            ? kSerieFamilyOtherLabelEn
            : kSerieFamilyOtherLabelFr);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.s5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s3.h),
            child: Row(
              children: [
                if (family != null) ...[
                  Icon(family!.icon, size: 22.sp, color: AppColors.ink),
                  SizedBox(width: AppSpacing.s2.w),
                ],
                Text(headerLabel, style: AppTypography.h3),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.s3.w,
              mainAxisSpacing: AppSpacing.s3.h,
              childAspectRatio: 1.4,
            ),
            itemCount: series.length,
            itemBuilder: (context, index) {
              final s = series[index];
              return AppCard(
                onTap: () => onSelect(s),
                padding: EdgeInsets.all(AppSpacing.s3.w),
                child: Center(
                  child: Text(
                    s.name[langKey] ?? s.name['fr'] ?? s.serieId,
                    style: AppTypography.bodyStrong,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onBack,
        icon: Icon(LucideIcons.arrowLeft, size: 24.sp, color: AppColors.ink),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
      ),
    );
  }
}
