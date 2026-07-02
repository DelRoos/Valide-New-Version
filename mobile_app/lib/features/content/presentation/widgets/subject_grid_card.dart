import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';

// Palette de couleurs cyclique pour identifier visuellement chaque matière.
const List<Color> _kSubjectPalette = [
  Color(0xFF3B82F6), // bleu
  Color(0xFF8B5CF6), // violet
  Color(0xFF10B981), // vert émeraude
  Color(0xFFF59E0B), // ambre
  Color(0xFFEF4444), // rouge rose
  Color(0xFF0EA5E9), // ciel
  Color(0xFFF97316), // orange
  Color(0xFF6366F1), // indigo
];

Color subjectColorAt(int index) => _kSubjectPalette[index % _kSubjectPalette.length];

class SubjectGridCard extends StatelessWidget {
  const SubjectGridCard({
    super.key,
    required this.subject,
    required this.index,
  });

  final Subject subject;
  final int index;

  @override
  Widget build(BuildContext context) {
    final langKey = Localizations.localeOf(context).languageCode;
    final abbr = subject.abbreviationFor(langKey);
    final name =
        subject.name[langKey] ?? subject.name['fr'] ?? subject.subjectId;
    final label = abbr ?? name;
    final color = subjectColorAt(index);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: () =>
              GoRouter.of(context).push(AppRoutes.subject(subject.subjectId)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header coloré avec icône
              Expanded(
                flex: 10,
                child: Container(
                  color: color.withValues(alpha: 0.10),
                  child: Center(
                    child: Container(
                      width: AppSpacing.s12,
                      height: AppSpacing.s12,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(
                        subjectIconFor(subject.icon),
                        size: AppIconSize.xl4,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              // Nom de la matière
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3.w,
                    vertical: AppSpacing.s2.h,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: AppTypography.bodyStrong.copyWith(
                        fontSize: AppFontSize.bodySmall,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
