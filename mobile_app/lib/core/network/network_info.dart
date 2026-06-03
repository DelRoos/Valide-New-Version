import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline, unknown }

class NetworkInfo {
  NetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  Future<NetworkStatus> get status async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _mapResults(results);
    } catch (_) {
      return NetworkStatus.unknown;
    }
  }

  Stream<NetworkStatus> get statusStream =>
      _connectivity.onConnectivityChanged.map(_mapResults);

  static NetworkStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }
}

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfo(Connectivity()),
);

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(networkInfoProvider).statusStream;
});
