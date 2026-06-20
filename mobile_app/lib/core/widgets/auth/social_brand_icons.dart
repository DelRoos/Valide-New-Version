// Icônes de marque pour les boutons d'authentification sociale.
// Utilisées dans AuthChoiceStepBody (step 5 onboarding) et
// AccountUpgradeSheet (dashboard visiteur -> compte permanent).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo Google officiel (G 4 couleurs) depuis assets/images/logo_google.svg.
class GoogleBrandIcon extends StatelessWidget {
  const GoogleBrandIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_google.svg',
      fit: BoxFit.contain,
    );
  }
}

/// Logo Apple officiel (pomme monochrome) depuis assets/images/logo_apple.svg.
/// [color] remplace le fill du SVG pour s'adapter au fond du bouton.
class AppleBrandIcon extends StatelessWidget {
  const AppleBrandIcon({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_apple.svg',
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
