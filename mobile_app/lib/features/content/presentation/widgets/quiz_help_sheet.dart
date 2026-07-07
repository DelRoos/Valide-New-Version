import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/pedagogical_content.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/notion_entity.dart';
import '../../providers.dart';

class QuizHelpSheet extends ConsumerWidget {
  const QuizHelpSheet({super.key, required this.notionId, required this.isFr});

  final String? notionId;
  // isFr : langue du contenu pédagogique (notion title/body), pas de l'UI.
  final bool isFr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
              AppSpacing.s4,
              AppSpacing.s3,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.warning,
                  size: AppIconSize.xl2,
                ),
                SizedBox(width: AppSpacing.s2),
                Text(
                  l10n.quizNeedHelp,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.h3Compact,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),

          // ── Contenu notion ─────────────────────────────────────────────
          Flexible(
            child: notionId != null
                ? QuizNotionContent(notionId: notionId!, isFr: isFr)
                : const QuizNoNotionFallback(),
          ),

          // ── Bouton fermer ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s2,
              AppSpacing.s4,
              AppSpacing.s4 + MediaQuery.paddingOf(context).bottom,
            ),
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, AppSpacing.s12),
                side: const BorderSide(
                  color: AppColors.border,
                  width: AppBorderWidth.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                l10n.closeLabel,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizNotionContent extends ConsumerWidget {
  const QuizNotionContent({super.key, required this.notionId, required this.isFr});

  final String notionId;
  // isFr : sélection langue du contenu notion (fr/en).
  final bool isFr;

  String get _langCode => isFr ? 'fr' : 'en';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notionAsync = ref.watch(notionProvider(notionId));
    return notionAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const QuizNoNotionFallback(),
      data: (NotionEntity? notion) {
        if (notion == null) return const QuizNoNotionFallback();
        final title = notion.titleFor(_langCode);
        final content = notion.contentFor(_langCode);
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: AppSpacing.s3),
              ],
              if (content.isNotEmpty)
                PedagogicalContent(data: content)
              else
                const QuizNoNotionFallback(),
            ],
          ),
        );
      },
    );
  }
}

class QuizNoNotionFallback extends StatelessWidget {
  const QuizNoNotionFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.s4),
      child: Text(
        AppLocalizations.of(context).quizNoNotionHint,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppFontSize.body,
          color: AppColors.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
