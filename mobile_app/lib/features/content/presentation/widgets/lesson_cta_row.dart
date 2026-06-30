import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class LessonCtaRow extends StatelessWidget {
  const LessonCtaRow({super.key, required this.isFr});

  final bool isFr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.primary,
                width: AppBorderWidth.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: AppIconSize.md,
                  color: AppColors.primary,
                ),
                SizedBox(width: AppSpacing.s1),
                Flexible(
                  child: Text(
                    isFr ? 'Résumé' : 'Summary',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.s3),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isFr ? 'Faire le quiz' : 'Take the quiz',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.card,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: AppSpacing.s1),
                Icon(
                  Icons.arrow_forward,
                  size: AppIconSize.md,
                  color: AppColors.card,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
