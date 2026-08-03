/// Per-account campus client factory.
///
/// Creates isolated Dio + CookieJar instances for each school account.
/// Ensures no cross-account cookie leakage.
library;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/core/utils/constants.dart';

/// An isolated HTTP client for a single campus account.
class CampusClient {
  CampusClient({String? accountId})
      : _cookieJar = CookieJar(),
        _accountId = accountId ?? 'unknown' {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.campusBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        // Don't auto-decode; we handle GBK manually.
        responseType: ResponseType.bytes,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NKgrabber/1.0',
          'Accept': '*/*',
        },
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(_CampusLoggingInterceptor(_accountId));
  }

  late final Dio _dio;
  final CookieJar _cookieJar;
  final String _accountId;

  /// The underlying Dio instance.
  Dio get dio => _dio;

  /// The cookie jar for this account.
  CookieJar get cookieJar => _cookieJar;

  /// Set a specific cookie (e.g., gdpk from user input).
  Future<void> setCookie(String name, String value, String domain) async {
    final cookie = Cookie(name, value)
      ..domain = domain
      ..path = '/';
    await _cookieJar.saveFromResponse(
      Uri.parse('${AppConstants.campusBaseUrl}/'),
      [cookie],
    );
  }

  /// Extract the Date header timestamp from the last response.
  DateTime? lastResponseDate;

  /// Close and clean up resources.
  void dispose() {
    _dio.close();
  }
}

/// Logging interceptor for campus requests (per-account).
class _CampusLoggingInterceptor extends Interceptor {
  _CampusLoggingInterceptor(this._accountId);

  final String _accountId;
  final _logger = AppLogger('Campus');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('[$_accountId] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '[$_accountId] ← ${response.statusCode} '
      '${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sanitizedUrl = LogSanitizer.sanitize(
      err.requestOptions.uri.toString(),
    );
    _logger.warn(
      '[$_accountId] ✗ ${err.response?.statusCode ?? 'N/A'} '
      '$sanitizedUrl: ${err.message ?? 'unknown error'}',
    );
    handler.next(err);
  }
}
