part of '../pedagogical_content.dart';

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120.h,
      color: AppColors.muted.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24.w,
        height: 24.h,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.s3.w),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.dangerInk),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.dangerInk),
          SizedBox(width: AppSpacing.s2.w),
          Flexible(
            child: Text(
              'Image indisponible',
              style: AppTypography.meta.copyWith(color: AppColors.dangerInk),
            ),
          ),
        ],
      ),
    );
  }
}
