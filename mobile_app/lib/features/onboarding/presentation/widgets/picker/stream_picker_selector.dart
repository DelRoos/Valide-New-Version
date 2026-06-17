import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/catalogue/domain/models.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/cards/selection_card.dart';

/// Stream picker : liste verticale de SelectionCard pour choisir une serie.
/// Tap card = commit immediat (setStreamIdDraft) + transition vers la vue
/// derivee. Pas de CTA Continuer intermediaire.
class StreamPicker extends StatelessWidget {
  const StreamPicker({
    super.key,
    required this.streams,
    required this.langKey,
    required this.onConfirm,
  });

  final List<Serie> streams;
  final String langKey;
  final void Function(String streamId) onConfirm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s3.h),
          for (final stream in streams) ...[
            SelectionCard(
              title: stream.name[langKey] ?? stream.name.values.first,
              description: stream.descriptionFor(langKey),
              selected: false,
              variant: SelectionCardVariant.standard,
              showRadio: false,
              onTap: () => onConfirm(stream.serieId),
            ),
            SizedBox(height: AppSpacing.s2.h),
          ],
          SizedBox(height: AppSpacing.s4.h),
        ],
      ),
    );
  }
}

/// Fallback affiche quand `streams.isEmpty` pour un niveau qui requiert un
/// picker mais n'a aucune serie dans le catalogue. Evite le message trompeur
/// "Chargement impossible" qui suggere a tort un probleme reseau.
class StreamPickerEmpty extends StatelessWidget {
  const StreamPickerEmpty({
    super.key,
    required this.title,
    required this.body,
    required this.changeLevelLabel,
    required this.retryLabel,
    required this.onChangeLevel,
    required this.onRetry,
  });

  final String title;
  final String body;
  final String changeLevelLabel;
  final String retryLabel;
  final VoidCallback onChangeLevel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.searchX,
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
              onPressed: onChangeLevel,
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              label: Text(changeLevelLabel),
            ),
            SizedBox(height: AppSpacing.s2.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
