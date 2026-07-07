import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SubjectHeader extends StatelessWidget {
  const SubjectHeader({
    super.key,
    required this.subjectName,
    required this.subjectIcon,
    required this.eyebrow,
    required this.overallProgress,
    required this.rank,
    required this.onBack,
  });

  final String subjectName;
  final IconData subjectIcon;
  final String eyebrow;
  final int overallProgress;
  final int rank;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s2,
            AppSpacing.s1,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s2),
                      child: Icon(Icons.arrow_back, color: AppColors.card, size: AppIconSize.xl),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s2),
                      child: Icon(Icons.search, color: AppColors.card, size: AppIconSize.xl),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: AppSpacing.s10,
                    height: AppSpacing.s10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(subjectIcon, color: AppColors.card, size: AppIconSize.xl2),
                  ),
                  SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (eyebrow.isNotEmpty)
                          Text(
                            eyebrow,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: AppFontSize.eyebrow,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.5,
                            ),
                          ),
                        SizedBox(height: AppSpacing.s1),
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppFontSize.h2,
                            fontWeight: FontWeight.w900,
                            color: AppColors.card,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.subjectProgress,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.eyebrow,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: overallProgress / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.20),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                        minHeight: AppDimension.progressBarMed,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s2),
                  Text(
                    '$overallProgress%',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.meta,
                      fontWeight: FontWeight.w700,
                      color: AppColors.card,
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
