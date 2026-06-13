// Audit 2026-06-13 (PR1) — Wrapper SharedPreferences pour persister le draft
// du flow onboarding refonte E1bis (cle `onboarding.draft`).
//
// Pourquoi : avant ce PR, `OnboardingNotifier.loadFromPersistence` ne
// restaurait que `subSystem`. Un kill app entre step 2 (track) et step 5
// (auth) faisait perdre trackId/levelId/streamId/pickedSubjects/currentStep
// — l'utilisateur revenait au step 1 obligé de tout recommencer.
//
// Ce qui est persiste : currentStep + trackId + levelId + levelRequiresPicker
// + streamId + pickedSubjects + userDisplayName + schoolId + schoolName +
// pendingSchoolRequestId + schoolSkipped + phoneSkipped + isVisitor +
// authProvider.
//
// Ce qui N'EST PAS persiste : phoneNumber (CLAUDE.md regle 4 securite —
// donnees personnelles sensibles, jamais sur disque persistant accessible
// root Android). subSystem reste persiste via SubsystemPrefs existant.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/state/onboarding_state.dart';

class OnboardingDraftPrefs {
  OnboardingDraftPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const String _kDraftKey = 'onboarding.draft';

  /// Persiste le draft du flow. Idempotent. Echec silencieux (log via
  /// caller si necessaire) — la persistance est une optimisation, pas une
  /// invariant : si elle echoue, le user repasse step 0 au pire.
  Future<void> write(OnboardingState state) async {
    final map = <String, dynamic>{
      'currentStep': state.currentStep,
      'trackId': state.trackId,
      'levelId': state.levelId,
      'levelRequiresPicker': state.levelRequiresPicker,
      'streamId': state.streamId,
      'pickedSubjects': state.pickedSubjects,
      'userDisplayName': state.userDisplayName,
      'schoolId': state.schoolId,
      'schoolName': state.schoolName,
      'pendingSchoolRequestId': state.pendingSchoolRequestId,
      'schoolSkipped': state.schoolSkipped,
      'phoneSkipped': state.phoneSkipped,
      'isVisitor': state.isVisitor,
      'authProvider': state.authProvider?.id,
    };
    await _prefs.setString(_kDraftKey, jsonEncode(map));
  }

  /// Lit le draft persiste. Retourne `null` au 1er lancement ou si le draft
  /// a ete clearé (post-flush success). Tolerant aux champs manquants
  /// (forward-compat : un futur ajout de champ ne casse pas la restauration).
  /// Le `subSystem` est lu separement via SubsystemPrefs et compose dans
  /// OnboardingNotifier.loadFromPersistence.
  OnboardingDraftSnapshot? read() {
    final raw = _prefs.getString(_kDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OnboardingDraftSnapshot(
        currentStep: (map['currentStep'] as int?) ?? 0,
        trackId: map['trackId'] as String?,
        levelId: map['levelId'] as String?,
        levelRequiresPicker:
            (map['levelRequiresPicker'] as bool?) ?? false,
        streamId: map['streamId'] as String?,
        pickedSubjects: (map['pickedSubjects'] as List?)?.cast<String>() ??
            const <String>[],
        userDisplayName: map['userDisplayName'] as String?,
        schoolId: map['schoolId'] as String?,
        schoolName: map['schoolName'] as String?,
        pendingSchoolRequestId: map['pendingSchoolRequestId'] as String?,
        schoolSkipped: (map['schoolSkipped'] as bool?) ?? false,
        phoneSkipped: (map['phoneSkipped'] as bool?) ?? false,
        isVisitor: (map['isVisitor'] as bool?) ?? false,
        authProvider: OnboardingAuthProvider.fromString(
          map['authProvider'] as String?,
        ),
      );
    } catch (_) {
      // Draft corrompu (JSON invalide ou schema obsolete) — on ignore et
      // on repart fresh. Pas de throw.
      return null;
    }
  }

  /// Efface le draft. Appele apres flush success OU au signOut (le caller
  /// decide). Idempotent.
  Future<void> clear() => _prefs.remove(_kDraftKey);
}

/// Snapshot des champs persistes (subSystem exclu — lu separement par
/// SubsystemPrefs). Composé dans OnboardingNotifier.loadFromPersistence pour
/// reconstituer un OnboardingState complet.
class OnboardingDraftSnapshot {
  const OnboardingDraftSnapshot({
    required this.currentStep,
    required this.trackId,
    required this.levelId,
    required this.levelRequiresPicker,
    required this.streamId,
    required this.pickedSubjects,
    required this.userDisplayName,
    required this.schoolId,
    required this.schoolName,
    required this.pendingSchoolRequestId,
    required this.schoolSkipped,
    required this.phoneSkipped,
    required this.isVisitor,
    required this.authProvider,
  });

  final int currentStep;
  final String? trackId;
  final String? levelId;
  final bool levelRequiresPicker;
  final String? streamId;
  final List<String> pickedSubjects;
  final String? userDisplayName;
  final String? schoolId;
  final String? schoolName;
  final String? pendingSchoolRequestId;
  final bool schoolSkipped;
  final bool phoneSkipped;
  final bool isVisitor;
  final OnboardingAuthProvider? authProvider;
}
