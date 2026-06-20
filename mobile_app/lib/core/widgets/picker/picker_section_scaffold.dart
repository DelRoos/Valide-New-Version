// Wrapper structurel responsive page-level des pickers (subjects, schools).
// Extrait du pattern repete 4x dans subjects_picker_page.dart (Stories 1.4 +
// 1.15 + 1.16 + 1.17) lors de la Story 1.18 (refactor extractif _Body).
//
// Pattern : LayoutBuilder + Center + ConstrainedBox(tablet 720dp max) +
// Padding(horiz s5.w / vert s6.h) + Column(stretch) [titre H2 + sous-titre
// optionnel + child].
//
// Breakpoint tablet : 840 dp (CLAUDE.md regle 3 / 5 durcie).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/tokens.dart';

class PickerSectionScaffold extends StatelessWidget {
  const PickerSectionScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.tabletBreakpoint = 840,
    this.tabletMaxWidth = 720,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double tabletBreakpoint;
  final double tabletMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= tabletBreakpoint;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? tabletMaxWidth : double.infinity,
            ),
            // Audit 2026-06-15 — padding horizontal s5.w deplace vers la
            // section titre uniquement. Le child (scroll list, picker, etc.)
            // est pleine largeur : il gere sa propre marge interne pour
            // laisser respirer les ombres/animations sans doubler le padding
            // du titre (was 20dp + 8dp = 28dp, now titre=20dp, cards=8dp).
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s5.w,
                    AppSpacing.s1.h,
                    AppSpacing.s5.w,
                    AppSpacing.s3.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: AppTypography.h2),
                      if (subtitle != null) ...[
                        SizedBox(height: AppSpacing.s2.h),
                        Text(
                          subtitle!,
                          style: AppTypography.body.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}
