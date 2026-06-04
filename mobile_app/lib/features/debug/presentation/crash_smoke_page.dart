import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';

/// Route debug `/_crash` — Story 0.6 AC5 (Crashlytics smoke).
/// Cette route disparaît à la clôture E0 (Story 0.21).
class CrashSmokePage extends StatelessWidget {
  const CrashSmokePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Crash smoke (debug)')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Story 0.6 AC5 — déclenche une exception captée par Crashlytics. '
                'Visible Console Firebase < 5 min après le crash.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.s6.h),
              AppButton.primary(
                label: 'Crasher l\'app maintenant',
                onPressed: () => throw Exception('E0 sentinel crash test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
