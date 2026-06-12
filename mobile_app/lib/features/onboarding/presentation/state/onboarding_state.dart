// Story E1bis-1 — State machine onboarding (refonte 10 etapes).
//
// State immutable Equatable consomme par OnboardingNotifier (cf.
// onboarding_notifier.dart). Cohabite avec OnboardingFlowState legacy Epic 1
// jusqu'a la depreciation E1bis-9. Pas de Firebase / Riverpod / Flutter ici
// (CLAUDE.md regle 1 domain pur).
//
// Conventions :
// - currentStep dans [0..9] (10 etapes onboarding refonte). Defaut 0.
// - Tous les champs draft sont nullable / vides au depart. copyWith expose
//   une sentinelle pour distinguer "non fourni" de "fourni null" — pattern
//   existant OnboardingFlowState (Story 1.3).

import 'package:equatable/equatable.dart';

import '../../domain/sub_system.dart';

/// Provider d'authentification choisi au step 5.
///
/// `guest` correspond a Firebase Auth `signInAnonymously()` — l'utilisateur
/// continue sans compte permanent (mode visiteur). `google` / `apple` sont
/// les comptes OAuth permanents.
enum OnboardingAuthProvider {
  google,
  apple,
  guest;

  /// Identifiant string utilise comme champ `users/{uid}.authProvider`
  /// Firestore (ecrit en E1bis-4 via `OnboardingNotifier.toFirestorePayload`).
  String get id => name;

  /// Parse la valeur lue depuis Firestore. Retourne `null` si absent ou
  /// inconnu (forward-compat : un nouveau provider futur ne casse pas le
  /// parse).
  static OnboardingAuthProvider? fromString(String? raw) {
    if (raw == null) return null;
    for (final value in OnboardingAuthProvider.values) {
      if (value.id == raw) return value;
    }
    return null;
  }
}

/// Sentinelle interne pour distinguer "champ non fourni" de "champ fourni a
/// null" dans `copyWith`. Pattern Story 1.3 (`OnboardingFlowState`).
class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

/// Etat immutable de la state machine onboarding refonte E1bis (10 etapes).
///
/// Cohabite avec [OnboardingFlowState] legacy Epic 1 jusqu'a E1bis-9. Pas
/// de import Firebase / Flutter / Riverpod / dart:io ici (CLAUDE.md regle 1).
class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentStep = 0,
    this.subSystem,
    this.trackId,
    this.levelId,
    this.levelRequiresPicker = false,
    this.streamId,
    this.pickedSubjects = const <String>[],
    this.userDisplayName,
    this.phoneNumber,
    this.phoneSkipped = false,
    this.schoolId,
    this.schoolName,
    this.pendingSchoolRequestId,
    this.schoolSkipped = false,
    this.isVisitor = false,
    this.authProvider,
  });

  /// Etape courante dans [0..9]. Defaut 0 (sub-system choice).
  final int currentStep;

  /// Sous-systeme scolaire (FR / EN). Persiste en SharedPreferences cle
  /// `onboarding.subsystem` via [SubsystemPrefs] (Story 1.2).
  final SubSystem? subSystem;

  /// `general` | `technical`. Choisi au step 2.
  final String? trackId;

  /// Id du niveau (cf. `levels/{id}` Firestore catalogue). Choisi au step 3.
  final String? levelId;

  /// Vrai si le niveau choisi necessite un picker stream/subjects (modes
  /// `series_only` / `free_with_obligatory` / `series_plus_optional` /
  /// `tve_picker`). Faux si mode `derived` (skip step 4). Capture par
  /// `setLevelId(requiresPicker:)`.
  final bool levelRequiresPicker;

  /// Id de la serie (D, A1, S2, etc.). Choisi au step 4 si applicable.
  final String? streamId;

  /// Ids des matieres choisies au step 4 (modes free /
  /// series_plus_optional / tve_picker). Vide pour modes derived / series_only.
  final List<String> pickedSubjects;

  /// Nom d'affichage. Defini au step 6 (saisie clavier) OU au step 5 si
  /// OAuth fournit un displayName (Google / Apple) — dans ce cas la
  /// transition saute step 6 (cf. AC6 tableau).
  final String? userDisplayName;

  /// Numero E.164 Cameroun (`+237XXXXXXXXX`). Defini au step 7. JAMAIS
  /// loguer ce champ complet — utiliser `maskPhone()` (lib/core/logging/
  /// log_safe.dart, Story E1bis-0).
  final String? phoneNumber;

  /// Vrai si l'utilisateur a explicitement passe le step 7 ("Passer pour
  /// l'instant"). Mutuellement exclusif avec [phoneNumber] non-null.
  final bool phoneSkipped;

  /// Id de l'ecole choisie au step 8. Null si [schoolSkipped] OU si
  /// [pendingSchoolRequestId] est posee (ecole pas encore au catalogue).
  final String? schoolId;

  /// Nom de l'ecole denormalise pour reprise sans re-fetch Firestore.
  /// Pose meme quand [pendingSchoolRequestId] est posee (nom saisi user).
  final String? schoolName;

  /// Id de la demande d'ajout d'ecole (collection `school_requests`
  /// — E1bis-6). Pose quand l'utilisateur tape `+ Ajouter [saisie]`.
  final String? pendingSchoolRequestId;

  /// Vrai si l'utilisateur a explicitement passe le step 8.
  final bool schoolSkipped;

  /// Vrai pour les comptes Firebase anonymous (mode visiteur). Pose par
  /// `setAuthProvider(OnboardingAuthProvider.guest)`. Influence les
  /// transitions next/back (skip step 8 school — cf. AC6).
  final bool isVisitor;

  /// Provider d'authentification choisi au step 5.
  final OnboardingAuthProvider? authProvider;

  /// `copyWith` avec sentinelle : passer le parametre = remplace ; ne pas
  /// le passer = preserve. Permet de remettre un champ a `null` via
  /// `copyWith(streamId: null)` sans collision avec "non fourni".
  OnboardingState copyWith({
    int? currentStep,
    Object? subSystem = _sentinel,
    Object? trackId = _sentinel,
    Object? levelId = _sentinel,
    bool? levelRequiresPicker,
    Object? streamId = _sentinel,
    List<String>? pickedSubjects,
    Object? userDisplayName = _sentinel,
    Object? phoneNumber = _sentinel,
    bool? phoneSkipped,
    Object? schoolId = _sentinel,
    Object? schoolName = _sentinel,
    Object? pendingSchoolRequestId = _sentinel,
    bool? schoolSkipped,
    bool? isVisitor,
    Object? authProvider = _sentinel,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      subSystem: subSystem is _Sentinel
          ? this.subSystem
          : subSystem as SubSystem?,
      trackId: trackId is _Sentinel ? this.trackId : trackId as String?,
      levelId: levelId is _Sentinel ? this.levelId : levelId as String?,
      levelRequiresPicker: levelRequiresPicker ?? this.levelRequiresPicker,
      streamId: streamId is _Sentinel ? this.streamId : streamId as String?,
      pickedSubjects: pickedSubjects ?? this.pickedSubjects,
      userDisplayName: userDisplayName is _Sentinel
          ? this.userDisplayName
          : userDisplayName as String?,
      phoneNumber: phoneNumber is _Sentinel
          ? this.phoneNumber
          : phoneNumber as String?,
      phoneSkipped: phoneSkipped ?? this.phoneSkipped,
      schoolId: schoolId is _Sentinel ? this.schoolId : schoolId as String?,
      schoolName: schoolName is _Sentinel
          ? this.schoolName
          : schoolName as String?,
      pendingSchoolRequestId: pendingSchoolRequestId is _Sentinel
          ? this.pendingSchoolRequestId
          : pendingSchoolRequestId as String?,
      schoolSkipped: schoolSkipped ?? this.schoolSkipped,
      isVisitor: isVisitor ?? this.isVisitor,
      authProvider: authProvider is _Sentinel
          ? this.authProvider
          : authProvider as OnboardingAuthProvider?,
    );
  }

  /// Payload pour ecriture Firestore via `set(merge: true)`.
  ///
  /// **CHAMPS REQUIS** par les firestore.rules (create) — toujours presents
  /// avec defaults safe meme si l'utilisateur a saute l'etape ou est visiteur :
  ///   - `subSystem` / `language` / `trackId` / `levelId` : obligatoires
  ///     (validation amont au step 0-3, jamais null a l'arrivee step 9).
  ///   - `pickedSubjects` : `[]` si vide (la regle exige `is list`, pas
  ///     `size > 0`).
  ///   - `displayName` : `''` si null (visiteur ou skip OAuth) — la regle
  ///     exige `is string`, pas `size > 0`.
  ///   - `authProvider` / `isAnonymous` : poses au step 5 par
  ///     setAuthProvider().
  ///
  /// **CHAMPS OPTIONNELS** (pas dans les rules create) — ecrits seulement
  /// s'ils ont une valeur, pour ne pas polluer le doc :
  ///   - `streamId` / `phoneNumber` / `schoolId` / `schoolName` /
  ///     `pendingSchoolRequestId`.
  Map<String, dynamic> toFirestorePayload() {
    final payload = <String, dynamic>{};
    if (subSystem != null) payload['subSystem'] = subSystem!.id;
    if (trackId != null) payload['trackId'] = trackId;
    if (levelId != null) payload['levelId'] = levelId;
    if (streamId != null) payload['streamId'] = streamId;
    // Champs requis create — defaults safe ('' / []) si pas remplis.
    payload['pickedSubjects'] = List<String>.unmodifiable(pickedSubjects);
    payload['displayName'] = userDisplayName ?? '';
    if (phoneNumber != null) payload['phoneNumber'] = phoneNumber;
    if (schoolId != null) payload['schoolId'] = schoolId;
    if (schoolName != null) payload['schoolName'] = schoolName;
    if (pendingSchoolRequestId != null) {
      payload['pendingSchoolRequestId'] = pendingSchoolRequestId;
    }
    if (authProvider != null) payload['authProvider'] = authProvider!.id;
    payload['isAnonymous'] = isVisitor;
    return payload;
  }

  @override
  List<Object?> get props => [
        currentStep,
        subSystem,
        trackId,
        levelId,
        levelRequiresPicker,
        streamId,
        pickedSubjects,
        userDisplayName,
        phoneNumber,
        phoneSkipped,
        schoolId,
        schoolName,
        pendingSchoolRequestId,
        schoolSkipped,
        isVisitor,
        authProvider,
      ];
}
