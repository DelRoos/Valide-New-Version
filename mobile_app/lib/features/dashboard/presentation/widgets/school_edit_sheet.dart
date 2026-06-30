import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/forms/school_entry.dart';
import '../../../../core/widgets/forms/school_search_with_add.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/school.dart';
import '../../../onboarding/providers.dart';

/// Bottom sheet de changement/retrait d'école.
///
/// Ouvert depuis le menu "Mon école" dans le profil.
class SchoolEditSheet extends ConsumerStatefulWidget {
  const SchoolEditSheet({
    super.key,
    required this.initialSchoolId,
    required this.initialSchoolName,
  });

  final String? initialSchoolId;
  final String? initialSchoolName;

  static Future<void> show(
    BuildContext context, {
    required String? schoolId,
    required String? schoolName,
  }) {
    return AppBottomSheet.show<void>(
      context,
      child: SchoolEditSheet(
        initialSchoolId: schoolId,
        initialSchoolName: schoolName,
      ),
    );
  }

  @override
  ConsumerState<SchoolEditSheet> createState() => _SchoolEditSheetState();
}

class _SchoolEditSheetState extends ConsumerState<SchoolEditSheet> {
  School? _selectedSchool;
  String _currentQuery = '';
  final Map<String, School> _schoolsMap = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(schoolSearchNotifierProvider.notifier).preload(limit: 300);
    });
  }

  void _onSelect(SchoolEntry entry) {
    final school = _schoolsMap[entry.id];
    setState(() => _selectedSchool = school);
    AppLogger.i('school.edit.select id=${entry.id}');
  }

  Future<String> _onAddRequest(String name) async {
    final repo = ref.read(schoolRepositoryProvider);
    final result = await repo.createSchoolRequest(name: name);
    return result.fold(
      (failure) {
        AppLogger.w('school.edit.addRequest failed: ${failure.message}');
        throw Exception(failure.message);
      },
      (_) {
        final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
        AppLogger.i('school.edit.addRequest OK localId=$localId');
        return localId;
      },
    );
  }

  SchoolSearchAsync _searchProvider(String query) {
    if (query != _currentQuery) {
      _currentQuery = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(schoolSearchNotifierProvider.notifier).search(query);
      });
    }
    final state = ref.watch(schoolSearchNotifierProvider);
    return state.when(
      data: (schools) {
        for (final s in schools) {
          _schoolsMap[s.schoolId] = s;
        }
        return SchoolSearchAsync.data(
          schools.map((s) => SchoolEntry(id: s.schoolId, name: s.name)).toList(),
        );
      },
      loading: () => SchoolSearchAsync.loading(),
      error: (e, _) => SchoolSearchAsync.error(isNetwork: true),
    );
  }

  Future<void> _onConfirm() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedSchool == null) return;

    setState(() => _loading = true);
    final repo = ref.read(userProfileRepositoryProvider);
    final result = await repo.updateLinkedSchool(_selectedSchool);

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => AppToast.show(
        context,
        message: l10n.errorGeneric,
        tone: ToastTone.error,
      ),
      (_) {
        AppToast.show(context, message: l10n.profileSchoolUpdateSuccess);
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _onRemove() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    final repo = ref.read(userProfileRepositoryProvider);
    final result = await repo.updateLinkedSchool(null);

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => AppToast.show(
        context,
        message: l10n.errorGeneric,
        tone: ToastTone.error,
      ),
      (_) {
        AppToast.show(context, message: l10n.profileSchoolUpdateSuccess);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasCurrentSchool = widget.initialSchoolId != null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560.w),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileSchoolSheetTitle, style: AppTypography.h3),
            SizedBox(height: AppSpacing.s4.h),
            SizedBox(
              height: 300.h,
              child: SchoolSearchWithAdd(
                selectedSchool: _selectedSchool != null
                    ? SchoolEntry(
                        id: _selectedSchool!.schoolId,
                        name: _selectedSchool!.name,
                      )
                    : null,
                onSelect: _onSelect,
                onAddRequest: _onAddRequest,
                searchProvider: _searchProvider,
                placeholder: l10n.onboardingSchoolPlaceholder,
                emptyAddTemplate: l10n.onboardingSchoolAddTemplate('{name}'),
                warningOfflineMessage: l10n.onboardingSchoolOfflineWarning,
              ),
            ),
            SizedBox(height: AppSpacing.s4.h),
            AppButton.primary(
              label: _loading ? l10n.sendingLabel : 'Enregistrer',
              onPressed: (_loading || _selectedSchool == null) ? null : _onConfirm,
            ),
            if (hasCurrentSchool) ...[
              SizedBox(height: AppSpacing.s2.h),
              TextButton.icon(
                onPressed: _loading ? null : _onRemove,
                icon: Icon(
                  LucideIcons.x,
                  size: AppIconSize.sm,
                  color: AppColors.danger,
                ),
                label: Text(
                  l10n.profileSchoolRemove,
                  style: AppTypography.body.copyWith(
                    color: AppColors.danger,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
