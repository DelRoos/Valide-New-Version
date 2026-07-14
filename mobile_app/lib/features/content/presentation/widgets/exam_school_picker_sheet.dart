import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Représentation d'une école dans le picker.
/// `id == null` = option « Toutes les écoles » (désactive le filtre).
/// `id == '_unknown_school_'` (cf. `_kUnknownSchoolId` dans exam_sujets_page)
/// = sentinel pour les sujets sans source dans les mocks.
class ExamSchoolOption {
  const ExamSchoolOption({required this.id, required this.label});

  /// `null` = option "Toutes les écoles".
  final String? id;
  final String label;
}

/// Ouvre le bottom sheet « Filtrer par école » avec recherche.
///
/// Utilise un callback pour distinguer « user a choisi » (`onSchoolSelected`
/// appelé, y compris avec `null` pour « Toutes les écoles ») de « user a
/// dismissed » (callback jamais appelé, aucune modification du filtre).
Future<void> showExamSchoolPickerSheet({
  required BuildContext context,
  required List<ExamSchoolOption> options,
  required ExamSchoolOption? selected,
  required ValueChanged<ExamSchoolOption?> onSchoolSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: AppColors.card,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.7,
      child: SafeArea(
        top: false,
        child: _SchoolPickerBody(
          options: options,
          selected: selected,
          onSelected: (opt) {
            Navigator.of(ctx, rootNavigator: true).pop();
            onSchoolSelected(opt);
          },
        ),
      ),
    ),
  );
}

class _SchoolPickerBody extends StatefulWidget {
  const _SchoolPickerBody({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<ExamSchoolOption> options;
  final ExamSchoolOption? selected;
  final ValueChanged<ExamSchoolOption?> onSelected;

  @override
  State<_SchoolPickerBody> createState() => _SchoolPickerBodyState();
}

class _SchoolPickerBodyState extends State<_SchoolPickerBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExamSchoolOption> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered();

    return Column(
      children: [
        _SheetHeader(title: l10n.examSujetsFilterSchoolSheetTitle),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w, 0, AppSpacing.s4.w, AppSpacing.s3.h,
          ),
          child: TextField(
            controller: _searchController,
            // TODO(Story 2.x) : debounce (~250 ms) quand la liste vient de
            // Firestore, pour éviter un rebuild par frappe sur grande
            // volumétrie. Acceptable en mock (liste < 10 écoles).
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: l10n.examSujetsFilterSchoolSheetSearchHint,
              prefixIcon: Icon(
                LucideIcons.search,
                size: AppIconSize.md,
                color: AppColors.muted,
              ),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: AppSpacing.s2.h,
                horizontal: AppSpacing.s3.w,
              ),
            ),
          ),
        ),
        // Option "Toutes les écoles" en tête (option null).
        _SchoolRow(
          label: l10n.examSujetsFilterSchoolAllChip,
          isAll: true,
          selected: widget.selected == null,
          onTap: () => widget.onSelected(null),
        ),
        Divider(
          color: AppColors.border,
          height: 1,
          indent: AppSpacing.s4.w,
          endIndent: AppSpacing.s4.w,
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(label: l10n.examSujetsFilterSchoolSheetEmpty)
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: AppSpacing.s4.h),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    color: AppColors.border,
                    height: 1,
                    indent: AppSpacing.s4.w,
                    endIndent: AppSpacing.s4.w,
                  ),
                  itemBuilder: (_, i) {
                    final opt = filtered[i];
                    return _SchoolRow(
                      label: opt.label,
                      selected: widget.selected?.id == opt.id,
                      onTap: () => widget.onSelected(opt),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s2.h),
          child: Container(
            width: AppSpacing.s9.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.mute2,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s4.w,
            AppSpacing.s1.h,
            AppSpacing.s2.w,
            AppSpacing.s3.h,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.ink,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  LucideIcons.x,
                  size: AppIconSize.lg,
                  color: AppColors.muted,
                ),
                padding: EdgeInsets.all(AppSpacing.s2.w),
                constraints: const BoxConstraints(),
                splashRadius: AppSpacing.s5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAll = false,
  });

  final String label;
  final bool selected;
  final bool isAll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4.w,
            vertical: AppSpacing.s3.h,
          ),
          child: Row(
            children: [
              Icon(
                isAll
                    ? LucideIcons.globe
                    : selected
                        ? LucideIcons.checkCircle
                        : LucideIcons.school,
                size: AppIconSize.lg,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
              SizedBox(width: AppSpacing.s3.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontSize: AppFontSize.bodySmall,
                    color: selected ? AppColors.primary : AppColors.ink,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  LucideIcons.check,
                  size: AppIconSize.md,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.search,
              size: AppIconSize.xl5,
              color: AppColors.mute2,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
