import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../utils/env.dart';

class DioClient {
  DioClient({
    String? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    Future<void> Function(Duration)? sleep,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? Env.apiBaseUrl,
                connectTimeout: timeout,
                sendTimeout: timeout,
                receiveTimeout: timeout,
              ),
            ) {
    _dio.interceptors.addAll([
      _LogInterceptor(),
      _RetryInterceptor(_dio, sleep: sleep ?? Future.delayed),
    ]);
  }

  final Dio _dio;

  Dio get dio => _dio;
}

class _LogInterceptor extends Interceptor {
  static const int _maxBodyLogBytes = 1024;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('→ ${options.method} ${options.uri}');
    final data = options.data;
    if (data != null) {
      final repr = data.toString();
      if (repr.length <= _maxBodyLogBytes) {
        AppLogger.d('  body: $repr');
      } else {
        AppLogger.d('  body: <${repr.length} bytes>');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.i(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    AppLogger.e(
      '✗ ${status ?? err.type.name} ${err.requestOptions.method} ${err.requestOptions.uri} : ${err.message ?? '(no message)'}',
    );
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio, {required this.sleep});

  static const int _maxAttempts = 3;
  static const List<Duration> _backoff = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  final Dio _dio;
  final Future<void> Function(Duration) sleep;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;

    if (!_isRetryable(err) || attempt >= _maxAttempts) {
      return handler.next(err);
    }

    final delay = _backoff[attempt];
    AppLogger.w(
      'Retry ${attempt + 1}/$_maxAttempts apres ${delay.inMilliseconds}ms : ${err.requestOptions.uri}',
    );
    await sleep(delay);

    final nextOptions = err.requestOptions
      ..extra['retry_attempt'] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(nextOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status == 429 || (status >= 500 && status < 600);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
