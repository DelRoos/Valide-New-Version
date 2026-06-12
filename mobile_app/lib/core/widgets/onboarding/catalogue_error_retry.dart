// Fix runtime 2026-06-12 — Widget reutilisable pour afficher l'erreur de
// chargement catalogue avec un bouton "Reessayer". Anti-boucle infinie :
// le user peut declencher manuellement `ref.invalidate(catalogueProvider)`
// au lieu de rester pris dans un AsyncError silencieux.
//
// Utilise par les step bodies E1bis-3 (track, level, stream/subjects picker)
// quand `catalogueProvider` ou `derivedProfileV2Provider` retourne une erreur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalogue/providers.dart';
import '../../theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class CatalogueErrorRetry extends ConsumerWidget {
  const CatalogueErrorRetry({
    super.key,
    this.message,
  });

  /// Message custom optionnel. Defaut: `l10n.errorCatalogueLoading`.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 48.sp,
              color: AppColors.inkSoft,
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              message ?? l10n.errorCatalogueLoading,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(catalogueProvider);
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 18),
              label: Text(l10n.retryLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.card,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s5.w,
                  vertical: AppSpacing.s3.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
