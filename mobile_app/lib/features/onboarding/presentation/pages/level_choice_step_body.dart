// Story E1bis-3 — Step body 3 du shell onboarding refonte.
//
// LEVEL CHOICE (Niveau scolaire). Lit `niveaux` du catalogueProvider existant
// et filtre par subSystem + trackId. Determine `requiresPicker` selon les
// series disponibles pour ce niveau (any.pickerMode != derived = requiresPicker).
//
// Mapping local : Niveau (model domain Epic 1) -> variables level* cote
// E1bis. Rename global Story 1.19.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
import '../../../../core/widgets/feedback/onboarding_loader.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../state/onboarding_providers.dart';

class LevelChoiceStepBody extends ConsumerWidget {
  const LevelChoiceStepBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final catalogueAsync = ref.watch(catalogueProvider);
    final isAnglo = state.subSystem == SubSystem.anglophone;

    // Audit 2026-06-14 — Header (icone + titre + sous-titre) TOUJOURS rendu,
    // meme pendant loading/error. Sans ca, un ErrorRetryView cachait tout le
    // contexte (utilisateur ne savait plus quel choix etait attendu).
    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppSpacing.s2.h),
          Icon(LucideIcons.graduationCap,
              size: 36.sp, color: AppColors.primary),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            l10n.onboardingLevelTitle,
            style: AppTypography.h1.copyWith(fontSize: 22.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            l10n.onboardingLevelSubtitle,
            style: AppTypography.body.copyWith(
              fontSize: 13.sp,
              color: AppColors.inkSoft,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return Column(
      children: [
        header,
        Expanded(
          child: catalogueAsync.when(
            data: (snapshot) {
              final subSystemId = state.subSystem?.id;
              if (subSystemId == null) {
                return ErrorRetryView(
                  onRetry: () => ref.invalidate(catalogueProvider),
                );
              }

              // Audit 2026-06-13 — Filtrer aussi par trackId quand il est pose.
              // Avant ce fix, on affichait tous les niveaux du sub-system, ce qui
              // permettait a un user Anglo + Technique de choisir Form 5 (qui est
              // generale uniquement) -> step 4 renvoyait "No stream available"
              // car la serie form_5_olevel a filiereId=generale != track.
              // La verite est dans niveau.filiereIds (cf. matrice.json).
              final trackId = state.trackId;
              final levels = snapshot.niveaux
                  .where((n) =>
                      n.isActive &&
                      n.subSystem == subSystemId &&
                      (trackId == null || n.filiereIds.contains(trackId)))
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

              if (levels.isEmpty) {
                // Audit 2026-06-14 — Discriminer 2 cas :
                // (a) trackId pose mais 0 niveaux match -> filiere choisie
                //     incomplete cote seed (ex. anglo+technique = TVE non seede
                //     en MVP). Le retry catalogue ne resoudra rien : guider
                //     vers le back step 2 pour changer de filiere.
                // (b) trackId null + 0 niveaux -> catalogue vide reel -> retry.
                if (trackId != null) {
                  return _LevelEmptyForTrack(
                    title: l10n.onboardingLevelEmptyForTrackTitle,
                    body: l10n.onboardingLevelEmptyForTrackBody,
                    changeTrackLabel:
                        l10n.onboardingLevelEmptyForTrackChangeTrack,
                    onChangeTrack: () => notifier.back(),
                  );
                }
                return ErrorRetryView(
                  onRetry: () => ref.invalidate(catalogueProvider),
                  message: l10n.errorCatalogueEmpty,
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: AppSpacing.s3.h),
                    for (final level in levels) ...[
                      SelectionCard(
                        title: _localizedName(level, anglo: isAnglo),
                        selected: state.levelId == level.niveauId,
                        variant: SelectionCardVariant.compact,
                        showRadio: false,
                        onTap: () => _onLevelTap(
                            ref, notifier, snapshot, level.niveauId),
                      ),
                      SizedBox(height: AppSpacing.s2.h),
                    ],
                    SizedBox(height: AppSpacing.s3.h),
                  ],
                ),
              );
            },
            loading: () => OnboardingLoader(label: l10n.onboardingLoaderLabel),
            error: (e, st) => ErrorRetryView(
              onRetry: () => ref.invalidate(catalogueProvider),
              kind: ErrorRetryKind.offline,
            ),
          ),
        ),
      ],
    );
  }

  void _onLevelTap(
    WidgetRef ref,
    dynamic notifier,
    CatalogueSnapshot snapshot,
    String niveauId,
  ) {
    // Audit 2026-06-13 — Filtrer seriesForLevel par trackId quand pose, sinon
    // requiresPicker peut etre true pour un track auquel le niveau ne
    // s'applique pas (Form 5 generale avec track technique).
    final trackId = ref.read(onboardingNotifierProvider).trackId;
    final seriesForLevel = snapshot.series.where((s) =>
        s.isActive &&
        s.niveauId == niveauId &&
        (trackId == null || s.filiereId == trackId));
    final requiresPicker =
        seriesForLevel.any((s) => s.pickerMode != PickerMode.derived) ||
            seriesForLevel.length > 1;
    notifier.setLevelId(niveauId, requiresPicker: requiresPicker);
  }

  String _localizedName(Niveau n, {required bool anglo}) {
    final key = anglo ? 'en' : 'fr';
    return n.name[key] ?? n.name.values.first;
  }
}

/// Audit 2026-06-14 — Fallback dedie quand le user a choisi une filiere
/// (track) pour laquelle 0 niveaux sont seedes actifs. Cas typique : anglo
/// + technique (TVE non seede en MVP). Le CTA primaire ramene step 3 -> 2
/// pour permettre de changer de filiere ; pas de "Reessayer le catalogue"
/// car ca ne resoudra rien (le catalogue est bien charge).
class _LevelEmptyForTrack extends StatelessWidget {
  const _LevelEmptyForTrack({
    required this.title,
    required this.body,
    required this.changeTrackLabel,
    required this.onChangeTrack,
  });

  final String title;
  final String body;
  final String changeTrackLabel;
  final VoidCallback onChangeTrack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.compass,
              size: 48.sp,
              color: AppColors.inkSoft,
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              title,
              style: AppTypography.h3.copyWith(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              body,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            FilledButton.icon(
              onPressed: onChangeTrack,
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              label: Text(changeTrackLabel),
            ),
          ],
        ),
      ),
    );
  }
}
