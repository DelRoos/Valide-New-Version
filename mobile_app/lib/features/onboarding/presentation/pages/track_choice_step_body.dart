// Story E1bis-3 — Step body 2 du shell onboarding refonte.
//
// TRACK CHOICE (Filiere Generale / Technique). Lit `filieres` du
// catalogueProvider existant (Story 1.5) et filtre les actives.
//
// Mapping local : Filiere (model domain Epic 1) -> variables track* cote
// E1bis. Le rename global est Story 1.19 (dette identifiers anglais).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/catalogue/providers.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/selection_card.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
import '../../../../core/widgets/feedback/onboarding_loader.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/sub_system.dart';
import '../state/onboarding_providers.dart';

class TrackChoiceStepBody extends ConsumerWidget {
  const TrackChoiceStepBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final catalogueAsync = ref.watch(catalogueProvider);
    final isAnglo = state.subSystem == SubSystem.anglophone;

    return catalogueAsync.when(
      data: (snapshot) {
        final tracks = snapshot.filieres
            .where((f) => f.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (tracks.isEmpty) {
          return ErrorRetryView(
            onRetry: () => ref.invalidate(catalogueProvider),
            message: l10n.errorCatalogueEmpty,
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.s6.h),
              Icon(LucideIcons.briefcase,
                  size: 48.sp, color: AppColors.primary),
              SizedBox(height: AppSpacing.s5.h),
              Text(
                l10n.onboardingTrackTitle,
                style: AppTypography.h1.copyWith(fontSize: 24.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.s3.h),
              Text(
                l10n.onboardingTrackSubtitle,
                style: AppTypography.body.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.inkSoft,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.s6.h),
              for (final t in tracks) ...[
                SelectionCard(
                  title: _localizedName(t, anglo: isAnglo),
                  description: _trackHint(l10n, t.filiereId),
                  // Audit 2026-06-13 — pas de `color:` explicite ici sinon
                  // l'icone reste primary sur le fond primary quand la card
                  // est selectionnee (invisible). On laisse SelectionCard
                  // appliquer son IconTheme : inkSoft hors selection, white
                  // sur selection. Cf. SelectionCard._SelectionCardIcon.
                  icon: Icon(_trackIcon(t.filiereId)),
                  selected: state.trackId == t.filiereId,
                  // Audit 2026-06-13 — setTrackIdDraft (no transition) :
                  // l'utilisateur choisit puis confirme via CTA Continuer
                  // du shell. Permet de changer d'avis sans back.
                  onTap: () => notifier.setTrackIdDraft(t.filiereId),
                  showRadio: false,
                ),
                SizedBox(height: AppSpacing.s3.h),
              ],
              SizedBox(height: AppSpacing.s5.h),
            ],
          ),
        );
      },
      loading: () => OnboardingLoader(label: l10n.onboardingLoaderLabel),
      error: (e, st) => ErrorRetryView(
        onRetry: () => ref.invalidate(catalogueProvider),
        kind: ErrorRetryKind.offline,
      ),
    );
  }

  String _localizedName(Filiere t, {required bool anglo}) {
    final key = anglo ? 'en' : 'fr';
    return t.name[key] ?? t.name.values.first;
  }

  String _trackHint(AppLocalizations l10n, String trackId) {
    return switch (trackId) {
      'generale' => l10n.onboardingTrackHintGeneral,
      'technique' => l10n.onboardingTrackHintTechnique,
      _ => '',
    };
  }

  /// Audit 2026-06-13 — Icone par track pour aider l'eleve a visualiser
  /// la filiere. Generale = mortier diplome, Technique = cle a molette.
  IconData _trackIcon(String trackId) {
    return switch (trackId) {
      'generale' => LucideIcons.graduationCap,
      'technique' => LucideIcons.wrench,
      _ => LucideIcons.bookOpen,
    };
  }
}

