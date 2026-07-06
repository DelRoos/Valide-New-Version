import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/errors/content_error_view.dart';
import '../../../../core/widgets/pedagogical_content.dart';
import '../../domain/failures/content_failure.dart';
import '../../providers.dart';

class FicheTab extends ConsumerWidget {
  const FicheTab({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.languageCode,
  });

  final String subjectId;
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
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s4,
                    AppSpacing.s6 + bottomInset,
                  ),
                  child: PedagogicalContent(data: content),
                ),
                Positioned(
                  top: AppSpacing.s2.h,
                  right: AppSpacing.s2.w,
                  child: _ExpandButton(
                    onTap: () => _openFullscreen(context, content),
                  ),
                ),
              ],
            );
          },
        );

        if (maxWidth < width) {
          return Center(child: SizedBox(width: maxWidth, child: body));
        }
        return body;
      },
    );
  }

  void _openFullscreen(BuildContext context, String content) {
    final topPad = MediaQuery.paddingOf(context).top;
    final sheetHeight = MediaQuery.sizeOf(context).height - topPad;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      builder: (ctx) => SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl2),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: _FicheFullscreenSheet(
            content: content,
            languageCode: languageCode,
            onClose: () => Navigator.of(ctx, rootNavigator: true).pop(),
            onExercise: () {
              Navigator.of(ctx, rootNavigator: true).pop();
              context.push(AppRoutes.chapterQuiz(subjectId, chapterId));
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet plein écran avec scroll progress + CTA
// ─────────────────────────────────────────────────────────────────────────────

class _FicheFullscreenSheet extends StatefulWidget {
  const _FicheFullscreenSheet({
    required this.content,
    required this.languageCode,
    required this.onClose,
    required this.onExercise,
  });

  final String content;
  final String languageCode;
  final VoidCallback onClose;
  final VoidCallback onExercise;

  @override
  State<_FicheFullscreenSheet> createState() => _FicheFullscreenSheetState();
}

class _FicheFullscreenSheetState extends State<_FicheFullscreenSheet> {
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isFr = widget.languageCode == 'fr';

    return Column(
      children: [
        // ── Header : handle + titre + fermer ────────────────────────────
        _FicheSheetHeader(isFr: isFr, onClose: widget.onClose),

        // ── Barre de progression lecture ─────────────────────────────────
        LinearProgressIndicator(
          value: _progress,
          minHeight: 3,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),

        // ── Contenu scrollable ───────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            child: PedagogicalContent(data: widget.content),
          ),
        ),

        // ── CTA S'exercer ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            AppSpacing.s3.h,
            AppSpacing.s4.w,
            AppSpacing.s3.h + bottomInset,
          ),
          child: AppButton.primary(
            label: isFr ? "S'exercer sur ce chapitre" : 'Practice this chapter',
            onPressed: widget.onExercise,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FicheSheetHeader extends StatelessWidget {
  const _FicheSheetHeader({required this.isFr, required this.onClose});

  final bool isFr;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
          child: Container(
            width: AppSpacing.s9.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.mute2,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        // Titre + bouton fermer
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s5.w, 0, AppSpacing.s2.w, AppSpacing.s3.h,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                isFr ? 'Fiche de révision' : 'Study Sheet',
                style: AppTypography.h3,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    LucideIcons.x,
                    size: AppIconSize.xl,
                    color: AppColors.muted,
                  ),
                  padding: EdgeInsets.all(AppSpacing.s2),
                  constraints: const BoxConstraints(),
                  splashRadius: AppSpacing.s5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 2,
      shadowColor: AppColors.ink.withValues(alpha: 0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s2),
          child: Icon(
            LucideIcons.maximize2,
            size: AppIconSize.lg,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
