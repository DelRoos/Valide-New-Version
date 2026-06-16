// Story E1bis-6 — Step body 8 du shell onboarding refonte.
//
// SCHOOL SEARCH. Reutilise SchoolSearchWithAdd (Story E1bis-0 widget
// foundation). Recherche Firestore via schoolSearchNotifierProvider
// (Story 1.7). Ajout custom -> createSchoolRequest. Skip avec micro-friction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/forms/school_entry.dart';
import '../../../../core/widgets/forms/school_search_with_add.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../providers.dart';
import '../state/onboarding_providers.dart';

class SchoolInputStepBody extends ConsumerStatefulWidget {
  const SchoolInputStepBody({super.key});

  @override
  ConsumerState<SchoolInputStepBody> createState() =>
      _SchoolInputStepBodyState();
}

class _SchoolInputStepBodyState extends ConsumerState<SchoolInputStepBody> {
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(schoolSearchNotifierProvider.notifier).preload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingNotifierProvider);

    final selected = state.schoolId != null && state.schoolName != null
        ? SchoolEntry(id: state.schoolId!, name: state.schoolName!)
        : state.pendingSchoolRequestId != null && state.schoolName != null
            ? SchoolEntry(
                id: state.pendingSchoolRequestId!,
                name: state.schoolName!,
                isPending: true,
              )
            : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.s5.h),
            Icon(LucideIcons.school, size: 48.sp, color: AppColors.primary),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              l10n.onboardingSchoolTitle,
              style: AppTypography.h1.copyWith(fontSize: 22.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s2.h),
            Text(
              l10n.onboardingSchoolSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s5.h),
            SchoolSearchWithAdd(
              selectedSchool: selected,
              onSelect: _onSelect,
              onAddRequest: _onAddRequest,
              searchProvider: _searchProvider,
              placeholder: l10n.onboardingSchoolPlaceholder,
              emptyAddTemplate: l10n.onboardingSchoolAddTemplate('{name}'),
              warningOfflineMessage: l10n.onboardingSchoolOfflineWarning,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Center(
              child: TextButton(
                onPressed: _onSkipTap,
                child: Text(
                  l10n.onboardingSchoolSkipLabel,
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkSoft,
                    decoration: TextDecoration.underline,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.s5.h),
          ],
        ),
      ),
    );
  }

  Future<void> _onSkipTap() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingPhoneSkipConfirmTitle),
        content: Text(l10n.onboardingSchoolSkipToast),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.onboardingPhoneSkipConfirmNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.onboardingPhoneSkipConfirmYes),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      AppLogger.i('school.skip confirmed');
      ref.read(onboardingNotifierProvider.notifier).skipSchool();
    }
  }

  void _onSelect(SchoolEntry school) {
    if (school.isPending) {
      ref.read(onboardingNotifierProvider.notifier).setPendingSchoolRequest(
            pendingRequestId: school.id,
            schoolName: school.name,
          );
    } else {
      ref.read(onboardingNotifierProvider.notifier).setSchool(
            schoolId: school.id,
            schoolName: school.name,
          );
    }
    AppLogger.i(
      'school.select id=${school.id} pending=${school.isPending}',
    );
  }

  Future<String> _onAddRequest(String name) async {
    final repo = ref.read(schoolRepositoryProvider);
    final state = ref.read(onboardingNotifierProvider);
    final result = await repo.createSchoolRequest(
      name: name,
      subSystem: state.subSystem?.id,
    );
    return result.fold(
      (failure) {
        AppLogger.w('school.addRequest failed: ${failure.message}');
        throw Exception(failure.message);
      },
      (_) {
        // Le repo ne retourne pas l'ID Firestore (V1 Story 1.7). On genere
        // un ID client temporaire pour le state (le user n'a pas besoin de
        // l'ID Firestore avant l'ecran "Mes demandes" Epic 2).
        final localId =
            'local-${DateTime.now().millisecondsSinceEpoch}';
        AppLogger.i('school.addRequest OK localId=$localId');
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
      data: (schools) => SchoolSearchAsync.data(
        schools
            .map((s) => SchoolEntry(id: s.schoolId, name: s.name))
            .toList(),
      ),
      loading: () => SchoolSearchAsync.loading(),
      error: (e, _) =>
          SchoolSearchAsync.error(isNetwork: e.toString().contains('network')),
    );
  }
}
