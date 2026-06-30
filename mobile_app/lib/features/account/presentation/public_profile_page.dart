// Story A.2 — Page profil public d'un pair.
//
// Route : /user/:uid (hors shell — pas de NavigationBar).
// États : loading (AppSkeleton), data (header + stats), error/vide (AppEmptyState).
// Responsive : LayoutBuilder phone (< 600 dp) / tablet (≥ 600 dp).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../onboarding/domain/profile_failure.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/providers.dart';
import 'widgets/public_profile_header.dart';
import 'widgets/public_profile_stats_section.dart';

const double _kSkeletonHeaderHeight = 220;
const double _kSkeletonLabelWidth = 120;
const double _kSkeletonLabelHeight = 14;
const double _kSkeletonStatHeight = 80;

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final profileAsync = ref.watch(publicProfileProvider(uid));
    final catalogueAsync = ref.watch(catalogueProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: profileAsync.when(
        loading: () => _LoadingBody(l10n: l10n),
        error: (error, _) {
          AppLogger.e('PublicProfilePage: publicProfileProvider error', error: error);
          return _errorBody(context, ref, l10n, failure: null);
        },
        data: (either) => either.fold(
          (failure) {
            AppLogger.w(
              'PublicProfilePage: kind=${failure.kind.name} message=${failure.message}',
            );
            return _errorBody(context, ref, l10n, failure: failure);
          },
          (profile) {
            if (profile == null) {
              return _NotFoundBody(l10n: l10n);
            }

            final classLabel = catalogueAsync.maybeWhen(
              data: (cat) {
                String? levelName;
                String? streamName;
                final levelMatch =
                    cat.niveaux.where((n) => n.niveauId == profile.levelId);
                if (levelMatch.isNotEmpty) {
                  levelName = levelMatch.first.name[languageCode] ??
                      levelMatch.first.name['fr'];
                }
                final streamMatch =
                    cat.series.where((s) => s.serieId == profile.streamId);
                if (streamMatch.isNotEmpty) {
                  streamName = streamMatch.first.name[languageCode] ??
                      streamMatch.first.name['fr'];
                }
                if (levelName != null && streamName != null) {
                  return '$levelName — $streamName';
                }
                return levelName ?? streamName;
              },
              orElse: () => null,
            );

            return Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 600;
                    // hPad déjà en logical px depuis constraints — pas de .w
                    // (évite double-scaling ScreenUtil sur tablet).
                    final hPad = isTablet
                        ? (constraints.maxWidth - 560) / 2
                        : 0.0;

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: PublicProfileHeader(
                            profile: profile,
                            classLabel: classLabel,
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          sliver: SliverToBoxAdapter(
                            child: PublicProfileStatsSection(l10n: l10n),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.s8.h),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _errorBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required ProfileFailure? failure,
  }) {
    final kind = failure?.kind ?? ProfileFailureKind.networkUnavailable;
    final (title, icon) = switch (kind) {
      ProfileFailureKind.permissionDenied ||
      ProfileFailureKind.notAuthenticated =>
        (l10n.errorPermissionDenied, LucideIcons.lock),
      ProfileFailureKind.networkUnavailable =>
        (l10n.errorNetworkUnavailable, LucideIcons.wifiOff),
      ProfileFailureKind.unknown =>
        (l10n.errorFirestoreUnknown, LucideIcons.alertTriangle),
    };

    return Column(
      children: [
        _BackBar(),
        Expanded(
          child: AppEmptyState(
            icon: icon,
            title: title,
            ctaLabel: l10n.retryLabel,
            onCtaPressed: () => ref.invalidate(publicProfileProvider(uid)),
          ),
        ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSkeleton(
          width: double.infinity,
          height: _kSkeletonHeaderHeight.h,
          borderRadius: BorderRadius.zero,
        ),
        Padding(
          padding: EdgeInsets.all(AppSpacing.s4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: _kSkeletonLabelWidth.w, height: _kSkeletonLabelHeight.h),
              SizedBox(height: AppSpacing.s3.h),
              Row(
                children: [
                  Expanded(child: AppSkeleton(width: double.infinity, height: _kSkeletonStatHeight.h)),
                  SizedBox(width: AppSpacing.s3.w),
                  Expanded(child: AppSkeleton(width: double.infinity, height: _kSkeletonStatHeight.h)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotFoundBody extends StatelessWidget {
  const _NotFoundBody({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BackBar(),
        Expanded(
          child: AppEmptyState(
            icon: LucideIcons.userX,
            title: l10n.publicProfileNotFound,
            subtitle: l10n.publicProfileNotFoundSubtitle,
          ),
        ),
      ],
    );
  }
}

class _BackBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(top: top),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
