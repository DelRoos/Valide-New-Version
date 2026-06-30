import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Conteneur visuel uniforme pour tous les dialogues de l'app.
///
/// Utilisé directement par `AppModal.show` (cas statiques) et par
/// `showDialog` + `Consumer` (cas dynamiques avec state Riverpod).
/// Garantit : fond `AppColors.card`, rayon `AppRadius.xl2`, padding
/// `AppSpacing.s6`, titre en `AppTypography.h3`.
class AppDialogCard extends StatelessWidget {
  const AppDialogCard({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  final Widget child;
  final String? title;

  /// Si non-null, affiche un bouton ✕ en haut à droite du titre.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420.w,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s6.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null || onClose != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(title!, style: AppTypography.h3),
                          ),
                        if (onClose != null)
                          Padding(
                            padding: EdgeInsets.only(left: AppSpacing.s2.w),
                            child: InkWell(
                              onTap: onClose,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.s1.w),
                                child: Icon(
                                  Icons.close,
                                  size: AppIconSize.xl2,
                                  color: AppColors.mute2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s3.h),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modale plein écran centrée, UX-DR-10 : au moins UN bouton explicite —
/// pas de close X seul. `primary` est obligatoire, `secondary` optionnel.
///
/// Layout boutons :
/// - Si `secondary` present : Row [secondary | primary] cote-a-cote
///   (Expanded chacun). Pattern Material Design standard pour les dialogues
///   de confirmation.
/// - Si pas de `secondary` : primary seul stretched full-width.
class AppModal {
  AppModal._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    required ({String label, ValueChanged<BuildContext> onTap}) primary,
    ({String label, ValueChanged<BuildContext> onTap})? secondary,
    String? title,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (ctx) => AppDialogCard(
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            SizedBox(height: AppSpacing.s6.h),
            if (secondary != null)
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: secondary.label,
                      onPressed: () => secondary.onTap(ctx),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s3.w),
                  Expanded(
                    child: AppButton.primary(
                      label: primary.label,
                      onPressed: () => primary.onTap(ctx),
                    ),
                  ),
                ],
              )
            else
              AppButton.primary(
                label: primary.label,
                onPressed: () => primary.onTap(ctx),
              ),
          ],
        ),
      ),
    );
  }
}
