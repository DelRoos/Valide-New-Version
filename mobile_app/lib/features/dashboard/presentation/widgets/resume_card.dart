import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Fake data — carte reprise uniquement
// ---------------------------------------------------------------------------

const _kLastLessonTitle = 'Dérivation et étude de fonctions';
const _kLastLessonChapter = 'Chapitre 3';
const _kLastLessonSubject = 'Mathématiques';
const _kLastLessonProgress = 0.60;
const _kLastLessonColor = Color(0xFF2563EB);

// ---------------------------------------------------------------------------
// Card reprendre — gradient couleur matière, dominante
// ---------------------------------------------------------------------------

class ResumeCard extends StatelessWidget {
  const ResumeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final pct = (_kLastLessonProgress * 100).round();
    final dark = Color.lerp(_kLastLessonColor, Colors.black, 0.35)!;

    return Material(
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kLastLessonColor, dark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            boxShadow: [
              BoxShadow(
                color: _kLastLessonColor.withValues(alpha: 0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.s5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chip matière + label chapitre
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2.w,
                      vertical: AppSpacing.s1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      _kLastLessonSubject.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.tiny,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _kLastLessonChapter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.caption,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s4.h),
              // Titre
              Text(
                _kLastLessonTitle,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.h2Compact,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.s5.h),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: _kLastLessonProgress,
                  minHeight: 6.h,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(height: AppSpacing.s3.h),
              // Stats + CTA
              Row(
                children: [
                  Text(
                    '$pct% lu',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4.w,
                        vertical: AppSpacing.s2.h,
                      ),
                      textStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      // Limite la largeur pour eviter l'overflow en test
                      // (fonts non chargees = metriques larges).
                      maximumSize: const Size(160, double.infinity),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.play, size: AppIconSize.md),
                        SizedBox(width: AppSpacing.s2.w),
                        const Flexible(
                          child: Text(
                            'Continuer',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
