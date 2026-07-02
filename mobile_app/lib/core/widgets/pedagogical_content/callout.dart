part of '../pedagogical_content.dart';

class _Callout extends StatefulWidget {
  const _Callout({
    required this.type,
    required this.body,
    required this.textStyle,
  });

  final String type;
  final String body;
  final TextStyle textStyle;

  static _CalloutStyle _styleFor(String type) {
    switch (type) {
      case 'definition':
        return const _CalloutStyle(
          bg: AppColors.primarySoft,
          border: AppColors.primary,
          label: 'DÉFINITION',
          icon: Icons.article_outlined,
          labelColor: AppColors.primary,
        );
      case 'theoreme':
      case 'theorem':
        return const _CalloutStyle(
          bg: Color(0xFFF5F3FF),
          border: Color(0xFF7C3AED),
          label: 'THÉORÈME',
          icon: Icons.auto_awesome,
          labelColor: Color(0xFF5B21B6),
        );
      case 'demonstration':
      case 'demo':
      case 'preuve':
        return const _CalloutStyle(
          bg: AppColors.skySoft,
          border: AppColors.sky,
          label: 'DÉMONSTRATION',
          icon: Icons.functions,
          labelColor: AppColors.skyInk,
        );
      case 'propriete':
      case 'prop':
      case 'property':
        return const _CalloutStyle(
          bg: AppColors.successSoft,
          border: AppColors.success,
          label: 'PROPRIÉTÉ',
          icon: Icons.check_circle_outline,
          labelColor: AppColors.successInk,
        );
      case 'methode':
      case 'method':
        return const _CalloutStyle(
          bg: Color(0xFFFFF7ED),
          border: Color(0xFFF97316),
          label: 'MÉTHODE',
          icon: Icons.format_list_numbered,
          labelColor: Color(0xFFC2410C),
        );
      case 'attention':
      case 'warning':
      case 'danger':
        return const _CalloutStyle(
          bg: AppColors.dangerSoft,
          border: AppColors.danger,
          label: 'ATTENTION',
          icon: Icons.error_outline,
          labelColor: AppColors.dangerInk,
        );
      case 'retenir':
      case 'recap':
        return const _CalloutStyle(
          bg: AppColors.warningSoft,
          border: AppColors.warning,
          label: 'À RETENIR',
          icon: Icons.lightbulb_outline,
          labelColor: AppColors.warningInk,
        );
      case 'exemple':
      case 'example':
        return const _CalloutStyle(
          bg: AppColors.bg,
          border: AppColors.border,
          label: 'EXEMPLE',
          icon: Icons.edit_note_outlined,
          labelColor: AppColors.muted,
        );
      case 'figure':
        return const _CalloutStyle(
          bg: Color(0xFFF0FDFA),
          border: Color(0xFF0D9488),
          label: 'FIGURE',
          icon: Icons.image_outlined,
          labelColor: Color(0xFF0F766E),
        );
      default:
        return const _CalloutStyle(
          bg: AppColors.bg,
          border: AppColors.border,
          label: 'NOTE',
          icon: Icons.info_outline,
          labelColor: AppColors.muted,
        );
    }
  }

  @override
  State<_Callout> createState() => _CalloutState();
}

class _CalloutState extends State<_Callout> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final s = _Callout._styleFor(widget.type);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: s.border.withValues(alpha: 0.35),
            width: AppBorderWidth.normal,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  color: s.border.withValues(alpha: 0.12),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3.w,
                    vertical: AppSpacing.s2.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.s1.w),
                        decoration: BoxDecoration(
                          color: s.border.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Icon(s.icon, size: AppIconSize.sm, color: s.labelColor),
                      ),
                      SizedBox(width: AppSpacing.s2.w),
                      Expanded(
                        child: Text(
                          s.label,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.eyebrow,
                            fontWeight: FontWeight.w800,
                            color: s.labelColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: AppIconSize.md,
                          color: s.labelColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Container(
                        width: double.infinity,
                        color: s.bg,
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.s3.w,
                          AppSpacing.s3.h,
                          AppSpacing.s3.w,
                          AppSpacing.s3.h,
                        ),
                        child: GptMarkdown(
                          widget.body,
                          style: widget.textStyle,
                          useDollarSignsForLatex: true,
                          imageBuilder: PedagogicalContent._imageBuilder,
                          codeBuilder: PedagogicalContent._codeBuilder,
                          latexBuilder: PedagogicalContent._latexBuilder,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalloutStyle {
  const _CalloutStyle({
    required this.bg,
    required this.border,
    required this.label,
    required this.icon,
    required this.labelColor,
  });

  final Color bg;
  final Color border;
  final String label;
  final IconData icon;
  final Color labelColor;
}
