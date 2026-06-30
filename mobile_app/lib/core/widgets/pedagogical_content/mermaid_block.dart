part of '../pedagogical_content.dart';

class _MermaidBlock extends StatelessWidget {
  const _MermaidBlock({required this.source});

  final String source;

  String get _url {
    final bytes = utf8.encode(source);
    final b64 = base64UrlEncode(bytes).replaceAll('=', '');
    return 'https://mermaid.ink/img/$b64?type=png';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.s3.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: CachedNetworkImage(
          imageUrl: _url,
          fit: BoxFit.contain,
          placeholder: (_, _) => _MermaidLoading(),
          errorWidget: (_, _, _) => _MermaidError(source: source),
        ),
      ),
    );
  }
}

class _MermaidError extends StatelessWidget {
  const _MermaidError({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.s2.h),
          child: Text(
            'Diagramme indisponible (mode source ci-dessous)',
            style: AppTypography.meta.copyWith(color: AppColors.muted),
          ),
        ),
        _CodeBlock(language: 'mermaid', code: source),
      ],
    );
  }
}

class _MermaidLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
      child: Column(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
          ),
          SizedBox(height: AppSpacing.s2.h),
          Text(
            'Chargement diagramme…',
            style: AppTypography.meta.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
