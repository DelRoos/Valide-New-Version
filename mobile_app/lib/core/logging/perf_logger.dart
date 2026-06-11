// Dev audit toolkit — helper de mesure de performance.
//
// Wrap un Future async dans un Stopwatch et log la duree via AppLogger.
// Aucune donnee sensible n'est tracee (juste le nom de l'operation + ms).
// Conforme CLAUDE.md regle 4 : pas de payload utilisateur dans les logs.
//
// Usage :
//   final user = await logPerf('users.read', () => repo.watchProfile().first);
//   await logPerf('users.update.school', () => repo.updateLinkedSchool(s));

import 'package:firebase_core/firebase_core.dart';

import 'app_logger.dart';

/// Tag prefix utilise sur tous les logs perf. Permet de filtrer la console
/// avec `flutter run | grep PERF` pendant un audit de parcours.
const String _kPerfTag = 'PERF';

/// Wrappe une operation async dans un Stopwatch et log sa duree + capture
/// le type/code d'erreur si throw.
///
/// Le [name] doit etre court et stable (pattern `<collection>.<verb>`,
/// ex. `users.create`, `schools.search`, `nav.dashboard`). Eviter les IDs
/// utilisateur dans le nom.
///
/// Sur erreur :
/// - FirebaseException : log [PERF] name FAIL Nms code=... message=...
/// - autre exception : log [PERF] name FAIL Nms type=... message=...
///   et inclut la stack via AppLogger.w(error: e) pour Crashlytics.
/// L'exception est toujours rethrown.
Future<T> logPerf<T>(String name, Future<T> Function() op) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await op();
    stopwatch.stop();
    AppLogger.i('[$_kPerfTag] $name ok ${stopwatch.elapsedMilliseconds}ms');
    return result;
  } on FirebaseException catch (e, st) {
    stopwatch.stop();
    AppLogger.w(
      '[$_kPerfTag] $name FAIL ${stopwatch.elapsedMilliseconds}ms '
      'code=${e.code} message=${e.message ?? "(none)"}',
      error: e,
    );
    AppLogger.w('[$_kPerfTag] $name stack: $st');
    rethrow;
  } catch (e, st) {
    stopwatch.stop();
    AppLogger.w(
      '[$_kPerfTag] $name FAIL ${stopwatch.elapsedMilliseconds}ms '
      'type=${e.runtimeType} error=$e',
      error: e,
    );
    AppLogger.w('[$_kPerfTag] $name stack: $st');
    rethrow;
  }
}

/// Variante synchrone (peu utilisee, mais utile pour mesurer un parsing
/// JSON couteux par exemple). Pas de gestion d'erreur (l'appelant catch).
T logPerfSync<T>(String name, T Function() op) {
  final stopwatch = Stopwatch()..start();
  final result = op();
  stopwatch.stop();
  AppLogger.i('[$_kPerfTag] $name ok ${stopwatch.elapsedMilliseconds}ms (sync)');
  return result;
}

/// Marque un evenement instantane (entree/sortie de page, boot step).
/// Format : `[PERF] event:<name> tEpochMs=<ms>` pour calcul de delta cote
/// analyse de logs.
void logPerfEvent(String name) {
  final ms = DateTime.now().millisecondsSinceEpoch;
  AppLogger.i('[$_kPerfTag] event:$name tEpochMs=$ms');
}
