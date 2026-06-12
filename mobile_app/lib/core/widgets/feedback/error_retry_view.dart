// Widget reutilisable pour afficher une erreur + un bouton "Reessayer".
//
// Anti-boucle infinie : le user peut declencher manuellement le retry au
// lieu de rester pris dans un AsyncError silencieux.
//
// Utilise dans tous les ecrans qui consomment un `AsyncValue` (catalogue,
// derived profile, schools, etc.). Le bouton est large + en bas, en zone
// pouce confortable. Le titre est gros pour attirer l'oeil. L'icone et le
// message sont adaptes au type d'erreur (offline / chargement / generique).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

enum ErrorRetryKind { offline, loading, generic }

class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.onRetry,
    this.kind = ErrorRetryKind.loading,
    this.title,
    this.message,
    this.retryLabel,
  });

  /// Callback invoque quand l'utilisateur tape "Reessayer".
  final VoidCallback onRetry;

  /// Determine icone + couleur + ton par defaut. Override individual via
  /// [title] / [message] / [retryLabel].
  final ErrorRetryKind kind;

  final String? title;
  final String? message;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final iconData = switch (kind) {
      ErrorRetryKind.offline => LucideIcons.wifiOff,
      ErrorRetryKind.loading => LucideIcons.cloudOff,
      ErrorRetryKind.generic => LucideIcons.triangleAlert,
    };
    final iconColor = switch (kind) {
      ErrorRetryKind.offline => AppColors.warningInk,
      ErrorRetryKind.loading => AppColors.danger,
      ErrorRetryKind.generic => AppColors.danger,
    };

    final resolvedTitle = title ?? _defaultTitle(l10n);
    final resolvedMessage = message ?? l10n.errorCatalogueLoading;
    final resolvedRetryLabel = retryLabel ?? l10n.retryLabel;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                iconData,
                size: 44.sp,
                color: iconColor,
              ),
            ),
            SizedBox(height: AppSpacing.s5.h),
            Text(
              resolvedTitle,
              style: AppTypography.h2.copyWith(fontSize: 22.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              resolvedMessage,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 15.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s6.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.rotateCcw, size: 20),
                label: Text(
                  resolvedRetryLabel,
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.card,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.card,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s6.w,
                    vertical: AppSpacing.s4.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.s6.h),
          ],
        ),
      ),
    );
  }

  String _defaultTitle(AppLocalizations l10n) {
    return switch (kind) {
      ErrorRetryKind.offline => l10n.errorOfflineTitle,
      ErrorRetryKind.loading => l10n.errorLoadingTitle,
      ErrorRetryKind.generic => l10n.errorGenericTitle,
    };
  }
}
