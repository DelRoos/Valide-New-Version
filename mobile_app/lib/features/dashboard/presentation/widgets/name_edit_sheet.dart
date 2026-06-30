import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/profile_failure.dart';
import '../../../onboarding/providers.dart';

class NameEditSheet extends ConsumerStatefulWidget {
  const NameEditSheet({super.key, required this.initialDisplayName});

  final String initialDisplayName;

  static Future<void> show(
    BuildContext context, {
    required String displayName,
  }) {
    return AppBottomSheet.show<void>(
      context,
      child: NameEditSheet(initialDisplayName: displayName),
    );
  }

  @override
  ConsumerState<NameEditSheet> createState() => _NameEditSheetState();
}

class _NameEditSheetState extends ConsumerState<NameEditSheet> {
  late final TextEditingController _ctrl;
  String? _error;
  bool _loading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialDisplayName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String name) {
    final l10n = AppLocalizations.of(context);
    if (name.trim().length < 2) return l10n.onboardingNameTooShort;
    if (name.trim().length > 50) return l10n.onboardingNameTooLong;
    return null;
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context);
    final error = _validate(_ctrl.text);
    setState(() {
      _submitted = true;
      _error = error;
      _loading = error == null;
    });
    if (error != null) return;

    final result = await ref
        .read(userProfileRepositoryProvider)
        .updateDisplayName(_ctrl.text.trim());

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
            Text(l10n.profileMenuName, style: AppTypography.h3),
            SizedBox(height: AppSpacing.s4.h),
            AppInput(
              label: l10n.profileEditNameLabel,
              controller: _ctrl,
              errorText: _error,
              autofocus: true,
              onChanged: (v) {
                if (_submitted || _error != null) {
                  setState(() => _error = _validate(v));
                }
              },
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
