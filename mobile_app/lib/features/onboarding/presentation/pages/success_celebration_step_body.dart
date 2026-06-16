// Story E1bis-7 — Step body 9 du shell onboarding refonte.
//
// SUCCESS CELEBRATION. Au render, declenche le flush Firestore via
// OnboardingFlushService avec retry exponentiel (audit PR3 2026-06-13).
// Si succes, affiche CelebrationConfettiSuccess + auto-dispatch vers
// /dashboard. Si echec apres N retries, affiche ErrorRetryView avec
// compteur et le code Firestore (diagnostic).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/feedback/celebration_confetti_success.dart';
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
  /// Audit PR3 — Retry exponentiel : 3 tentatives auto avec delays 0s, 1s,
  /// 3s avant d'afficher ErrorRetryView. Au-dela, le tap "Reessayer" relance
  /// un nouveau cycle de 3 retries.
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

  /// Audit PR3 — Cycle de retry exponentiel automatique. Tente jusqu'a
  /// [_maxAutoRetries] fois avec backoff avant d'exposer l'erreur a l'user.
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
        return;
      }
    }

    // 3 tentatives consommees sans succes -> expose ErrorRetryView.
    if (!mounted) return;
    setState(() {
      _flushing = false;
      _flushError = _lastFailureCode ?? 'unknown';
    });
  }

  void _onComplete() {
    if (!mounted) return;
    AppLogger.i('success.onComplete -> /dashboard');
    // Reset le flag d'upgrade : le router peut de nouveau bouncer
    // /onboarding/v2 -> /dashboard si le profil est complet.
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

  /// Audit PR3 — Mapping code Firestore -> message localise specifique
  /// (CLAUDE.md regle 13). Distingue 3 categories : permission, reseau, autre.
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
