part of '../pedagogical_content.dart';

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.language, required this.code});

  final String language;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (language.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3.w,
                  vertical: AppSpacing.s1.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    topRight: Radius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  language,
                  style: AppTypography.meta.copyWith(
                    color: AppColors.muted,
                    fontFamily: AppTypography.monoFontFamily,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.s3.w),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  code,
                  style: AppTypography.body.copyWith(
                    fontFamily: AppTypography.monoFontFamily,
                    fontSize: 13.sp,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
