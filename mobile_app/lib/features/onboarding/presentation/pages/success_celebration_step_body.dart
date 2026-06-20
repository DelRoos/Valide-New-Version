// Story E1bis-7 — Step body 9 du shell onboarding refonte.
//
// SUCCESS CELEBRATION. Au render, declenche le flush Firestore via
// OnboardingFlushService avec retry exponentiel (audit PR3 2026-06-13).
// Si succes, affiche un dialog expliquant les benefices du compte cree,
// puis auto-dispatch vers /dashboard. Si echec apres N retries, affiche
// ErrorRetryView avec le code Firestore (diagnostic).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../providers.dart'
    show
        onboardingFlushServiceProvider,
        profileUpgradeInProgressProvider;
import '../state/onboarding_providers.dart';

class SuccessCelebrationStepBody extends ConsumerStatefulWidget {
  const SuccessCelebrationStepBody({super.key});

  @override
  ConsumerState<SuccessCelebrationStepBody> createState() =>
      _SuccessCelebrationStepBodyState();
}

class _SuccessCelebrationStepBodyState
    extends ConsumerState<SuccessCelebrationStepBody> {
  static const int _maxAutoRetries = 3;
  static const List<Duration> _backoffDelays = [
    Duration.zero,
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];

  bool _flushed = false;
  bool _flushing = false;
  String? _flushError;
  String? _lastFailureCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlushCycle());
  }

  Future<void> _runFlushCycle() async {
    if (_flushing || _flushed) return;
    setState(() {
      _flushing = true;
      _flushError = null;
      _lastFailureCode = null;
    });

    for (var attempt = 0; attempt < _maxAutoRetries; attempt++) {
      if (!mounted) return;
      if (_backoffDelays[attempt] != Duration.zero) {
        AppLogger.i(
          'flush retry attempt=${attempt + 1}/$_maxAutoRetries '
          'after ${_backoffDelays[attempt].inSeconds}s backoff',
        );
        await Future<void>.delayed(_backoffDelays[attempt]);
        if (!mounted) return;
      }

      final state = ref.read(onboardingNotifierProvider);
      final service = ref.read(onboardingFlushServiceProvider);
      final result = await service.flush(state);
      if (!mounted) return;

      final success = result.fold(
        (failure) {
          AppLogger.w(
            'flush attempt=${attempt + 1} failed code=${failure.code}',
          );
          _lastFailureCode = failure.code;
          return false;
        },
        (_) => true,
      );
      if (success) {
        AppLogger.i('flush success on attempt=${attempt + 1}');
        if (!mounted) return;
        setState(() {
          _flushing = false;
          _flushed = true;
        });
        await _showWelcomeDialog();
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _flushing = false;
      _flushError = _lastFailureCode ?? 'unknown';
    });
  }

  Future<void> _showWelcomeDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WelcomeBenefitsDialog(
        onContinue: () {
          Navigator.of(ctx).pop();
          _onComplete();
        },
      ),
    );
  }

  void _onComplete() {
    if (!mounted) return;
    AppLogger.i('success.onComplete -> /dashboard');
    ref.read(profileUpgradeInProgressProvider.notifier).setInProgress(false);
    GoRouter.of(context).go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_flushError != null) {
      return ErrorRetryView(
        onRetry: _runFlushCycle,
        kind: _errorKindFromCode(_flushError),
        message: _errorMessageFor(l10n, _flushError),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  String _errorMessageFor(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'permission-denied':
      case 'unauthenticated':
        return l10n.errorPermissionDenied;
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return l10n.errorNetworkUnavailable;
      default:
        return l10n.onboardingFlushError;
    }
  }

  ErrorRetryKind _errorKindFromCode(String? code) {
    switch (code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return ErrorRetryKind.offline;
      default:
        return ErrorRetryKind.generic;
    }
  }
}

class _WelcomeBenefitsDialog extends StatelessWidget {
  const _WelcomeBenefitsDialog({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl2),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.sp,
              height: 64.sp,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.circleCheck,
                color: AppColors.success,
                size: 36.sp,
              ),
            ),
            SizedBox(height: AppSpacing.s4.h),
            Text(
              l10n.onboardingSuccessDialogTitle,
              style: AppTypography.h2.copyWith(fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s2.h),
            Text(
              l10n.onboardingSuccessDialogSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s4.h),
            _BenefitRow(
              icon: LucideIcons.trendingUp,
              label: l10n.onboardingSuccessBenefit1,
            ),
            SizedBox(height: AppSpacing.s3.h),
            _BenefitRow(
              icon: LucideIcons.trophy,
              label: l10n.onboardingSuccessBenefit2,
            ),
            SizedBox(height: AppSpacing.s3.h),
            _BenefitRow(
              icon: LucideIcons.bookOpen,
              label: l10n.onboardingSuccessBenefit3,
            ),
            SizedBox(height: AppSpacing.s5.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
                child: Text(
                  l10n.onboardingSuccessDialogCta,
                  style: AppTypography.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.sp,
          height: 36.sp,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18.sp),
        ),
        SizedBox(width: AppSpacing.s3.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              label,
              style: AppTypography.body.copyWith(fontSize: 14.sp),
            ),
          ),
        ),
      ],
    );
  }
}
