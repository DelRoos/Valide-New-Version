import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';

class AppPillTabs extends StatelessWidget {
  const AppPillTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final tabCount = labels.length;
    assert(tabCount > 1, 'AppPillTabs nécessite au moins 2 onglets');
    assert(
      selectedIndex >= 0 && selectedIndex < tabCount,
      'selectedIndex hors bornes : $selectedIndex / $tabCount',
    );

    return Container(
      height: 44.h,
      padding: EdgeInsets.all(AppSpacing.s1.w),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / tabCount;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment(
                  tabCount == 1
                      ? 0
                      : (selectedIndex / (tabCount - 1)) * 2 - 1,
                  0,
                ),
                duration: AppMotion.fast,
                curve: AppMotion.standardOut,
                child: Container(
                  width: itemWidth,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppElevation.soft,
                  ),
                ),
              ),
              Row(
                children: List.generate(tabCount, (i) {
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (selected) return;
                        HapticFeedback.selectionClick();
                        onTabSelected(i);
                      },
                      child: Center(
                        child: Text(
                          labels[i],
                          style: AppTypography.caption.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.inkSoft,
                            fontSize: 13.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
