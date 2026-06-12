// Story E1bis-7 — Step body 9 du shell onboarding refonte.
//
// SUCCESS CELEBRATION. Au render, declenche le flush Firestore via
// OnboardingFlushService. Si succes, affiche CelebrationConfettiSuccess
// + auto-dispatch vers /dashboard. Si echec, affiche ErrorRetryView.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/feedback/celebration_confetti_success.dart';
import '../../../../core/widgets/feedback/error_retry_view.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../providers.dart';
import '../state/onboarding_providers.dart';

class SuccessCelebrationStepBody extends ConsumerStatefulWidget {
  const SuccessCelebrationStepBody({super.key});

  @override
  ConsumerState<SuccessCelebrationStepBody> createState() =>
      _SuccessCelebrationStepBodyState();
}

class _SuccessCelebrationStepBodyState
    extends ConsumerState<SuccessCelebrationStepBody> {
  bool _flushed = false;
  bool _flushing = false;
  String? _flushError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlush());
  }

  Future<void> _runFlush() async {
    if (_flushing || _flushed) return;
    setState(() {
      _flushing = true;
      _flushError = null;
    });
    final state = ref.read(onboardingNotifierProvider);
    final service = ref.read(onboardingFlushServiceProvider);
    final result = await service.flush(state);
    if (!mounted) return;
    result.fold(
      (failure) {
        AppLogger.w('flush failed code=${failure.code}');
        setState(() {
          _flushing = false;
          _flushError = failure.message;
        });
      },
      (_) {
        AppLogger.i('flush success');
        setState(() {
          _flushing = false;
          _flushed = true;
        });
      },
    );
  }

  void _onComplete() {
    if (!mounted) return;
    AppLogger.i('success.onComplete -> /dashboard');
    GoRouter.of(context).go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_flushError != null) {
      return ErrorRetryView(
        onRetry: _runFlush,
        kind: ErrorRetryKind.generic,
        message: l10n.onboardingFlushError,
      );
    }
    if (_flushing || !_flushed) {
      return const Center(child: CircularProgressIndicator());
    }
    return CelebrationConfettiSuccess(
      title: l10n.onboardingSuccessTitle,
      subtitle: l10n.onboardingSuccessSubtitle,
      ctaLabel: l10n.onboardingSuccessCta,
      onComplete: _onComplete,
    );
  }
}
