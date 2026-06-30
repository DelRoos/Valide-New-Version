part of '../pedagogical_content.dart';

class _Citation extends StatelessWidget {
  const _Citation({required this.text, required this.textStyle});

  final String text;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s3.w,
          AppSpacing.s3.h,
          AppSpacing.s4.w,
          AppSpacing.s3.h,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.s2.w),
              child: Text(
                '"',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary.withValues(alpha: 0.20),
                  height: 0.80,
                ),
              ),
            ),
            Expanded(
              child: GptMarkdown(
                text,
                style: textStyle.copyWith(
                  color: AppColors.inkSoft,
                  fontStyle: FontStyle.italic,
                ),
                useDollarSignsForLatex: true,
                imageBuilder: PedagogicalContent._imageBuilder,
                codeBuilder: PedagogicalContent._codeBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
