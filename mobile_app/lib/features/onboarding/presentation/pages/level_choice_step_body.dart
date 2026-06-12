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

    return catalogueAsync.when(
      data: (snapshot) {
        final subSystemId = state.subSystem?.id;
        final trackId = state.trackId;
        if (subSystemId == null || trackId == null) {
          return _Message(text: l10n.errorCatalogueLoading);
        }

        final levels = snapshot.niveaux
            .where((n) =>
                n.isActive &&
                n.subSystem == subSystemId &&
                n.filiereIds.contains(trackId))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (levels.isEmpty) {
          return _Message(text: l10n.errorCatalogueEmpty);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.s5.h),
              Icon(LucideIcons.graduationCap,
                  size: 40.sp, color: AppColors.primary),
              SizedBox(height: AppSpacing.s4.h),
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
              SizedBox(height: AppSpacing.s5.h),
              for (final level in levels) ...[
                SelectionCard(
                  title: _localizedName(level, anglo: isAnglo),
                  selected: state.levelId == level.niveauId,
                  variant: SelectionCardVariant.compact,
                  onTap: () =>
                      _onLevelTap(notifier, snapshot, level.niveauId),
                ),
                SizedBox(height: AppSpacing.s2.h),
              ],
              SizedBox(height: AppSpacing.s5.h),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => _Message(text: l10n.errorCatalogueLoading),
    );
  }

  void _onLevelTap(
    dynamic notifier,
    CatalogueSnapshot snapshot,
    String niveauId,
  ) {
    final seriesForLevel =
        snapshot.series.where((s) => s.isActive && s.niveauId == niveauId);
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

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6.w),
        child: Text(
          text,
          style: AppTypography.body.copyWith(color: AppColors.inkSoft),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
