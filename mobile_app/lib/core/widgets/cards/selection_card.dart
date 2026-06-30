import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../pressable.dart';

/// Variants de [SelectionCard] (cf. DESIGN.md § Composants Onboarding > Selection card).
///
/// * [compact] : padding 12 px, radius 14 px, icone 40x40, titre 15 sp, radio 20 px.
///   Pickers denses (matieres, options secondaires).
/// * [standard] : padding 16 px, radius 18 px, icone 48x48, titre 17 sp, radio 24 px.
///   Choix structurants standard (track, level, ecole resultat).
/// * [hero] : padding 20 px, radius 18 px, icone 56x56, titre 18 sp, radio 24 px.
///   Sub-system step 0 (les deux options structurantes du flow).
///
/// La decision de fusionner `SubSystemHeroCard` dans ce composant via la
/// variant `hero` est documentee Story E1bis-0 Completion Notes (les specs
/// DESIGN.md des deux composants ne different que sur le padding et la taille
/// d'icone, parametres deja portes par la variant).
enum SelectionCardVariant { compact, standard, hero }

/// Carte de selection reutilisable pour tous les pickers d'option unique du
/// flow onboarding (steps 0 sub-system, 2 track, 3 level, 4 cards series,
/// 8 resultats ecole).
///
/// API :
///   - [title] requis
///   - [selected] requis (etat exterieur)
///   - [onTap] requis
///   - [icon] optionnel (Lucide ou Material)
///   - [description] optionnelle (texte 12 sp sous le titre)
///   - [variant] defaut [SelectionCardVariant.standard]
///
/// Comportements :
///   - Tap : haptic `selection` (via Pressable) + appel [onTap].
///   - Selected : bg primary-soft + ring 2 px primary + scale 1.01 + ombre brand attenuee.
///   - Transition couleurs / scale 200 ms `AppMotion.standardOut`.
///   - Responsive : largeur max 600 dp >= 840 dp via [LayoutBuilder] interne
///     (l'appelant n'a pas a se preoccuper du centrage tablette).
///
/// Pas d'i18n interne : le caller passe `title` / `description` deja localises.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
    this.description,
    this.variant = SelectionCardVariant.standard,
    this.showRadio = true,
    this.maxLines,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;
  final String? description;
  final SelectionCardVariant variant;

  /// Affiche le cercle radio a droite. Default `true` pour retro-compat.
  /// Passer `false` quand l'etat selectionne est deja signale par le border
  /// + bg + scale (cas onboarding refonte E1bis 2026-06-12).
  final bool showRadio;

  /// Limite le titre a N lignes avec overflow ellipsis. `null` = pas de limite.
  final int? maxLines;

  /// Padding interieur de la carte selon la variant (DESIGN.md).
  EdgeInsets get _padding {
    switch (variant) {
      case SelectionCardVariant.compact:
        return EdgeInsets.all(AppSpacing.s3.w);
      case SelectionCardVariant.standard:
        return EdgeInsets.all(AppSpacing.s4.w);
      case SelectionCardVariant.hero:
        return EdgeInsets.all(AppSpacing.s5.w);
    }
  }

  double get _cardRadius {
    switch (variant) {
      case SelectionCardVariant.compact:
        return AppRadius.lg;
      case SelectionCardVariant.standard:
      case SelectionCardVariant.hero:
        return AppRadius.xl2;
    }
  }

  double get _iconBoxSize {
    switch (variant) {
      case SelectionCardVariant.compact:
        return 40.w;
      case SelectionCardVariant.standard:
        return 48.w;
      case SelectionCardVariant.hero:
        return 56.w;
    }
  }

  double get _titleSize {
    switch (variant) {
      case SelectionCardVariant.compact:
        return 15.sp;
      case SelectionCardVariant.standard:
        return 17.sp;
      case SelectionCardVariant.hero:
        return 18.sp;
    }
  }

  double get _radioSize {
    switch (variant) {
      case SelectionCardVariant.compact:
        return 20.w;
      case SelectionCardVariant.standard:
      case SelectionCardVariant.hero:
        return 24.w;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 840;
        if (!isTablet) return _buildCard(context);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: 600.w),
            child: _buildCard(context),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final radius = BorderRadius.circular(_cardRadius);
    final container = AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardOut,
      padding: _padding,
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.card,
        borderRadius: radius,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  offset: Offset(0, 10),
                  blurRadius: 30,
                  color: Color(0x262563EB), // rgba(37,99,235,0.15)
                ),
              ]
            : AppElevation.soft,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            _SelectionCardIcon(
              icon: icon!,
              boxSize: _iconBoxSize,
              selected: selected,
            ),
            SizedBox(width: AppSpacing.s3.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: maxLines,
                  overflow: maxLines != null ? TextOverflow.ellipsis : null,
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: _titleSize,
                    color: selected ? AppColors.primary : AppColors.ink,
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.s1.h),
                  Text(
                    description!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primaryDark : AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showRadio) ...[
            SizedBox(width: AppSpacing.s3.w),
            _SelectionCardRadio(size: _radioSize, selected: selected),
          ],
        ],
      ),
    );

    final scaled = AnimatedScale(
      scale: selected ? 1.01 : 1.0,
      duration: AppMotion.standard,
      curve: AppMotion.standardOut,
      child: container,
    );

    return Pressable(
      onTap: onTap,
      borderRadius: radius,
      hapticPreset: HapticPreset.selection,
      child: scaled,
    );
  }
}

/// Cercle d'icone gauche. Bg [AppColors.bg] / fg [AppColors.inkSoft] par defaut ;
/// selected -> bg primary + fg card + ombre brand attenuee.
class _SelectionCardIcon extends StatelessWidget {
  const _SelectionCardIcon({
    required this.icon,
    required this.boxSize,
    required this.selected,
  });

  final Widget icon;
  final double boxSize;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardOut,
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: selected ? AppElevation.brand : null,
      ),
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: IconThemeData(
          color: selected ? AppColors.card : AppColors.inkSoft,
          size: boxSize * 0.5,
        ),
        child: icon,
      ),
    );
  }
}

/// Indicateur radio droite. Cercle borde 2 px ; selected -> rempli primary
/// avec checkmark blanc 14 px.
class _SelectionCardRadio extends StatelessWidget {
  const _SelectionCardRadio({required this.size, required this.selected});

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(
              LucideIcons.check,
              size: size * 0.6,
              color: AppColors.card,
            )
          : null,
    );
  }
}
