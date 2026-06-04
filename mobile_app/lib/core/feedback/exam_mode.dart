import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub du provider Mode Examen — sera implémenté en Epic 6 (Mode 3, Examen).
/// Story 0.14 dépend du signal pour couper les feedbacks haptic/audio,
/// mais l'état réel n'est calculé qu'en E6. En attendant : toujours `false`.
class ExamModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setActive(bool active) => state = active;
}

final examModeProvider = NotifierProvider<ExamModeNotifier, bool>(
  ExamModeNotifier.new,
);
