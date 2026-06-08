// Story 1.7 AC1-AC6 — Page de liaison ecole optionnelle (FR-6).
//
// Affichee post-success Story 1.6 (AccountCreationPage success navigue ici
// au lieu de /hello).
//
// 3 sorties possibles :
//   1. Tap card ecole -> users/{uid}.schoolId = chosenId -> /hello
//   2. Etat vide -> bouton "Ajouter mon ecole" -> modale -> demande envoyee -> /hello
//   3. Tap "Passer cette etape" -> nav /hello sans update (schoolId reste null
//      par defaut Story 1.3)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/school.dart';
import '../providers.dart';

class SchoolPickerPage extends ConsumerStatefulWidget {
  const SchoolPickerPage({super.key});

  @override
  ConsumerState<SchoolPickerPage> createState() => _SchoolPickerPageState();
}

class _SchoolPickerPageState extends ConsumerState<SchoolPickerPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLinking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchState = ref.watch(schoolSearchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 840;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s5.w,
                    vertical: AppSpacing.s6.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.onboardingSchoolTitle,
                        style: AppTypography.h2,
                      ),
                      SizedBox(height: AppSpacing.s2.h),
                      Text(
                        l10n.onboardingSchoolSubtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s5.h),
                      TextField(
                        controller: _controller,
                        enabled: !_isLinking,
                        decoration: InputDecoration(
                          hintText: l10n.onboardingSchoolSearchPlaceholder,
                          prefixIcon: const Icon(LucideIcons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onChanged: (q) => ref
                            .read(schoolSearchNotifierProvider.notifier)
                            .search(q),
                      ),
                      SizedBox(height: AppSpacing.s4.h),
                      Expanded(
                        child: _buildResults(searchState, l10n),
                      ),
                      SizedBox(height: AppSpacing.s3.h),
                      AppButton.secondary(
                        label: l10n.onboardingSchoolSkipCta,
                        onPressed: _isLinking ? null : _onSkip,
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

  Widget _buildResults(
    AsyncValue<List<School>> state,
    AppLocalizations l10n,
  ) {
    return state.when(
      data: (schools) {
        if (schools.isEmpty) {
          final query = _controller.text.trim();
          if (query.length < 2) {
            return const SizedBox.shrink();
          }
          return _EmptyState(
            query: query,
            onAddSchool: _isLinking ? null : _onShowAddDialog,
          );
        }
        return ListView.separated(
          itemCount: schools.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s2.h),
          itemBuilder: (context, index) {
            final s = schools[index];
            return _SchoolCard(
              school: s,
              onTap: _isLinking ? null : () => _onPickSchool(s),
              validatedLabel: l10n.onboardingSchoolValidatedBadge,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text(
          l10n.errorGeneric,
          style: AppTypography.body.copyWith(color: AppColors.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _onPickSchool(School school) async {
    if (_isLinking) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isLinking = true);

    final repo = ref.read(userProfileRepositoryProvider);
    final result = await repo.updateSchoolId(school.schoolId);

    if (!mounted) return;
    setState(() => _isLinking = false);

    result.fold(
      (failure) {
        AppLogger.w('updateSchoolId failed: ${failure.message}');
        AppToast.show(
          context,
          message: l10n.onboardingSchoolGenericErrorToast,
          tone: ToastTone.warning,
        );
      },
      (_) {
        GoRouter.of(context).go('/hello');
      },
    );
  }

  void _onSkip() {
    final l10n = AppLocalizations.of(context);
    AppLogger.i('School linking skipped');
    AppToast.show(
      context,
      message: l10n.onboardingSchoolSkipToast,
      tone: ToastTone.info,
    );
    GoRouter.of(context).go('/hello');
  }

  Future<void> _onShowAddDialog() async {
    final result = await showDialog<_AddSchoolFormData>(
      context: context,
      builder: (dialogContext) => const _AddSchoolDialog(),
    );
    if (result == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    final repo = ref.read(schoolRepositoryProvider);
    final outcome = await repo.requestSchool(
      name: result.name,
      city: result.city,
      region: result.region,
    );

    if (!mounted) return;
    outcome.fold(
      (failure) {
        AppLogger.w('requestSchool failed: ${failure.message}');
        AppToast.show(
          context,
          message: l10n.onboardingSchoolGenericErrorToast,
          tone: ToastTone.warning,
        );
      },
      (_) {
        AppToast.show(
          context,
          message: l10n.onboardingSchoolAddRequestSentToast,
          tone: ToastTone.info,
        );
        GoRouter.of(context).go('/hello');
      },
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({
    required this.school,
    required this.onTap,
    required this.validatedLabel,
  });

  final School school;
  final VoidCallback? onTap;
  final String validatedLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.s4.w),
        child: Row(
          children: [
            Icon(
              LucideIcons.school,
              color: AppColors.primary,
              size: 28.sp,
            ),
            SizedBox(width: AppSpacing.s3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school.name, style: AppTypography.bodyStrong),
                  SizedBox(height: AppSpacing.s1.h),
                  Text(
                    '${school.city}, ${school.region}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.s2.w),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s2.w,
                vertical: AppSpacing.s1.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.badgeCheck,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.s1.w),
                  Text(
                    validatedLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onAddSchool});

  final String query;
  final VoidCallback? onAddSchool;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 48.sp,
            color: AppColors.inkSoft,
          ),
          SizedBox(height: AppSpacing.s4.h),
          Text(
            l10n.onboardingSchoolEmptyTitle(query),
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.s5.h),
          AppButton.primary(
            label: l10n.onboardingSchoolAddCta,
            icon: LucideIcons.plus,
            onPressed: onAddSchool,
          ),
        ],
      ),
    );
  }
}

class _AddSchoolFormData {
  const _AddSchoolFormData({
    required this.name,
    required this.city,
    this.region,
  });
  final String name;
  final String city;
  final String? region;
}

class _AddSchoolDialog extends StatefulWidget {
  const _AddSchoolDialog();

  @override
  State<_AddSchoolDialog> createState() => _AddSchoolDialogState();
}

class _AddSchoolDialogState extends State<_AddSchoolDialog> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty && _cityCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.onboardingSchoolAddDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l10n.onboardingSchoolAddDialogNameLabel,
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _cityCtrl,
            decoration: InputDecoration(
              labelText: l10n.onboardingSchoolAddDialogCityLabel,
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _regionCtrl,
            decoration: InputDecoration(
              labelText: l10n.onboardingSchoolAddDialogRegionLabel,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.back),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () {
                  final regionInput = _regionCtrl.text.trim();
                  Navigator.of(context).pop(
                    _AddSchoolFormData(
                      name: _nameCtrl.text.trim(),
                      city: _cityCtrl.text.trim(),
                      region: regionInput.isEmpty ? null : regionInput,
                    ),
                  );
                }
              : null,
          child: Text(l10n.onboardingSchoolAddDialogSubmitCta),
        ),
      ],
    );
  }
}
