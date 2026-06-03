// Helper responsive 3 form factors (cf. ADR-011 et EXPERIENCE.md § Responsive & Platform).
// Permet de décider du nombre de colonnes, du switch bottom-tabs / NavigationRail, etc.
// `flutter_screenutil` gère l'échelle relative (.w/.h/.sp) ; ce helper gère la composition.

import 'package:flutter/widgets.dart';

enum FormFactor {
  /// < 600 dp — phone portrait (cible référence design 375×812).
  phone,

  /// 600-840 dp — phone landscape ou small tablet portrait.
  phoneLandscape,

  /// ≥ 840 dp — tablet (iPad mini, Pixel Tablet, etc.).
  tablet,
}

class Responsive {
  const Responsive._(this.formFactor, this.width);

  final FormFactor formFactor;
  final double width;

  factory Responsive.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Responsive._(_classify(width), width);
  }

  bool get isPhone => formFactor == FormFactor.phone;
  bool get isPhoneLandscape => formFactor == FormFactor.phoneLandscape;
  bool get isTablet => formFactor == FormFactor.tablet;

  /// Sélecteur fluide qui retourne la valeur adaptée au form factor courant.
  /// `phoneLandscape` est optionnel et fallback sur `phone` si non fourni.
  T select<T>({
    required T phone,
    T? phoneLandscape,
    required T tablet,
  }) {
    switch (formFactor) {
      case FormFactor.phone:
        return phone;
      case FormFactor.phoneLandscape:
        return phoneLandscape ?? phone;
      case FormFactor.tablet:
        return tablet;
    }
  }

  static FormFactor _classify(double width) {
    if (width >= 840) return FormFactor.tablet;
    if (width >= 600) return FormFactor.phoneLandscape;
    return FormFactor.phone;
  }
}

/// Builder qui rebuilds quand la largeur change suffisamment pour traverser un breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Responsive responsive) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = Responsive._(
          Responsive._classify(constraints.maxWidth),
          constraints.maxWidth,
        );
        return builder(context, responsive);
      },
    );
  }
}
