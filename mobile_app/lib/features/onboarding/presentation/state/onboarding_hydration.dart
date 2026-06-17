import '../../../../core/logging/app_logger.dart';
import '../../domain/sub_system.dart';
import 'onboarding_state.dart';

/// Extrait depuis un doc Firestore users/{uid} l'état d'onboarding et le
/// sous-système détecté. Séparé de OnboardingNotifier pour pouvoir être testé
/// sans Riverpod et sans `ref`.
({OnboardingState state, SubSystem? subSystem}) parseOnboardingDoc(
  Map<String, dynamic> data, {
  String? oauthDisplayName,
}) {
  SubSystem? sub;
  final rawSub = data['subSystem'] as String?;
  if (rawSub != null) {
    try {
      sub = SubSystem.values.firstWhere((s) => s.id == rawSub);
    } catch (_) {}
  }

  // Bug 6 fix : lecture des champs en anglais + fallback legacy francais
  // (filiere/niveau/serie) pour les docs crees par Epic 1 avant la migration.
  final trackId = (data['trackId'] ?? data['filiere']) as String?;
  final levelId = (data['levelId'] ?? data['niveau']) as String?;
  final streamId = (data['streamId'] ?? data['serie']) as String?;

  // Bug 11 fix : subSystem absent du doc (docs anciens) mais profil complet.
  // On derive francophone par defaut pour debloquer le router.
  if (sub == null && trackId != null) {
    AppLogger.w(
      'parseOnboardingDoc: subSystem absent du doc -> fallback francophone',
    );
    sub = SubSystem.francophone;
  }

  final rawP = data['pickedSubjects'];
  final picked = rawP is List
      ? List<String>.unmodifiable(rawP.whereType<String>().toList())
      : const <String>[];
  final fsName = data['displayName'] as String?;
  final name = (fsName?.isNotEmpty == true) ? fsName : oauthDisplayName;
  final schoolId = data['schoolId'] as String?;
  final step = trackId == null
      ? 2
      : levelId == null
          ? 3
          : picked.isEmpty
              ? 4
              : (name?.isEmpty ?? true)
                  ? 6
                  : (schoolId == null ? 8 : 9);

  // Bug 3 fix : lire authProvider depuis Firestore plutot que hardcoder google.
  final authProvider =
      OnboardingAuthProvider.fromString(data['authProvider'] as String?) ??
          OnboardingAuthProvider.google;

  AppLogger.i(
    'parseOnboardingDoc step=$step trackId=$trackId levelId=$levelId '
    'subjects=${picked.length} schoolId=${schoolId ?? "<null>"} '
    'authProvider=${authProvider.id}',
  );

  return (
    state: OnboardingState(
      currentStep: step,
      subSystem: sub,
      trackId: trackId,
      levelId: levelId,
      levelRequiresPicker: streamId != null || picked.isNotEmpty,
      streamId: streamId,
      pickedSubjects: picked,
      userDisplayName: name,
      schoolId: schoolId,
      schoolName: data['schoolName'] as String?,
      authProvider: authProvider,
    ),
    subSystem: sub,
  );
}
