import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';

class ProfileMenuItemData {
  const ProfileMenuItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
}

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ProfileMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.eyebrow.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.eyebrow,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: AppSpacing.s2.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppElevation.soft,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: AppBorderWidth.hairline,
                    color: AppColors.border,
                    indent: AppSpacing.s4.w + AppSpacing.s10,
                  ),
                _MenuItem(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});

  final ProfileMenuItemData item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s4.w,
          vertical: AppSpacing.s4.h,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.s10,
              height: AppSpacing.s10,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(item.icon, size: AppIconSize.md, color: item.color),
            ),
            SizedBox(width: AppSpacing.s3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.body.copyWith(
                      color: AppColors.ink,
                      fontSize: AppFontSize.body,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: AppSpacing.s1.h),
                    Text(
                      item.subtitle!,
                      style: AppTypography.meta.copyWith(
                        color: AppColors.muted,
                        fontSize: AppFontSize.meta,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              item.subtitle != null
                  ? LucideIcons.pencil
                  : LucideIcons.chevronRight,
              size: AppIconSize.sm,
              color: AppColors.mute2,
            ),
          ],
        ),
      ),
    );
  }
}
