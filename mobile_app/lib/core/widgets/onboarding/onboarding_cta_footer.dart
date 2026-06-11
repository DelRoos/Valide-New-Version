// Story E1bis-2 — Footer CTA sticky bottom reutilise par toutes les pages
// onboarding refonte (E1bis-2 a E1bis-7).
//
// Pattern : se pose en `Scaffold.bottomNavigationBar`. Le `AppButton.primary`
// occupe toute la largeur via `SizedBox(width: double.infinity)`. Le `secondaryAction`
// optionnel (lien tertiaire type "Passer pour l'instant") s'affiche AU-DESSUS
// du CTA.
//
// Composant pur : pas de Riverpod, pas d'i18n interne — le caller passe le
// label deja localise.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/tokens.dart';
import '../app_button.dart';

class OnboardingCtaFooter extends StatelessWidget {
  const OnboardingCtaFooter({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryAction,
  });

  /// Label du bouton primaire. Deja localise par le caller.
  final String label;

  /// Callback tap. `null` -> bouton disabled (visuel + non interactif via
  /// `AppButton.primary`).
  final VoidCallback? onPressed;

  /// Action secondaire optionnelle (ex. "Passer pour l'instant" pour steps 7
  /// et 8). Affichee au-dessus du CTA primaire avec un espacement.
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -4),
            blurRadius: 12,
            color: Color(0x0F0F172A),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4.w,
            vertical: AppSpacing.s4.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondaryAction != null) ...[
                secondaryAction!,
                SizedBox(height: AppSpacing.s3.h),
              ],
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: label,
                  onPressed: onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
