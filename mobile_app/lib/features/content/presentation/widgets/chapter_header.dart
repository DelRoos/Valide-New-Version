import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/segmented_tab_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ChapterHeader extends StatelessWidget {
  const ChapterHeader({
    super.key,
    required this.chapterOrder,
    required this.chapterTitle,
    required this.subjectAbbrev,
    required this.progressPercent,
    required this.tabLabels,
    required this.selectedTabIndex,
    required this.onTabTap,
    required this.onBack,
  });

  final int chapterOrder;
  final String chapterTitle;
  final String subjectAbbrev;
  final int progressPercent;
  final List<String> tabLabels;
  final int selectedTabIndex;
  final ValueChanged<int> onTabTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s2),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.ink,
                    size: AppIconSize.xl,
                  ),
                ),
              ),
              Container(
                width: AppSpacing.s6,
                height: AppSpacing.s6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$chapterOrder',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w800,
                    color: AppColors.card,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  l10n.chapterEyebrow(subjectAbbrev, chapterOrder),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.eyebrow,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s2),
                  child: Icon(
                    Icons.favorite_border,
                    color: AppColors.warning,
                    size: AppIconSize.xl,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            child: Text(
              chapterTitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.h2,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.s3),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            child: _ProgressBar(percent: progressPercent),
          ),
          SizedBox(height: AppSpacing.s3),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            child: SegmentedTabBar(
              labels: tabLabels,
              selectedIndex: selectedTabIndex,
              onTap: onTabTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.s2),
        Text(
          '$percent%',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.meta,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

