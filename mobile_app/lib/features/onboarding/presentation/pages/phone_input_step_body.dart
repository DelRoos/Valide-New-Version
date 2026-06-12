// Story E1bis-5 — Step body 7 du shell onboarding refonte.
//
// PHONE INPUT (+237 Cameroun). Reutilise PhoneInputWithCountryFlag
// (Story E1bis-0 widget foundation). Skip avec micro-friction (dialog
// confirmation). CLAUDE.md regle 4 securite : ne jamais logger le numero
// complet — masque via maskPhone() pour les logs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/log_safe.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/forms/phone_input_with_country_flag.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../state/onboarding_providers.dart';

class PhoneInputStepBody extends ConsumerStatefulWidget {
  const PhoneInputStepBody({super.key});

  @override
  ConsumerState<PhoneInputStepBody> createState() =>
      _PhoneInputStepBodyState();
}

class _PhoneInputStepBodyState extends ConsumerState<PhoneInputStepBody> {
  String _value = '';
  String? _errorText;

  static final _phoneRegex = RegExp(r'^\+237[26][0-9]{8}$');

  @override
  void initState() {
    super.initState();
    _value = ref.read(onboardingNotifierProvider).phoneNumber ?? '';
  }

  void _onChanged(String e164) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _value = e164;
      if (e164.isEmpty || _phoneRegex.hasMatch(e164)) {
        _errorText = null;
      } else if (e164.length >= 13) {
        _errorText = l10n.onboardingPhoneInvalid;
      } else {
        _errorText = null;
      }
    });
    if (_phoneRegex.hasMatch(e164)) {
      ref.read(onboardingNotifierProvider.notifier).setPhoneNumberDraft(e164);
      AppLogger.i('phone.draft set masked=${maskPhone(e164)}');
    } else {
      ref.read(onboardingNotifierProvider.notifier).setPhoneNumberDraft(null);
    }
  }

  Future<void> _onSkipTap() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingPhoneSkipConfirmTitle),
        content: Text(l10n.onboardingPhoneSkipConfirmMessage),
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
      ref.read(onboardingNotifierProvider.notifier).skipPhone();
      AppLogger.i('phone.skip confirmed');
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
            Icon(LucideIcons.phone, size: 56.sp, color: AppColors.primary),
            SizedBox(height: AppSpacing.s5.h),
            Text(
              l10n.onboardingPhoneTitle,
              style: AppTypography.h1.copyWith(fontSize: 24.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              l10n.onboardingPhoneSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s6.h),
            PhoneInputWithCountryFlag(
              value: _value,
              onChanged: _onChanged,
              errorText: _errorText,
              autofocus: true,
            ),
            SizedBox(height: AppSpacing.s5.h),
            TextButton(
              onPressed: _onSkipTap,
              child: Text(
                l10n.onboardingPhoneSkipLabel,
                style: AppTypography.body.copyWith(
                  color: AppColors.inkSoft,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.s5.h),
          ],
        ),
      ),
    );
  }
}
