// Audit BUG-03 2026-06-13 — Loader visible et explicite pour les states
// `loading` du parcours onboarding.
//
// Avant ce widget, chaque step body affichait un simple `Center(child:
// CircularProgressIndicator())` minuscule au milieu de l'ecran. Pendant le
// fetch du catalogue Firestore (~4s sur Wi-Fi, davantage sur 3G), l'ecran
// paraissait gele -> l'utilisateur pouvait croire que l'app etait plantee.
//
// Ce widget combine :
// - un spinner de taille raisonnable (32sp),
// - un texte explicite "Chargement..." sous le spinner,
// - une transparence/disposition centree commune.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/tokens.dart';

class OnboardingLoader extends StatelessWidget {
  const OnboardingLoader({
    super.key,
    required this.label,
  });

  /// Texte affiche sous le spinner. Doit etre localise par l'appelant
  /// (typiquement `l10n.onboardingLoaderLabel`).
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32.sp,
              height: 32.sp,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
