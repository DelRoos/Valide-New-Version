import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/forms/phone_input_with_country_flag.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/profile_failure.dart';
import '../../../onboarding/providers.dart';

class ProfileSetupSheet extends ConsumerStatefulWidget {
  const ProfileSetupSheet._({required this.initialDisplayName});

  final String initialDisplayName;

  static Future<void> show(
    BuildContext context, {
    required String displayName,
  }) {
    return AppBottomSheet.show<void>(
      context,
      child: ProfileSetupSheet._(initialDisplayName: displayName),
    );
  }

  @override
  ConsumerState<ProfileSetupSheet> createState() => _ProfileSetupSheetState();
}

class _ProfileSetupSheetState extends ConsumerState<ProfileSetupSheet> {
  late final TextEditingController _nameCtrl;
  String _phone = '';
  String? _nameError;
  String? _phoneError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDisplayName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String name) {
    final l10n = AppLocalizations.of(context);
    if (name.trim().length < 2) return l10n.onboardingNameTooShort;
    if (name.trim().length > 50) return l10n.onboardingNameTooLong;
    return null;
  }

  String? _validatePhone(String phone) {
    if (phone.isEmpty) return null;
    if (!RegExp(r'^\+237[26][0-9]{8}$').hasMatch(phone)) {
      return AppLocalizations.of(context).onboardingPhoneInvalid;
    }
    return null;
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context);
    final nameErr = _validateName(_nameCtrl.text);
    final phoneErr = _validatePhone(_phone);
    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _loading = nameErr == null && phoneErr == null;
    });
    if (nameErr != null || phoneErr != null) return;

    String? toastError;

    final nameResult = await ref
        .read(userProfileRepositoryProvider)
        .updateDisplayName(_nameCtrl.text.trim());
    if (!mounted) return;
    nameResult.fold(
      (f) {
        AppLogger.w(
          'ProfileSetupSheet.updateDisplayName: kind=${f.kind.name} message=${f.message}',
        );
        toastError = _errorMessage(l10n, f);
      },
      (_) {},
    );

    if (toastError != null) {
      setState(() => _loading = false);
      AppToast.show(context, message: toastError!, tone: ToastTone.error);
      return;
    }

    if (_phone.isNotEmpty) {
      final phoneResult = await ref
          .read(userProfileRepositoryProvider)
          .updatePhoneNumber(_phone);
      if (!mounted) return;
      phoneResult.fold(
        (f) {
          AppLogger.w(
            'ProfileSetupSheet.updatePhoneNumber: kind=${f.kind.name} message=${f.message}',
          );
          toastError = _errorMessage(l10n, f);
        },
        (_) {},
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (toastError != null) {
      AppToast.show(context, message: toastError!, tone: ToastTone.error);
      return;
    }

    AppToast.show(context, message: l10n.profileEditSuccess);
    // AppBottomSheet utilise useRootNavigator:true → pop doit cibler le root navigator.
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  String _errorMessage(AppLocalizations l10n, ProfileFailure f) {
    return switch (f.kind) {
      ProfileFailureKind.permissionDenied ||
      ProfileFailureKind.notAuthenticated =>
        l10n.errorPermissionDenied,
      ProfileFailureKind.networkUnavailable => l10n.errorNetworkUnavailable,
      ProfileFailureKind.unknown => l10n.errorFirestoreUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560.w),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.profileSetupSheetTitle, style: AppTypography.h3),
              SizedBox(height: AppSpacing.s4.h),
              AppInput(
                label: l10n.profileEditNameLabel,
                controller: _nameCtrl,
                errorText: _nameError,
                // Google pré-remplit le nom → focus directement sur téléphone.
                autofocus: widget.initialDisplayName.isEmpty,
                onChanged: (v) => setState(() => _nameError = _validateName(v)),
              ),
              SizedBox(height: AppSpacing.s4.h),
              Text(
                l10n.profileSetupPhoneLabel,
                style: AppTypography.meta.copyWith(color: AppColors.inkSoft),
              ),
              SizedBox(height: AppSpacing.s2.h),
              PhoneInputWithCountryFlag(
                value: _phone,
                errorText: _phoneError,
                autofocus: widget.initialDisplayName.isNotEmpty,
                onChanged: (v) => setState(() {
                  _phone = v;
                  _phoneError = _validatePhone(v);
                }),
              ),
              SizedBox(height: AppSpacing.s5.h),
              AppButton.primary(
                label: _loading ? l10n.sendingLabel : l10n.saveLabel,
                onPressed: _loading ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
