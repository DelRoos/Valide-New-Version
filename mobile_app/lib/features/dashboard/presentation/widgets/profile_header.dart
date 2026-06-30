import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/providers.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';

// Examen visé ID → label affiché (abréviation officielle camerounaise).
const _kExamLabels = <String, String>{
  'bepc': 'BEPC',
  'probatoire': 'Probatoire',
  'bac': 'BAC',
  'gce_ol': 'GCE O/L',
  'gce_al': 'GCE A/L',
  'cap': 'CAP',
  'bep': 'BEP',
  'bts': 'BTS',
};

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({
    super.key,
    required this.l10n,
    required this.languageCode,
  });

  final AppLocalizations l10n;
  final String languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    final catalogueAsync = ref.watch(catalogueProvider);

    final data = profileAsync.maybeWhen(data: (d) => d, orElse: () => null);
    final isLoading = profileAsync.isLoading;

    final displayName = data?['displayName'] as String?;
    final levelId = data?['levelId'] as String?;
    final streamId = data?['streamId'] as String?;
    final phoneNumber = data?['phoneNumber'] as String?;
    final schoolName = data?['schoolName'] as String?;
    final examTargetIds =
        (data?['examTargets'] as List?)?.cast<String>() ?? const <String>[];

    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : '?';

    final streamLabel = catalogueAsync.maybeWhen(
      data: (cat) {
        String? levelName;
        String? serieName;
        if (levelId != null) {
          final match = cat.niveaux.where((n) => n.niveauId == levelId);
          if (match.isNotEmpty) {
            levelName =
                match.first.name[languageCode] ?? match.first.name['fr'];
          }
        }
        if (streamId != null) {
          final match = cat.series.where((s) => s.serieId == streamId);
          if (match.isNotEmpty) {
            serieName =
                match.first.name[languageCode] ?? match.first.name['fr'];
          }
        }
        if (levelName != null && serieName != null) {
          return '$levelName — $serieName';
        }
        return levelName ?? serieName;
      },
      orElse: () => null,
    );

    final examLabel = examTargetIds.isNotEmpty
        ? examTargetIds.map((id) => _kExamLabels[id] ?? id).join(' · ')
        : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            AppSpacing.s4.h,
            AppSpacing.s4.w,
            AppSpacing.s4.h,
          ),
          child: Row(
            children: [
              // Avatar avec indicateur de chargement superposé.
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: AppBorderWidth.bold,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: AppTypography.h1.copyWith(
                          color: Colors.white,
                          fontSize: AppFontSize.h1,
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              SizedBox(width: AppSpacing.s4.w),
              // Infos textuelles + bouton Modifier.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            displayName ?? '—',
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontSize: AppFontSize.h3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (streamLabel != null) ...[
                          SizedBox(width: AppSpacing.s2.w),
                          Text(
                            streamLabel,
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: AppFontSize.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (schoolName != null) ...[
                      SizedBox(height: AppSpacing.s1.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.school,
                            size: AppIconSize.sm,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: AppSpacing.s1.w),
                          Flexible(
                            child: Text(
                              schoolName,
                              style: AppTypography.meta.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: AppFontSize.meta,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.s1.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.phone,
                            size: AppIconSize.sm,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: AppSpacing.s1.w),
                          Text(
                            phoneNumber,
                            style: AppTypography.meta.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: AppFontSize.meta,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (examLabel != null) ...[
                      SizedBox(height: AppSpacing.s1.h),
                      Text(
                        examLabel,
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: AppFontSize.meta,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
