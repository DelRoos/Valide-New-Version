// Story 1.14 — Widget de regroupement visuel des sous-series Tle franco
// generale (12 sous-series) par famille pedagogique avec headers Lucide.
//
// Layout : `ListView` parent scrollable verticalement, pour chaque famille
// avec >=1 serie on rend un header (icone + label bilingue) suivi d'une
// `GridView` 3 cols compacte (shrinkWrap + NeverScrollable).
//
// Cas catch-all : les series hors mapping (ex. `francophone_terminale_a`
// v1 DEPRECATED si encore `isActive: true`) sont rendues dans une derniere
// section "Autres series" sans icone — graceful pour retrocompat.
//
// Extrait de serie_choice_page.dart en juin 2026 (CLAUDE.md regle 12).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../_serie_family.dart';

class SeriePickerGroupedByFamily extends StatelessWidget {
  const SeriePickerGroupedByFamily({
    super.key,
    required this.series,
    required this.langKey,
    required this.onSelect,
  });

  final List<Serie> series;
  final String langKey;
  final void Function(Serie) onSelect;

  @override
  Widget build(BuildContext context) {
    // Grouper les series par famille (preserve l'ordre d'entree trie par
    // sortOrder cote repository — iteration conserve l'insertion order).
    final Map<SerieFamily?, List<Serie>> grouped = {};
    for (final s in series) {
      final family = serieFamilyFor(s.serieId);
      grouped.putIfAbsent(family, () => []).add(s);
    }

    // Ordre fixe des familles (cf. EXPERIENCE.md Flow 1a Aissatou).
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

    // Catch-all pour les series hors mapping (famille == null) — place en bas.
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

  /// `null` pour la section catch-all "Autres series".
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
