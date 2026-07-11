import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/firebase/providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/pedagogical_content.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../dashboard/presentation/widgets/account_upgrade_sheet.dart'
    show showAccountUpgradeDialog;
import '../../domain/failures/content_failure.dart';
import '../../providers.dart';

/// Ouvre le bottom sheet "Résumé du chapitre" (fiche de révision) en modal
/// plein écran. Contient un CTA final "S'exercer" qui route vers le quiz.
Future<void> showFicheSummarySheet({
  required BuildContext context,
  required String subjectId,
  required String chapterId,
  required String languageCode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: AppColors.card,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.9,
      child: SafeArea(
        top: false,
        child: _FicheSummarySheetBody(
          subjectId: subjectId,
          chapterId: chapterId,
          languageCode: languageCode,
        ),
      ),
    ),
  );
}

class _FicheSummarySheetBody extends ConsumerStatefulWidget {
  const _FicheSummarySheetBody({
    required this.subjectId,
    required this.chapterId,
    required this.languageCode,
  });

  final String subjectId;
  final String chapterId;
  final String languageCode;

  @override
  ConsumerState<_FicheSummarySheetBody> createState() =>
      _FicheSummarySheetBodyState();
}

class _FicheSummarySheetBodyState
    extends ConsumerState<_FicheSummarySheetBody> {
  final _scrollController = ScrollController();
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollController.offset / max).clamp(0.0, 1.0);
    if ((progress - _progress).abs() > 0.005) {
      setState(() => _progress = progress);
    }
  }

  void _onExercise() {
    Navigator.of(context, rootNavigator: true).pop();
    final isAnonymous =
        ref.read(firebaseAuthProvider).currentUser?.isAnonymous ?? true;
    if (isAnonymous) {
      showAccountUpgradeDialog(
        context,
        onAccountLinked: () => context.push(
          AppRoutes.chapterQuiz(widget.subjectId, widget.chapterId),
        ),
      );
    } else {
      context.push(AppRoutes.chapterQuiz(widget.subjectId, widget.chapterId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ficheAsync = ref.watch(chapterFicheProvider(widget.chapterId));
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _SheetHeader(
          onClose: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        LinearProgressIndicator(
          value: _progress,
          minHeight: 3,
          backgroundColor: AppColors.border,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        Expanded(
          child: ficheAsync.when(
            loading: () => const _SheetLoadingSkeleton(),
            error: (error, _) {
              if (error is ContentFailure &&
                  error.kind == ContentFailureKind.notFound) {
                return const _SheetEmptyState();
              }
              return ContentErrorView(
                error: error,
                onRetry: () =>
                    ref.invalidate(chapterFicheProvider(widget.chapterId)),
              );
            },
            data: (fiche) {
              final content = fiche.contentFor(widget.languageCode);
              if (content.isEmpty) return const _SheetEmptyState();
              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PedagogicalContent(data: content),
                    SizedBox(height: AppSpacing.s6.h),
                    AppButton.primary(
                      label: l10n.fichePracticeChapter,
                      onPressed: _onExercise,
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s4.w,
        AppSpacing.s2.h,
        AppSpacing.s2.w,
        AppSpacing.s2.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context).ficheTitle,
              style: AppTypography.h3.copyWith(fontSize: AppFontSize.body),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              LucideIcons.x,
              size: AppIconSize.lg,
              color: AppColors.muted,
            ),
            padding: EdgeInsets.all(AppSpacing.s2),
            constraints: const BoxConstraints(),
            splashRadius: AppSpacing.s5,
          ),
        ],
      ),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState();

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
            AppLocalizations.of(context).ficheComingSoon,
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

class _SheetLoadingSkeleton extends StatelessWidget {
  const _SheetLoadingSkeleton();

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
