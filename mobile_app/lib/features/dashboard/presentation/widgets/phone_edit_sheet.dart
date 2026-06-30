import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/forms/phone_input_with_country_flag.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/profile_failure.dart';
import '../../../onboarding/providers.dart';

class PhoneEditSheet extends ConsumerStatefulWidget {
  const PhoneEditSheet({super.key, required this.initialPhoneNumber});

  final String? initialPhoneNumber;

  static Future<void> show(
    BuildContext context, {
    required String? phoneNumber,
  }) {
    return AppBottomSheet.show<void>(
      context,
      child: PhoneEditSheet(initialPhoneNumber: phoneNumber),
    );
  }

  @override
  ConsumerState<PhoneEditSheet> createState() => _PhoneEditSheetState();
}

class _PhoneEditSheetState extends ConsumerState<PhoneEditSheet> {
  late String _phone;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _phone = widget.initialPhoneNumber ?? '';
  }

  String? _validate(String phone) {
    if (phone.isEmpty) return null;
    final valid = RegExp(r'^\+237[26][0-9]{8}$');
    if (!valid.hasMatch(phone)) {
      return AppLocalizations.of(context).onboardingPhoneInvalid;
    }
    return null;
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context);
    final error = _validate(_phone);
    setState(() {
      _error = error;
      _loading = error == null;
    });
    if (error != null) return;

    final result = await ref
        .read(userProfileRepositoryProvider)
        .updatePhoneNumber(_phone.isEmpty ? null : _phone);

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (f) {
        final message = switch (f.kind) {
          ProfileFailureKind.permissionDenied ||
          ProfileFailureKind.notAuthenticated =>
            l10n.errorPermissionDenied,
          ProfileFailureKind.networkUnavailable => l10n.errorNetworkUnavailable,
          ProfileFailureKind.unknown => l10n.errorFirestoreUnknown,
        };
        AppToast.show(context, message: message, tone: ToastTone.error);
      },
      (_) {
        AppToast.show(context, message: l10n.profileEditSuccess);
        Navigator.of(context).pop();
      },
    );
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
            Text(l10n.profileMenuPhone, style: AppTypography.h3),
            SizedBox(height: AppSpacing.s4.h),
            PhoneInputWithCountryFlag(
              value: _phone,
              errorText: _error,
              autofocus: true,
              onChanged: (v) => setState(() {
                _phone = v;
                _error = _validate(v);
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
    );
  }
}
