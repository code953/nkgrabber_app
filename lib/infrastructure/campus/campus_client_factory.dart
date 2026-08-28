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
  /// [baseUrl] defaults to the real campus host. It is injectable only so a
  /// test can point the client at a loopback server; production never sets it.
  CampusClient({String? accountId, String? baseUrl})
    : _cookieJar = CookieJar(),
      _accountId = accountId ?? 'unknown' {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.campusBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        // Don't auto-decode; we handle GBK manually.
        responseType: ResponseType.bytes,
        // A stock desktop-Chrome header set. The previous UA ended in
        // `NKgrabber/1.0`, which named the tool in every single request — one
        // `grep` server-side would have found every user of it. Nothing in the
        // campus protocol keys off the UA, so there is no reason to be
        // identifiable here.
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/131.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,'
              'image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9',
        },
      ),
    );
    // The portal emits a bare `Set-Cookie: HttpOnly=` alongside the real
    // session cookie — it means to append the HttpOnly *attribute* to
    // JSESSIONID and gets the header wrong. dart:io refuses to parse it, and
    // CookieManager forces the whole map with .toList(), so that one throw
    // discards the valid JSESSIONID on the same response and dio rejects the
    // request as `DioException [unknown]: null`. Skipping the bad fragment is
    // what browsers do; the school's header is not something we can fix.
    _dio.interceptors.add(
      CookieManager(_cookieJar, ignoreInvalidCookies: true),
    );
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
