import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/forms/phone_input_with_country_flag.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/providers.dart';

/// Bottom sheet d'édition du profil : displayName + téléphone optionnel.
///
/// Ouvert depuis _ProfileHeader via `AppBottomSheet.show`.
/// Appel: ProfileEditSheet.show(context, displayName, phoneNumber)
class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({
    super.key,
    required this.initialDisplayName,
    required this.initialPhoneNumber,
  });

  final String initialDisplayName;
  final String? initialPhoneNumber;

  static Future<void> show(
    BuildContext context, {
    required String displayName,
    required String? phoneNumber,
  }) {
    return AppBottomSheet.show<void>(
      context,
      child: ProfileEditSheet(
        initialDisplayName: displayName,
        initialPhoneNumber: phoneNumber,
      ),
    );
  }

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  late final TextEditingController _nameCtrl;
  late String _phone;

  String? _nameError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDisplayName);
    _phone = widget.initialPhoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String name) {
    if (name.trim().length < 2) {
      return AppLocalizations.of(context).onboardingNameTooShort;
    }
    if (name.trim().length > 50) {
      return AppLocalizations.of(context).onboardingNameTooLong;
    }
    return null;
  }

  String? _validatePhone(String phone) {
    if (phone.isEmpty) return null;
    final valid = RegExp(r'^\+237[26][0-9]{8}$');
    if (!valid.hasMatch(phone)) {
      return AppLocalizations.of(context).onboardingPhoneInvalid;
    }
    return null;
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context);
    final nameError = _validateName(_nameCtrl.text);
    final phoneError = _validatePhone(_phone);
    if (nameError != null || phoneError != null) {
      setState(() => _nameError = nameError);
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(userProfileRepositoryProvider);

    final nameResult = await repo.updateDisplayName(_nameCtrl.text.trim());
    final phoneResult = await repo.updatePhoneNumber(
      _phone.isEmpty ? null : _phone,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    final failed = nameResult.isLeft() || phoneResult.isLeft();
    if (failed) {
      AppToast.show(
        context,
        message: l10n.errorGeneric,
        tone: ToastTone.error,
      );
      return;
    }

    AppToast.show(context, message: l10n.profileEditSuccess);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            Text(l10n.profileEditSheetTitle, style: AppTypography.h3),
            SizedBox(height: AppSpacing.s4.h),
            AppInput(
              label: 'Prénom ou surnom',
              controller: _nameCtrl,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            SizedBox(height: AppSpacing.s4.h),
            PhoneInputWithCountryFlag(
              value: _phone,
              onChanged: (v) => setState(() => _phone = v),
            ),
            SizedBox(height: AppSpacing.s5.h),
            AppButton.primary(
              label: _loading ? l10n.sendingLabel : 'Enregistrer',
              onPressed: _loading ? null : _onSave,
            ),
          ],
        ),
      ),
    );
  }
}
