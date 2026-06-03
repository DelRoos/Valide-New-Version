import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/network/dio_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._statusCodes);

  final List<int> _statusCodes;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final idx = callCount < _statusCodes.length
        ? callCount
        : _statusCodes.length - 1;
    final status = _statusCodes[idx];
    callCount++;
    return ResponseBody.fromString(
      '{"status":$status}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioClient _buildClient(_FakeAdapter adapter) {
  final innerDio = Dio()..httpClientAdapter = adapter;
  return DioClient(dio: innerDio, sleep: (_) async {});
}

void main() {
  group('DioClient retry interceptor', () {
    test('503 → 503 → 200 réussit en 3 tentatives', () async {
      final adapter = _FakeAdapter([503, 503, 200]);
      final client = _buildClient(adapter);

      final response = await client.dio.get<dynamic>('/test');

      expect(response.statusCode, equals(200));
      expect(adapter.callCount, equals(3));
    });

    test('503 toujours échoue après 4 tentatives (1 initial + 3 retries)',
        () async {
      final adapter = _FakeAdapter([503]);
      final client = _buildClient(adapter);

      await expectLater(
        client.dio.get<dynamic>('/test'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, equals(4));
    });

    test('200 direct ne déclenche aucun retry', () async {
      final adapter = _FakeAdapter([200]);
      final client = _buildClient(adapter);

      final response = await client.dio.get<dynamic>('/test');

      expect(response.statusCode, equals(200));
      expect(adapter.callCount, equals(1));
    });

    test('400 ne déclenche pas de retry (4xx non retriable hors 429)',
        () async {
      final adapter = _FakeAdapter([400]);
      final client = _buildClient(adapter);

      await expectLater(
        client.dio.get<dynamic>('/test'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.callCount, equals(1));
    });

    test('429 déclenche un retry (rate limit)', () async {
      final adapter = _FakeAdapter([429, 200]);
      final client = _buildClient(adapter);

      final response = await client.dio.get<dynamic>('/test');

      expect(response.statusCode, equals(200));
      expect(adapter.callCount, equals(2));
    });
  });
}
