// Story A.2 — En-tête du profil public d'un pair.
//
// Avatar initiales 80×80 + gradient primary→primaryDark + displayName +
// sous-titre classe (niveau — série) + école optionnelle.
// Réutilisé uniquement par PublicProfilePage (non exporté dans core/widgets
// car spécifique à la feature account).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/public_profile.dart';

class PublicProfileHeader extends StatelessWidget {
  const PublicProfileHeader({
    super.key,
    required this.profile,
    required this.classLabel,
  });

  final PublicProfile profile;

  /// Label résolu : « Terminale D » ou « Form 5 » selon la langue.
  /// Calculé par le parent (PublicProfilePage) depuis le catalogue.
  final String? classLabel;

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : '?';

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
            AppSpacing.s6.h,
          ),
          child: Column(
            children: [
              Container(
                width: AppAvatarSize.profileLg,
                height: AppAvatarSize.profileLg,
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
              SizedBox(height: AppSpacing.s3.h),
              Text(
                profile.displayName.isNotEmpty ? profile.displayName : '—',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontSize: AppFontSize.h3,
                ),
              ),
              if (classLabel != null) ...[
                SizedBox(height: AppSpacing.s1.h),
                Text(
                  classLabel!,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
              ],
              if (profile.schoolName != null) ...[
                SizedBox(height: AppSpacing.s1.h),
                Text(
                  profile.schoolName!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: AppFontSize.caption,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
