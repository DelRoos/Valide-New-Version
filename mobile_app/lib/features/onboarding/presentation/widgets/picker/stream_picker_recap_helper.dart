import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/catalogue/domain/models.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/sub_system.dart';
import '../../state/onboarding_state.dart';

/// Construit les entrees a afficher dans le recap header du step 4 :
/// Section -> Filiere -> Niveau -> Serie -> Examen vise.
/// Resout les IDs vers leur nom localise via le snapshot catalogue + le
/// profile derive (pour examTargets).
List<({String label, String value, IconData icon})> buildRecapEntries(
  CatalogueSnapshot snapshot,
  OnboardingState state,
  DerivedProfile profile,
  String langKey,
  AppLocalizations l10n,
) {
  final entries = <({String label, String value, IconData icon})>[];
  final subSystem = state.subSystem;
  if (subSystem != null) {
    entries.add((
      label: l10n.onboardingRecapLabelSection,
      value: subSystem == SubSystem.francophone
          ? l10n.subsystemFrancophone
          : l10n.subsystemAnglophone,
      icon: LucideIcons.globe,
    ));
  }
  final trackId = state.trackId;
  if (trackId != null) {
    final f = snapshot.filieres.where((f) => f.filiereId == trackId);
    if (f.isNotEmpty) {
      entries.add((
        label: l10n.onboardingRecapLabelTrack,
        value: f.first.name[langKey] ?? f.first.name.values.first,
        icon: LucideIcons.layers,
      ));
    }
  }
  final levelId = state.levelId;
  if (levelId != null) {
    final n = snapshot.niveaux.where((n) => n.niveauId == levelId);
    if (n.isNotEmpty) {
      entries.add((
        label: l10n.onboardingRecapLabelLevel,
        value: n.first.name[langKey] ?? n.first.name.values.first,
        icon: LucideIcons.graduationCap,
      ));
    }
  }
  final streamId = state.streamId;
  if (streamId != null) {
    final s = snapshot.series.where((s) => s.serieId == streamId);
    if (s.isNotEmpty) {
      entries.add((
        label: l10n.onboardingRecapLabelStream,
        value: s.first.name[langKey] ?? s.first.name.values.first,
        icon: LucideIcons.bookmark,
      ));
    }
  }
  // Ajout de l'examen vise au recap (BAC D, BEPC, Probatoire G1...).
  // Plusieurs examens possibles par niveau ; on joint avec ' / ' si multiple.
  final activeExams = profile.examTargets
      .where((e) => e.isActive)
      .map((e) => e.name[langKey] ?? e.name.values.first)
      .toList(growable: false);
  if (activeExams.isNotEmpty) {
    entries.add((
      label: l10n.onboardingRecapLabelExam,
      value: activeExams.join(' / '),
      icon: LucideIcons.award,
    ));
  }
  return entries;
}
