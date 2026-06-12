// Detection connectivite reseau pour banner offline global.
//
// Stream du status reel (online / offline) base sur connectivity_plus. Le
// banner global (cf. lib/core/widgets/feedback/offline_banner.dart) consume
// ce provider pour afficher un bandeau persistant tant que le device n'a pas
// retrouve une connectivite (wifi ou cellulaire).

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

enum ConnectivityStatus { online, offline }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((results) {
    final status = _resolveStatus(results);
    AppLogger.i('connectivity: $status (results=$results)');
    return status;
  }).distinct();
});

ConnectivityStatus _resolveStatus(List<ConnectivityResult> results) {
  // Hors ligne si l'unique result est `none`, ou si la liste est vide.
  // wifi / mobile / ethernet / vpn / bluetooth -> online (le device a un
  // chemin reseau, meme s'il peut etre lent).
  if (results.isEmpty) return ConnectivityStatus.offline;
  if (results.length == 1 && results.first == ConnectivityResult.none) {
    return ConnectivityStatus.offline;
  }
  return ConnectivityStatus.online;
}
