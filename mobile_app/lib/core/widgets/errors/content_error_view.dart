import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../../../features/content/domain/failures/content_failure.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Vue d'erreur centrée pour les pages de contenu.
/// Affiche un message localisé selon le `ContentFailureKind` + bouton retry.
/// Utilisé dans SubjectDetailPage, ChapterPage, LessonPage.
class ContentErrorView extends StatelessWidget {
  const ContentErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = _messageFor(error, l10n);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: AppIconSize.xl8,
              color: AppColors.muted,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s4.h),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s5.w,
                  vertical: AppSpacing.s3.h,
                ),
              ),
              child: Text(
                l10n.retryLabel,
                style: AppTypography.bodyStrong.copyWith(
                  color: AppColors.primary,
                  fontSize: AppFontSize.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _messageFor(Object error, AppLocalizations l10n) {
    if (error is ContentFailure) {
      return switch (error.kind) {
        ContentFailureKind.permissionDenied => l10n.errorPermissionDenied,
        ContentFailureKind.networkUnavailable => l10n.errorNetworkUnavailable,
        ContentFailureKind.notFound ||
        ContentFailureKind.unknown =>
          l10n.errorFirestoreUnknown,
      };
    }
    return l10n.errorFirestoreUnknown;
  }
}
