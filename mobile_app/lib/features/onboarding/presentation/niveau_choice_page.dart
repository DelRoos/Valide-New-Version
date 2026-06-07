// Story 1.3 — Etape 2/3 du flow profil scolaire : choix niveau.
//
// Liste scrollable des niveaux filtrees par (subSystem, filiere) depuis
// CatalogueRepository.watchNiveaux(). Au tap : pre-check si le niveau a
// des series — si vide, skip directement vers recap avec serieId = null.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/domain/models.dart';
import '../../../core/catalogue/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/onboarding_flow_state.dart';
import '../providers.dart';
import 'onboarding_progress_header.dart';

class NiveauChoicePage extends ConsumerWidget {
  const NiveauChoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subSystem = ref.watch(subSystemNotifierProvider);
    final flow = ref.watch(onboardingFlowProvider);

    // Guard : si filiere manquante (deep link), redirect a la racine du flow.
    if (subSystem == null || flow.filiereId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).go('/onboarding/profile/filiere');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final niveauxAsync = ref.watch(
      _niveauxStreamProvider(
        _NiveauxQuery(
          subSystem: subSystem.id,
          filiereId: flow.filiereId!,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 720 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5.w,
                    vertical: AppSpacing.s6.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BackBar(
                        onBack: () {
                          ref
                              .read(onboardingFlowProvider.notifier)
                              .backTo(OnboardingFlowStep.niveau);
                          GoRouter.of(context)
                              .go('/onboarding/profile/filiere');
                        },
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      const OnboardingProgressHeader(step: 2, total: 3),
                      SizedBox(height: AppSpacing.s5.h),
                      Text(
                        l10n.onboardingNiveauTitle,
                        style: AppTypography.h2,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.s6.h),
                      Expanded(
                        child: niveauxAsync.when(
                          data: (niveaux) => _NiveauxList(
                            niveaux: niveaux,
                            langKey: subSystem.languageCode,
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, st) => Center(
                            child: Text(
                              l10n.errorGeneric,
                              style: AppTypography.body.copyWith(
                                color: AppColors.danger,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Cle de requete pour le StreamProvider family. Equatable pour deduplication.
class _NiveauxQuery {
  const _NiveauxQuery({required this.subSystem, required this.filiereId});
  final String subSystem;
  final String filiereId;

  @override
  bool operator ==(Object other) =>
      other is _NiveauxQuery &&
      other.subSystem == subSystem &&
      other.filiereId == filiereId;

  @override
  int get hashCode => Object.hash(subSystem, filiereId);
}

final _niveauxStreamProvider =
    StreamProvider.family<List<Niveau>, _NiveauxQuery>((ref, query) {
  return ref.watch(catalogueRepositoryProvider).watchNiveaux(
        subSystem: query.subSystem,
        filiereId: query.filiereId,
      );
});

class _NiveauxList extends ConsumerWidget {
  const _NiveauxList({required this.niveaux, required this.langKey});

  final List<Niveau> niveaux;
  final String langKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (niveaux.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).emptyStateGeneric,
          style: AppTypography.body,
        ),
      );
    }
    return ListView.separated(
      itemCount: niveaux.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3.h),
      itemBuilder: (context, index) {
        final n = niveaux[index];
        return AppCard(
          onTap: () => _onTapNiveau(context, ref, n),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  n.name[langKey] ?? n.name['fr'] ?? n.niveauId,
                  style: AppTypography.h3,
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 24.sp,
                color: AppColors.mute2,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onTapNiveau(
    BuildContext context,
    WidgetRef ref,
    Niveau niveau,
  ) async {
    ref.read(onboardingFlowProvider.notifier).selectNiveau(niveau.niveauId);

    // Pre-check : ce niveau a-t-il au moins une serie ?
    final subSystem = ref.read(subSystemNotifierProvider);
    final flow = ref.read(onboardingFlowProvider);
    if (subSystem == null || flow.filiereId == null) return;

    final repo = ref.read(catalogueRepositoryProvider);
    final series = await repo
        .watchSeries(
          subSystem: subSystem.id,
          niveauId: niveau.niveauId,
          filiereId: flow.filiereId,
        )
        .first
        .timeout(
          const Duration(seconds: 2),
          onTimeout: () => const [],
        );

    if (!context.mounted) return;

    if (series.isEmpty) {
      // Niveau sans serie (ex. 6e francophone, Form 1-4 anglophone).
      // Skip directement vers recap avec serieId = null.
      ref.read(onboardingFlowProvider.notifier).selectSerie(null);
      GoRouter.of(context).go('/onboarding/profile/recap');
    } else {
      GoRouter.of(context).go('/onboarding/profile/serie');
    }
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onBack,
        icon: Icon(LucideIcons.arrowLeft, size: 24.sp, color: AppColors.ink),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
      ),
    );
  }
}
