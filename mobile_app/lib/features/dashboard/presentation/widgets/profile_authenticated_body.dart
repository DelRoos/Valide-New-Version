import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app.dart';
import '../../../../core/firebase/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/profile_failure.dart';
import '../../../onboarding/presentation/state/onboarding_providers.dart';
import '../../../onboarding/providers.dart';
import 'complete_profile_dialog.dart';
import 'name_edit_sheet.dart';
import 'phone_edit_sheet.dart';
import 'profile_account_section.dart';
import 'profile_header.dart';
import 'profile_menu_section.dart';
import 'profile_stats_row.dart';
import 'school_edit_sheet.dart';

class ProfileAuthenticatedBody extends ConsumerWidget {
  const ProfileAuthenticatedBody({
    super.key,
    required this.l10n,
    required this.languageCode,
  });

  final AppLocalizations l10n;
  final String languageCode;

  static String _errorMessage(AppLocalizations l10n, Object? error) {
    String? code;
    try {
      code = (error as dynamic).code as String?;
    } catch (_) {}
    final kind = profileFailureKindForCode(code);
    return switch (kind) {
      ProfileFailureKind.permissionDenied ||
      ProfileFailureKind.notAuthenticated =>
        l10n.errorPermissionDenied,
      ProfileFailureKind.networkUnavailable => l10n.errorNetworkUnavailable,
      ProfileFailureKind.unknown => l10n.errorFirestoreUnknown,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    final data = profileAsync.maybeWhen(data: (d) => d, orElse: () => null);

    ref.listen<AsyncValue<Map<String, dynamic>?>>(
      profileDataProvider,
      (prev, next) {
        if (next.hasError && !(prev?.hasError ?? false)) {
          AppLogger.w('ProfileAuthenticatedBody: profileDataProvider error=${next.error}');
          AppToast.show(
            context,
            message: _errorMessage(l10n, next.error),
            tone: ToastTone.warning,
          );
        }
      },
    );

    final schoolId = data?['schoolId'] as String?;
    final schoolName = data?['schoolName'] as String?;
    final displayName = data?['displayName'] as String?;
    final phoneNumber = data?['phoneNumber'] as String?;
    final subjectsCount = (data?['pickedSubjects'] as List?)?.length ?? 0;
    final examsCount = (data?['examTargets'] as List?)?.length ?? 0;
    final currentLocale = ref.watch(localeProvider);
    final currentLanguageLabel = currentLocale.languageCode == 'fr'
        ? l10n.languageOptionFrench
        : l10n.languageOptionEnglish;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ProfileHeader(l10n: l10n, languageCode: languageCode),
        ),
        SliverToBoxAdapter(
          child: ProfileStatsRow(
            l10n: l10n,
            subjectsCount: subjectsCount,
            examsCount: examsCount,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s4.w,
              AppSpacing.s5.h,
              AppSpacing.s4.w,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section compte : école, nom, numéro — toujours visibles.
                ProfileMenuSection(
                  title: l10n.profileSectionAccount,
                  items: [
                    ProfileMenuItemData(
                      icon: LucideIcons.school,
                      label: l10n.profileMenuSchool,
                      subtitle: schoolName,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => CompleteProfileDialog.guardAnonymous(
                        context,
                        ref,
                        action: () => SchoolEditSheet.show(
                          context,
                          schoolId: schoolId,
                          schoolName: schoolName,
                        ),
                      ),
                    ),
                    ProfileMenuItemData(
                      icon: LucideIcons.userRound,
                      label: l10n.profileMenuName,
                      subtitle: (displayName != null && displayName.isNotEmpty)
                          ? displayName
                          : l10n.profileMenuAddName,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => CompleteProfileDialog.guardAnonymous(
                        context,
                        ref,
                        action: () => NameEditSheet.show(
                          context,
                          displayName: displayName ?? '',
                        ),
                      ),
                    ),
                    ProfileMenuItemData(
                      icon: LucideIcons.phone,
                      label: l10n.profileMenuPhone,
                      subtitle: (phoneNumber != null && phoneNumber.isNotEmpty)
                          ? phoneNumber
                          : l10n.profileMenuAddPhone,
                      color: const Color(0xFF10B981),
                      onTap: () => CompleteProfileDialog.guardAnonymous(
                        context,
                        ref,
                        action: () => PhoneEditSheet.show(
                          context,
                          phoneNumber: phoneNumber,
                        ),
                      ),
                    ),
                    ProfileMenuItemData(
                      icon: LucideIcons.logOut,
                      label: l10n.profileMenuSignOut,
                      color: AppColors.danger,
                      onTap: () => CompleteProfileDialog.guardAnonymous(
                        context,
                        ref,
                        action: () =>
                            _showSignOutDialog(context, ref, l10n),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.s4.h),
                ProfileMenuSection(
                  title: l10n.profileSectionCourses,
                  items: [
                    ProfileMenuItemData(
                      icon: LucideIcons.star,
                      label: l10n.profileMenuSubscription,
                      color: const Color(0xFFF59E0B),
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.featureComingSoon,
                        tone: ToastTone.info,
                      ),
                    ),
                    ProfileMenuItemData(
                      icon: LucideIcons.barChart2,
                      label: l10n.profileMenuResults,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.featureComingSoon,
                        tone: ToastTone.info,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.s4.h),
                ProfileMenuSection(
                  title: l10n.profileSectionSettings,
                  items: [
                    ProfileMenuItemData(
                      icon: LucideIcons.languages,
                      label: l10n.profileMenuLanguage,
                      subtitle: currentLanguageLabel,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _showLanguagePicker(context, ref, l10n),
                    ),
                    ProfileMenuItemData(
                      icon: LucideIcons.bell,
                      label: l10n.profileMenuNotifications,
                      color: const Color(0xFF10B981),
                      onTap: () => AppToast.show(
                        context,
                        message: l10n.featureComingSoon,
                        tone: ToastTone.info,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Section compte : email/provider + suppression.
        const SliverToBoxAdapter(child: ProfileAccountSection()),
      ],
    );
  }
}

Future<void> _showLanguagePicker(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) async {
  final current = ref.read(localeProvider);
  await AppBottomSheet.show<void>(
    context,
    title: l10n.languagePickerTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LanguageOption(
          label: l10n.languageOptionFrench,
          languageCode: 'fr',
          selected: current.languageCode == 'fr',
        ),
        SizedBox(height: AppSpacing.s2.h),
        _LanguageOption(
          label: l10n.languageOptionEnglish,
          languageCode: 'en',
          selected: current.languageCode == 'en',
        ),
      ],
    ),
  );
}

class _LanguageOption extends ConsumerWidget {
  const _LanguageOption({
    required this.label,
    required this.languageCode,
    required this.selected,
  });

  final String label;
  final String languageCode;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        ref
            .read(localeProvider.notifier)
            .setLocale(Locale(languageCode));
        Navigator.of(context).pop();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s4.w,
          vertical: AppSpacing.s4.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: selected ? AppColors.primarySoft : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: AppBorderWidth.hairline,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyStrong.copyWith(
                  color: selected ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: AppIconSize.md,
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showSignOutDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (dialogContext) {
      var loading = false;
      return StatefulBuilder(
        builder: (_, setState) => AppDialogCard(
          title: l10n.signOutConfirmTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.signOutConfirmBody,
                style: AppTypography.body.copyWith(
                  color: AppColors.inkSoft,
                  fontSize: AppFontSize.body,
                ),
              ),
              SizedBox(height: AppSpacing.s6.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: l10n.cancelLabel,
                      onPressed: loading
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s3.w),
                  Expanded(
                    child: AppButton.danger(
                      label: l10n.signOutConfirmCta,
                      loading: loading,
                      onPressed: loading
                          ? null
                          : () async {
                              setState(() => loading = true);
                              ref
                                  .read(onboardingNotifierProvider.notifier)
                                  .reset();
                              await ref
                                  .read(firebaseAuthProvider)
                                  .signOut();
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
