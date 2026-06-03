import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valide_school/core/network/network_info.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('NetworkInfo.status', () {
    test('retourne online quand au moins une connexion est active (wifi)',
        () async {
      final mock = _MockConnectivity();
      when(() => mock.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final info = NetworkInfo(mock);
      expect(await info.status, equals(NetworkStatus.online));
    });

    test('retourne offline quand results est [none]', () async {
      final mock = _MockConnectivity();
      when(() => mock.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final info = NetworkInfo(mock);
      expect(await info.status, equals(NetworkStatus.offline));
    });

    test('retourne unknown si checkConnectivity lance une exception',
        () async {
      final mock = _MockConnectivity();
      when(() => mock.checkConnectivity())
          .thenThrow(Exception('platform error'));

      final info = NetworkInfo(mock);
      expect(await info.status, equals(NetworkStatus.unknown));
    });
  });
}
