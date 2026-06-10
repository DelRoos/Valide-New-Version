// Barre de validation reutilisable pour les pages de selection (pickers).
// Extraite du pattern footer repete 4x dans subjects_picker_page.dart
// (Stories 1.4, 1.15, 1.16, 1.17) lors de la Story 1.18.
//
// Pattern : Row(Icon listChecks + Text counter) couleur conditionnelle
// (primary si isValid, danger sinon) + AppButton.primary(loading) +
// AppButton.secondary(label back).
//
// L'appelant fournit le texte compteur pre-formate (cles ARB conditionnelles
// : onboardingOptOutTakingCount vs onboardingPickerCounterLive).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../app_button.dart';

class PickerValidateBar extends StatelessWidget {
  const PickerValidateBar({
    super.key,
    required this.counterText,
    required this.isValid,
    required this.isSaving,
    required this.onValidate,
    required this.onCancel,
    required this.validateLabel,
    required this.cancelLabel,
  });

  /// Texte compteur pre-formate par l'appelant
  /// (ex. "8 / 11 matieres", "Tu prends 9 matieres sur 11").
  final String counterText;

  /// Si false : le compteur prend la couleur danger ET le bouton primary est
  /// desactive. Si true : compteur primary + bouton actif (sauf isSaving).
  final bool isValid;

  /// Si true : bouton primary affiche un loading spinner + bouton secondary
  /// est desactive.
  final bool isSaving;

  /// Callback bouton primary. Doit etre null quand !isValid pour que le
  /// bouton apparaisse desactive.
  final VoidCallback? onValidate;

  /// Callback bouton secondary (typiquement retour ecran precedent).
  final VoidCallback onCancel;

  /// Label du bouton primary (ex. l10n.onboardingPickerValidateCta).
  final String validateLabel;

  /// Label du bouton secondary (ex. l10n.back).
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final accentColor = isValid ? AppColors.primary : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.listChecks,
              color: accentColor,
              size: 20.sp,
            ),
            SizedBox(width: AppSpacing.s2.w),
            Expanded(
              child: Text(
                counterText,
                style: AppTypography.bodyStrong.copyWith(color: accentColor),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s3.h),
        AppButton.primary(
          label: validateLabel,
          onPressed: (isValid && !isSaving) ? onValidate : null,
          loading: isSaving,
        ),
        SizedBox(height: AppSpacing.s2.h),
        AppButton.secondary(
          label: cancelLabel,
          onPressed: isSaving ? null : onCancel,
        ),
      ],
    );
  }
}
