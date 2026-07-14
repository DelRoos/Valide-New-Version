import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/catalogue/domain/models.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/cards/subject_palette.dart';
import '../../../../core/widgets/picker/subject_icon_resolver.dart';
import '../../../../l10n/generated/app_localizations.dart';

// Seuil au-delà duquel on affiche le champ recherche dans le picker.
const int _kSearchThreshold = 8;

// Mock — sera remplacé par les compteurs réels par (matière, séquence) en Story 2.x.
const List<int> _kMockSujetsTotal = [8, 6, 5, 10, 7, 4, 9, 6, 7, 5, 8, 6, 9, 4];
const List<int> _kMockSujetsDone = [3, 0, 2, 7, 1, 4, 5, 0, 2, 1, 3, 0, 6, 2];

int _totalForMatiere(int subjectIndex, int seq) =>
    _kMockSujetsTotal[(subjectIndex + seq) % _kMockSujetsTotal.length];

int _doneForMatiere(int subjectIndex, int seq) =>
    _kMockSujetsDone[(subjectIndex + seq) % _kMockSujetsDone.length]
        .clamp(0, _totalForMatiere(subjectIndex, seq));

/// Ouvre le bottom sheet « Choisis ta matière » scopé à une séquence.
///
/// Capture le [GoRouter] avant l'ouverture pour permettre au sheet de
/// pop + push sans dépendre d'un context démonté.
Future<void> showExamsMatierePickerSheet({
  required BuildContext context,
  required int sequenceNumber,
  required List<Subject> subjects,
  required String langKey,
  String? eyebrowLabel,
}) {
  final router = GoRouter.of(context);
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
        child: _MatierePickerBody(
          sequenceNumber: sequenceNumber,
          subjects: subjects,
          langKey: langKey,
          eyebrowLabel: eyebrowLabel,
          onSubjectSelected: (subject) {
            Navigator.of(ctx, rootNavigator: true).pop();
            router.push(AppRoutes.examSujets(sequenceNumber, subject.subjectId));
          },
        ),
      ),
    ),
  );
}

class _MatierePickerBody extends StatefulWidget {
  const _MatierePickerBody({
    required this.sequenceNumber,
    required this.subjects,
    required this.langKey,
    required this.onSubjectSelected,
    this.eyebrowLabel,
  });

  final int sequenceNumber;
  final List<Subject> subjects;
  final String langKey;
  final String? eyebrowLabel;
  final ValueChanged<Subject> onSubjectSelected;

  @override
  State<_MatierePickerBody> createState() => _MatierePickerBodyState();
}

class _MatierePickerBodyState extends State<_MatierePickerBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SortedSubject> _sortedFiltered() {
    final query = _query.trim().toLowerCase();
    final indexed = <_SortedSubject>[];
    for (var i = 0; i < widget.subjects.length; i++) {
      final s = widget.subjects[i];
      final label = s.abbreviationFor(widget.langKey) ??
          s.name[widget.langKey] ??
          s.name['fr'] ??
          s.subjectId;
      if (query.isNotEmpty && !label.toLowerCase().contains(query)) continue;
      final total = _totalForMatiere(i, widget.sequenceNumber);
      final done = _doneForMatiere(i, widget.sequenceNumber);
      indexed.add(_SortedSubject(
        originalIndex: i,
        subject: s,
        label: label,
        done: done,
        total: total,
      ));
    }
    // Tri : matières commencées d'abord (done > 0), sinon ordre catalogue.
    indexed.sort((a, b) {
      final aStarted = a.done > 0;
      final bStarted = b.done > 0;
      if (aStarted != bStarted) return aStarted ? -1 : 1;
      return a.originalIndex.compareTo(b.originalIndex);
    });
    return indexed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showSearch = widget.subjects.length > _kSearchThreshold;
    final rows = _sortedFiltered();

    return Column(
      children: [
        _SheetHeader(
          eyebrow: widget.eyebrowLabel ??
              l10n.examsFolderSequenceTitle(widget.sequenceNumber),
          title: l10n.examsMatierePickerTitle,
        ),
        if (showSearch)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4.w,
              0,
              AppSpacing.s4.w,
              AppSpacing.s3.h,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l10n.examsMatierePickerSearchHint,
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
        Expanded(
          child: rows.isEmpty
              ? _EmptyState(label: l10n.examsMatierePickerEmpty)
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: AppSpacing.s4.h),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => Divider(
                    color: AppColors.border,
                    height: 1,
                    indent: AppSpacing.s4.w + AppSpacing.s10 + AppSpacing.s3.w,
                    endIndent: AppSpacing.s4.w,
                  ),
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return _MatiereRow(
                      subject: row.subject,
                      label: row.label,
                      done: row.done,
                      total: row.total,
                      color: subjectColorAt(row.originalIndex),
                      onTap: () => widget.onSubjectSelected(row.subject),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SortedSubject {
  const _SortedSubject({
    required this.originalIndex,
    required this.subject,
    required this.label,
    required this.done,
    required this.total,
  });

  final int originalIndex;
  final Subject subject;
  final String label;
  final int done;
  final int total;
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.eyebrow,
    required this.title,
  });

  final String eyebrow;
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eyebrow,
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSize.eyebrow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.ink,
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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

class _MatiereRow extends StatelessWidget {
  const _MatiereRow({
    required this.subject,
    required this.label,
    required this.done,
    required this.total,
    required this.color,
    required this.onTap,
  });

  final Subject subject;
  final String label;
  final int done;
  final int total;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: AppSpacing.s10,
                height: AppSpacing.s10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(
                  subjectIconFor(subject.icon),
                  size: AppIconSize.xl2,
                  color: color,
                ),
              ),
              SizedBox(width: AppSpacing.s3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.ink,
                        fontSize: AppFontSize.bodySmall,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.s075.h),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: progress.toDouble(),
                              backgroundColor:
                                  color.withValues(alpha: 0.12),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                              minHeight: AppDimension.progressBarThin,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.s2.w),
                        Text(
                          '$done/$total',
                          style: AppTypography.eyebrow.copyWith(
                            color: AppColors.muted,
                            fontSize: AppFontSize.tiny,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.s2.w),
              Icon(
                LucideIcons.chevronRight,
                size: AppIconSize.md,
                color: AppColors.muted,
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
