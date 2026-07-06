import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/pedagogical_content.dart';
import '../../domain/failures/content_failure.dart';
import '../../providers.dart';

class FicheTab extends ConsumerWidget {
  const FicheTab({
    super.key,
    required this.chapterId,
    required this.languageCode,
  });

  final String chapterId;
  final String languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficheAsync = ref.watch(chapterFicheProvider(chapterId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxWidth = width >= 840 ? 720.0 : width >= 600 ? 600.0 : width;

        Widget body = ficheAsync.when(
          loading: () => const _FicheLoadingSkeleton(),
          error: (error, _) {
            if (error is ContentFailure &&
                error.kind == ContentFailureKind.notFound) {
              return _FicheEmptyState(languageCode: languageCode);
            }
            return ContentErrorView(
              error: error,
              onRetry: () => ref.invalidate(chapterFicheProvider(chapterId)),
            );
          },
          data: (fiche) {
            final content = fiche.contentFor(languageCode);
            if (content.isEmpty) {
              return _FicheEmptyState(languageCode: languageCode);
            }
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s4,
                AppSpacing.s6 + bottomInset,
              ),
              child: PedagogicalContent(data: content),
            );
          },
        );

        if (maxWidth < width) {
          return Center(
            child: SizedBox(width: maxWidth, child: body),
          );
        }
        return body;
      },
    );
  }
}

class _FicheEmptyState extends StatelessWidget {
  const _FicheEmptyState({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: AppIconSize.xl8,
            color: AppColors.mute2,
          ),
          SizedBox(height: AppSpacing.s3),
          Text(
            languageCode == 'fr'
                ? 'Fiche bientôt disponible'
                : 'Study sheet coming soon',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.body,
              color: AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FicheLoadingSkeleton extends StatelessWidget {
  const _FicheLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(
            width: double.infinity,
            height: 28,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s3),
          AppSkeleton(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          SizedBox(height: AppSpacing.s3),
          AppSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ],
      ),
    );
  }
}
