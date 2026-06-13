// Story E1bis-1 — State machine onboarding refonte 10 etapes.
//
// Notifier Riverpod pur cote logique de transition, MAIS injecte un wrapper
// SharedPreferences (Audit 2026-06-13 PR1) pour persister le draft entre kill
// app et relaunch. Pas de Firebase / Firestore directement — l'ecriture finale
// se fait via OnboardingFlushService au step 9 (ou step 5 visiteur).
//
// Transitions next()/back() :
// - step 3 -> 4 si levelRequiresPicker, sinon -> 5 (skip mode `derived`)
// - step 5 -> 9 si visiteur (skip nom + telephone + ecole + success)
//           -> 6 (audit PR3 : toujours, OAuth pre-rempli + editable)
// - step 7 -> 8 (compte permanent) — visiteur n'arrive jamais ici
// - back() symetrique
//
// CLAUDE.md regle 4 securite : phoneNumber ne doit JAMAIS etre logue
// complet — utiliser maskPhone() (lib/core/logging/log_safe.dart).
// phoneNumber n'est PAS persiste en SharedPrefs (PII).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sub_system.dart';
import '../../providers.dart'
    show
        onboardingDraftPrefsProvider,
        subSystemNotifierProvider,
        subsystemPrefsProvider;
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
  /// Audit BUG-LANG-01 2026-06-13 — propage AUSSI le sub-system au
  /// `subSystemNotifierProvider` (legacy Story 1.2) qui pilote la locale
  /// globale via le `LocaleNotifier`. Avant ce fix, le notifier d'onboarding
  /// ecrivait en SharedPrefs mais ne mettait pas a jour le state Riverpod
  /// du sub-system -> les Steps 1-5 restaient en FR meme apres choix
  /// Anglophone. Seul le dashboard final etait en EN (relu depuis SharedPrefs
  /// au build du LocaleNotifier).
  ///
  /// Si l'ecriture SharedPreferences echoue (rarissime), l'exception remonte
  /// — la page consommatrice gere le toast erreur.
  Future<void> setSubSystem(SubSystem subSystem) async {
    await ref.read(subSystemNotifierProvider.notifier).set(subSystem);
    state = state.copyWith(subSystem: subSystem, currentStep: 1);
    await _persistDraft();
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
    _persistDraftFireAndForget();
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
    _persistDraftFireAndForget();
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
    _persistDraftFireAndForget();
  }

  /// Pose le streamId SANS transitionner. Utilise par
  /// StreamSubjectsPickerStepBody quand l'utilisateur choisit une serie
  /// d'abord, pour declencher la re-derivation via `derivedProfileV2Provider`
  /// (qui watch state). Le passage a l'etape 5 se fera via
  /// `setStreamAndSubjects` une fois les matieres validees.
  void setStreamIdDraft(String streamId) {
    state = state.copyWith(streamId: streamId);
    _persistDraftFireAndForget();
  }

  /// Pose le provider d'auth + capture le displayName eventuel.
  ///
  /// Transition conditionnelle :
  /// - visiteur (`OnboardingAuthProvider.guest`) -> NE TRANSITIONNE PAS :
  ///   le mode visiteur n'a ni nom, ni telephone, ni ecole, ni page success.
  ///   AuthChoiceStepBody fait directement le flush Firestore + nav vers
  ///   `/dashboard` (decision produit 2026-06-13 : "Mode visiteur il part
  ///   directement sur le dashboard", pas de celebration).
  /// - displayName non vide -> step 6 (pré-rempli) — l'utilisateur peut
  ///   modifier le nom OAuth avant de valider. Cf. audit 2026-06-13 (PR3) :
  ///   skip systematique step 6 supprimait l'edition.
  /// - displayName vide/null -> step 6 (saisie clavier requise).
  void setAuthProvider(
    OnboardingAuthProvider provider, {
    String? displayName,
  }) {
    final isVisitor = provider == OnboardingAuthProvider.guest;
    state = state.copyWith(
      authProvider: provider,
      userDisplayName: displayName,
      isVisitor: isVisitor,
      // Visiteur reste a step 5 — AuthChoiceStepBody fait le flush + nav.
      // Compte permanent : toujours step 6 (pre-rempli OAuth ou vide).
      currentStep: isVisitor ? state.currentStep : 6,
    );
    _persistDraftFireAndForget();
  }

  /// Pose le displayName (saisi clavier au step 6). Transition step 6 -> 7.
  void setUserDisplayName(String displayName) {
    state = state.copyWith(
      userDisplayName: displayName,
      currentStep: 7,
    );
    _persistDraftFireAndForget();
  }

  /// Pose le draft du displayName SANS transitionner. Utilise par
  /// NameInputStepBody pour synchroniser le draft avec l'etat (le shell
  /// footer lit `state.userDisplayName` pour activer le CTA Continuer).
  /// `null` reset le draft.
  void setUserDisplayNameDraft(String? draft) {
    state = state.copyWith(userDisplayName: draft);
    // Pas de persist intermediaire pendant la frappe — overhead disque
    // inutile, le commit final via setUserDisplayName declenche le write.
  }

  /// Pose le draft du numero E.164 SANS transitionner. Utilise par
  /// PhoneInputStepBody pour synchroniser le draft avec l'etat.
  void setPhoneNumberDraft(String? draft) {
    state = state.copyWith(
      phoneNumber: draft,
      phoneSkipped: false,
    );
    // phoneNumber n'est PAS persiste (PII) — pas de write disque ici.
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
    _persistDraftFireAndForget();
  }

  /// L'utilisateur tape "Passer pour l'instant" au step 7. Transition
  /// identique a [setPhoneNumber] : skip step 8 si visiteur.
  void skipPhone() {
    state = state.copyWith(
      phoneNumber: null,
      phoneSkipped: true,
      currentStep: state.isVisitor ? 9 : 8,
    );
    _persistDraftFireAndForget();
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
    _persistDraftFireAndForget();
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
    _persistDraftFireAndForget();
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
    _persistDraftFireAndForget();
  }

  /// Avance d'un cran en consultant l'etat actuel pour les branches
  /// conditionnelles :
  /// - skip step 4 si !levelRequiresPicker
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
      5 => 6,
      6 => 7,
      7 => 8,
      8 => 9,
      9 => 9,
      _ => s.currentStep,
    };
    if (target != s.currentStep) {
      state = s.copyWith(currentStep: target);
      _persistDraftFireAndForget();
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
      7 => 6,
      8 => 7,
      9 => 8,
      _ => s.currentStep,
    };
    if (target != s.currentStep) {
      state = s.copyWith(currentStep: target);
      _persistDraftFireAndForget();
    }
  }

  /// Restaure le `subSystem` + le draft complet depuis SharedPreferences.
  ///
  /// Audit 2026-06-13 (PR1) — Avant ce PR, seul `subSystem` etait restaure.
  /// Maintenant tout le draft (trackId/levelId/streamId/pickedSubjects/
  /// currentStep/userDisplayName/school*) est restaure pour que l'utilisateur
  /// reprenne exactement la ou il etait avant le kill app.
  ///
  /// phoneNumber n'est PAS persiste (PII regle 4 CLAUDE.md) — au retour, le
  /// step 7 demandera de re-saisir si non skip.
  ///
  /// Appelee explicitement par le wrapper page OnboardingShell au
  /// `initState` (pas dans `build()` pour preserver le determinisme synchrone
  /// du Notifier).
  Future<void> loadFromPersistence() async {
    final persistedSubSystem = ref.read(subsystemPrefsProvider).read();
    final draft = ref.read(onboardingDraftPrefsProvider).read();

    if (persistedSubSystem == null && draft == null) {
      return;
    }

    // Si pas de draft mais subSystem persiste : ancien comportement (user a
    // choisi subSystem au step 0 puis kill avant tout autre choix).
    if (draft == null) {
      state = state.copyWith(
        subSystem: persistedSubSystem,
        currentStep: 1,
      );
      return;
    }

    state = OnboardingState(
      currentStep: draft.currentStep,
      subSystem: persistedSubSystem,
      trackId: draft.trackId,
      levelId: draft.levelId,
      levelRequiresPicker: draft.levelRequiresPicker,
      streamId: draft.streamId,
      pickedSubjects: List<String>.unmodifiable(draft.pickedSubjects),
      userDisplayName: draft.userDisplayName,
      // phoneNumber non restaure (PII).
      phoneSkipped: draft.phoneSkipped,
      schoolId: draft.schoolId,
      schoolName: draft.schoolName,
      pendingSchoolRequestId: draft.pendingSchoolRequestId,
      schoolSkipped: draft.schoolSkipped,
      isVisitor: draft.isVisitor,
      authProvider: draft.authProvider,
    );
  }

  /// Reset complet en memoire + efface le draft persiste. Utile en tests +
  /// post-deconnexion (Story E1bis-9). Ne touche PAS `subSystem` persiste —
  /// le caller (dev_audit_service / signOut handler) decide separement.
  void reset() {
    state = const OnboardingState();
    _clearDraftFireAndForget();
  }

  /// Efface le draft persiste. Appele par OnboardingFlushService apres un
  /// flush success — a ce moment-la, le doc users/{uid} est la source de
  /// verite, plus besoin de garder le draft.
  Future<void> clearPersistedDraft() async {
    await ref.read(onboardingDraftPrefsProvider).clear();
  }

  Future<void> _persistDraft() {
    return ref.read(onboardingDraftPrefsProvider).write(state);
  }

  /// Variante fire-and-forget pour les setters synchrones qui ne veulent
  /// pas attendre le write disque (UI fluide). L'echec est swallow — la
  /// persistance est best-effort.
  void _persistDraftFireAndForget() {
    unawaited(_persistDraft());
  }

  void _clearDraftFireAndForget() {
    unawaited(ref.read(onboardingDraftPrefsProvider).clear());
  }
}
