// Story E1bis-1 — Provider Riverpod de la state machine onboarding refonte.
//
// Expose une seule provider racine consommee par les pages E1bis-2 a E1bis-7
// + le wrapper `OnboardingShell` (E1bis-2). Pas de provider derive supplementaire
// dans cette story — les pages calculent leurs derivees localement via
// `ref.watch(onboardingNotifierProvider)`.
//
// Cohabite avec `onboardingFlowProvider` legacy Epic 1
// (lib/features/onboarding/providers.dart) jusqu'a la depreciation E1bis-9.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_notifier.dart';
import 'onboarding_state.dart';

/// Provider racine de la state machine onboarding refonte (Epic E1bis).
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
