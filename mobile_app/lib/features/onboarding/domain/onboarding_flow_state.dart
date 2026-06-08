// Story 1.3 — State machine du flow profil scolaire 3 etapes.
//
// L'utilisateur progresse Filiere → Niveau → Serie → Recap. Chaque etape
// pose un id (ref Firestore catalogue). La selection d'une etape amont
// reset les choix aval (eviter incoherences). Le `currentStep` est derive
// des champs nullables.
//
// Domain pur : aucune dependance Flutter/Firebase. equatable pour comparaison
// dans les tests + Riverpod.

import 'package:equatable/equatable.dart';

enum OnboardingFlowStep { filiere, niveau, serie, recap }

class OnboardingFlowState extends Equatable {
  const OnboardingFlowState({
    this.filiereId,
    this.niveauId,
    this.serieId,
  });

  /// Ref vers `filieres/{id}` Firestore (ex. `generale`, `technique`).
  final String? filiereId;

  /// Ref vers `niveaux/{id}` Firestore (ex. `francophone_terminale`).
  final String? niveauId;

  /// Ref vers `series/{id}` Firestore (ex. `francophone_terminale_d`).
  /// Peut etre `null` si le niveau n'a pas de serie (6e francophone, Form 1
  /// anglophone). Story 1.3 AC3 : serie skip si pas de serie applicable.
  final String? serieId;

  /// Etape courante derivee des champs poses.
  /// - Aucune filiere : OnboardingFlowStep.filiere
  /// - Filiere posee, pas de niveau : OnboardingFlowStep.niveau
  /// - Niveau pose, pas de serie : OnboardingFlowStep.serie
  /// - Tout pose (ou serie skip explicite) : OnboardingFlowStep.recap
  ///
  /// Note : on ne peut pas distinguer ici "serie pas encore choisie" et
  /// "serie skip explicite (=null)" — c'est au caller (NiveauChoicePage)
  /// de naviguer directement vers recap si pas de serie applicable.
  OnboardingFlowStep get currentStep {
    if (filiereId == null) return OnboardingFlowStep.filiere;
    if (niveauId == null) return OnboardingFlowStep.niveau;
    return OnboardingFlowStep.recap;
  }

  /// Profil minimal pour pouvoir creer le doc users/{uid} Firestore (AC6).
  /// `serieId` peut etre null (niveau sans serie → '-' en Firestore).
  bool get isComplete => filiereId != null && niveauId != null;

  OnboardingFlowState copyWith({
    String? filiereId,
    String? niveauId,
    String? serieId,
  }) {
    return OnboardingFlowState(
      filiereId: filiereId ?? this.filiereId,
      niveauId: niveauId ?? this.niveauId,
      serieId: serieId ?? this.serieId,
    );
  }

  /// Reset les champs APRES `step` (inclus). Permet a `backTo(filiere)` de
  /// repartir d'une feuille propre tout en preservant le subSystem (lui
  /// vit dans subSystemNotifierProvider, hors de cette state machine).
  OnboardingFlowState resetFrom(OnboardingFlowStep step) {
    return switch (step) {
      OnboardingFlowStep.filiere => const OnboardingFlowState(),
      OnboardingFlowStep.niveau =>
        OnboardingFlowState(filiereId: filiereId),
      OnboardingFlowStep.serie => OnboardingFlowState(
          filiereId: filiereId,
          niveauId: niveauId,
        ),
      OnboardingFlowStep.recap => this, // pas de reset (deja a l'arrivee)
    };
  }

  @override
  List<Object?> get props => [filiereId, niveauId, serieId];
}
