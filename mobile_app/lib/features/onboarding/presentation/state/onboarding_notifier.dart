// Story E1bis-1 — State machine onboarding refonte 10 etapes.
//
// Notifier Riverpod pur : pas de Firebase / Firestore (les writes arrivent
// E1bis-4 via WriteBatch post-auth), pas de modification router (branchement
// E1bis-2). Persistance SharedPreferences uniquement pour `subSystem` via
// SubsystemPrefs existant (Story 1.2) — pas de wrapper duplicate.
//
// Cohabite avec OnboardingFlowNotifier legacy Epic 1 (depreciation E1bis-9).
//
// Transitions next()/back() :
// - step 3 -> 4 si levelRequiresPicker, sinon -> 5 (skip mode `derived`)
// - step 5 -> 9 si visiteur (skip nom + telephone + ecole)
//           -> 6 si compte permanent sans displayName
//           -> 7 si compte permanent avec displayName OAuth
// - step 7 -> 8 (compte permanent) — visiteur n'arrive jamais ici
// - back() symetrique
//
// CLAUDE.md regle 4 securite : phoneNumber ne doit JAMAIS etre logue
// complet — utiliser maskPhone() (lib/core/logging/log_safe.dart Story
// E1bis-0).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sub_system.dart';
import '../../providers.dart' show subsystemPrefsProvider;
import 'onboarding_state.dart';

/// State machine onboarding refonte E1bis (10 etapes).
///
/// Pattern : `Notifier<OnboardingState>` Riverpod 3.x. `build()` retourne
/// l'etat initial synchrone — la restauration SharedPreferences est explicite
/// via [loadFromPersistence] (appelee par le wrapper page E1bis-2 au
/// `initState`).
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  /// Pose le sous-systeme + persiste en SharedPreferences. Transition
  /// step 0 -> 1 (hero intro).
  ///
  /// Si l'ecriture SharedPreferences echoue (rarissime), l'exception remonte
  /// — la page consommatrice (E1bis-2) gere le toast erreur.
  Future<void> setSubSystem(SubSystem subSystem) async {
    await ref.read(subsystemPrefsProvider).write(subSystem);
    state = state.copyWith(subSystem: subSystem, currentStep: 1);
  }

  /// Pose le track + reset downstream (level / stream / picked) car un
  /// changement de track invalide les niveaux disponibles. Transition
  /// step 2 -> 3.
  void setTrackId(String trackId) {
    state = state.copyWith(
      trackId: trackId,
      levelId: null,
      levelRequiresPicker: false,
      streamId: null,
      pickedSubjects: const <String>[],
      currentStep: 3,
    );
  }

  /// Pose le level + capture le mode picker + reset stream/subjects.
  /// Transition conditionnelle :
  /// - requiresPicker == true  -> step 4 (picker stream/subjects)
  /// - requiresPicker == false -> step 5 (skip step 4, mode `derived`)
  void setLevelId(String levelId, {required bool requiresPicker}) {
    state = state.copyWith(
      levelId: levelId,
      levelRequiresPicker: requiresPicker,
      streamId: null,
      pickedSubjects: const <String>[],
      currentStep: requiresPicker ? 4 : 5,
    );
  }

  /// Pose le stream (peut etre null pour mode `free_with_obligatory`) +
  /// la liste finale des matieres choisies. Transition step 4 -> 5.
  void setStreamAndSubjects({
    String? streamId,
    required List<String> pickedSubjects,
  }) {
    state = state.copyWith(
      streamId: streamId,
      pickedSubjects: List<String>.unmodifiable(pickedSubjects),
      currentStep: 5,
    );
  }

  /// Pose le streamId SANS transitionner. Utilise par
  /// StreamSubjectsPickerStepBody quand l'utilisateur choisit une serie
  /// d'abord, pour declencher la re-derivation via `derivedProfileV2Provider`
  /// (qui watch state). Le passage a l'etape 5 se fera via
  /// `setStreamAndSubjects` une fois les matieres validees.
  void setStreamIdDraft(String streamId) {
    state = state.copyWith(streamId: streamId);
  }

  /// Pose le provider d'auth + capture le displayName eventuel.
  ///
  /// Transition conditionnelle :
  /// - visiteur (`OnboardingAuthProvider.guest`) -> NE TRANSITIONNE PAS :
  ///   le mode visiteur n'a ni nom, ni telephone, ni ecole, ni page success.
  ///   AuthChoiceStepBody fait directement le flush Firestore + nav vers
  ///   `/dashboard` (decision produit 2026-06-13 : "Mode visiteur il part
  ///   directement sur le dashboard", pas de celebration).
  /// - displayName non vide -> step 7 (skip step 6 name input).
  /// - displayName vide/null -> step 6 (saisie clavier requise).
  void setAuthProvider(
    OnboardingAuthProvider provider, {
    String? displayName,
  }) {
    final hasName = displayName != null && displayName.isNotEmpty;
    final isVisitor = provider == OnboardingAuthProvider.guest;
    state = state.copyWith(
      authProvider: provider,
      userDisplayName: displayName,
      isVisitor: isVisitor,
      // Visiteur reste a step 5 — AuthChoiceStepBody fait le flush + nav.
      currentStep:
          isVisitor ? state.currentStep : (hasName ? 7 : 6),
    );
  }

  /// Pose le displayName (saisi clavier au step 6). Transition step 6 -> 7.
  void setUserDisplayName(String displayName) {
    state = state.copyWith(
      userDisplayName: displayName,
      currentStep: 7,
    );
  }

  /// Pose le draft du displayName SANS transitionner. Utilise par
  /// NameInputStepBody pour synchroniser le draft avec l'etat (le shell
  /// footer lit `state.userDisplayName` pour activer le CTA Continuer).
  /// `null` reset le draft.
  void setUserDisplayNameDraft(String? draft) {
    state = state.copyWith(userDisplayName: draft);
  }

  /// Pose le draft du numero E.164 SANS transitionner. Utilise par
  /// PhoneInputStepBody pour synchroniser le draft avec l'etat.
  void setPhoneNumberDraft(String? draft) {
    state = state.copyWith(
      phoneNumber: draft,
      phoneSkipped: false,
    );
  }

  /// Pose le numero E.164 Cameroun. Transition conditionnelle :
  /// - !isVisitor -> step 8 (school search)
  /// - isVisitor  -> step 9 (skip school, success direct)
  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      phoneSkipped: false,
      currentStep: state.isVisitor ? 9 : 8,
    );
  }

  /// L'utilisateur tape "Passer pour l'instant" au step 7. Transition
  /// identique a [setPhoneNumber] : skip step 8 si visiteur.
  void skipPhone() {
    state = state.copyWith(
      phoneNumber: null,
      phoneSkipped: true,
      currentStep: state.isVisitor ? 9 : 8,
    );
  }

  /// Pose l'ecole choisie au step 8 (suggestions Firestore). Transition
  /// step 8 -> 9.
  void setSchool({required String schoolId, required String schoolName}) {
    state = state.copyWith(
      schoolId: schoolId,
      schoolName: schoolName,
      pendingSchoolRequestId: null,
      schoolSkipped: false,
      currentStep: 9,
    );
  }

  /// L'utilisateur tape `+ Ajouter [saisie]` — pose le pendingRequestId
  /// retourne par la collection `school_requests` (E1bis-6). Transition
  /// step 8 -> 9.
  void setPendingSchoolRequest({
    required String pendingRequestId,
    required String schoolName,
  }) {
    state = state.copyWith(
      schoolId: null,
      schoolName: schoolName,
      pendingSchoolRequestId: pendingRequestId,
      schoolSkipped: false,
      currentStep: 9,
    );
  }

  /// L'utilisateur tape "Passer pour l'instant" au step 8. Transition
  /// step 8 -> 9.
  void skipSchool() {
    state = state.copyWith(
      schoolId: null,
      schoolName: null,
      pendingSchoolRequestId: null,
      schoolSkipped: true,
      currentStep: 9,
    );
  }

  /// Avance d'un cran en consultant l'etat actuel pour les branches
  /// conditionnelles :
  /// - skip step 4 si !levelRequiresPicker
  /// - step 5 -> 7 si OAuth a fourni displayName (skip step 6)
  ///
  /// Le visiteur (`isVisitor=true`) n'utilise pas next() apres le step 5 :
  /// AuthChoiceStepBody navigue directement vers `/dashboard`.
  ///
  /// A step 9 -> no-op.
  void next() {
    final s = state;
    final target = switch (s.currentStep) {
      0 => 1,
      1 => 2,
      2 => 3,
      3 => s.levelRequiresPicker ? 4 : 5,
      4 => 5,
      5 => _hasDisplayName(s) ? 7 : 6,
      6 => 7,
      7 => 8,
      8 => 9,
      9 => 9,
      _ => s.currentStep,
    };
    if (target != s.currentStep) {
      state = s.copyWith(currentStep: target);
    }
  }

  /// Recule d'un cran symetrique a [next]. A step 0 -> no-op.
  ///
  /// Ne reset PAS les valeurs amont : les choix utilisateur sont preserves
  /// pour pre-remplissage UI au retour. C'est [setTrackId] / [setLevelId]
  /// qui font le reset downstream explicite.
  void back() {
    final s = state;
    final target = switch (s.currentStep) {
      0 => 0,
      1 => 0,
      2 => 1,
      3 => 2,
      4 => 3,
      5 => s.levelRequiresPicker ? 4 : 3,
      6 => 5,
      7 => _hasDisplayName(s) ? 5 : 6,
      8 => 7,
      9 => 8,
      _ => s.currentStep,
    };
    if (target != s.currentStep) {
      state = s.copyWith(currentStep: target);
    }
  }

  /// Restaure le `subSystem` depuis SharedPreferences (Story 1.2 cle
  /// `onboarding.subsystem`). Si present -> hydrate + saute au step 1 (hero
  /// intro, l'utilisateur a deja choisi son sub-system avant kill app).
  /// Si absent -> no-op (state reste initial step 0).
  ///
  /// Appelee explicitement par le wrapper page E1bis-2 au `initState` (pas
  /// dans `build()` pour preserver le determinisme synchrone du Notifier).
  Future<void> loadFromPersistence() async {
    final persisted = ref.read(subsystemPrefsProvider).read();
    if (persisted != null) {
      state = state.copyWith(subSystem: persisted, currentStep: 1);
    }
  }

  /// Reset complet en memoire (utile en tests + future deconnexion).
  /// Ne touche PAS SharedPreferences (la deconnexion future decidera).
  void reset() {
    state = const OnboardingState();
  }

  static bool _hasDisplayName(OnboardingState s) {
    final name = s.userDisplayName;
    return name != null && name.isNotEmpty;
  }
}
