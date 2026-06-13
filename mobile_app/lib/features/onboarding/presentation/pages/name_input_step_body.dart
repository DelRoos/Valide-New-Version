// Story E1bis-5 — Step body 6 du shell onboarding refonte.
//
// NAME INPUT. TextField simple avec validation 2-50 caracteres. Tous les
// comptes permanents passent par ici (audit 2026-06-13 PR3) : le notifier
// pre-remplit avec le displayName OAuth (Google/Apple) si fourni, et
// l'utilisateur peut le modifier avant validation. Le visiteur n'arrive
// jamais ici (nav direct dashboard depuis AuthChoiceStepBody).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../state/onboarding_providers.dart';

class NameInputStepBody extends ConsumerStatefulWidget {
  const NameInputStepBody({super.key});

  @override
  ConsumerState<NameInputStepBody> createState() => _NameInputStepBodyState();
}

class _NameInputStepBodyState extends ConsumerState<NameInputStepBody> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(onboardingNotifierProvider).userDisplayName ?? '';
    _controller = TextEditingController(text: initial);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final value = _controller.text;
    final l10n = AppLocalizations.of(context);
    String? error;
    if (value.trim().length < 2 && value.isNotEmpty) {
      error = l10n.onboardingNameTooShort;
    } else if (value.length > 50) {
      error = l10n.onboardingNameTooLong;
    }
    if (_errorText != error) {
      setState(() => _errorText = error);
    }
    // Pas de side-effect : le shell footer lit l'etat current du controller
    // via le notifier pour activer/desactiver le CTA.
    if (error == null && value.trim().length >= 2) {
      ref
          .read(onboardingNotifierProvider.notifier)
          .setUserDisplayNameDraft(value.trim());
    } else {
      ref
          .read(onboardingNotifierProvider.notifier)
          .setUserDisplayNameDraft(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.s8.h),
            Icon(LucideIcons.user, size: 56.sp, color: AppColors.primary),
            SizedBox(height: AppSpacing.s5.h),
            Text(
              l10n.onboardingNameTitle,
              style: AppTypography.h1.copyWith(fontSize: 24.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              l10n.onboardingNameSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s6.h),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.onboardingNamePlaceholder,
                errorText: _errorText,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4.w,
                  vertical: AppSpacing.s4.h,
                ),
              ),
              style: AppTypography.body.copyWith(fontSize: 16.sp),
            ),
            SizedBox(height: AppSpacing.s5.h),
          ],
        ),
      ),
    );
  }
}
