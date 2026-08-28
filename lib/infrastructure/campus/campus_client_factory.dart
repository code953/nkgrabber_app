/// Per-account campus client factory.
///
/// Creates isolated Dio + CookieJar instances for each school account.
/// Ensures no cross-account cookie leakage.
library;

import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_bus.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/infrastructure/campus/encoding/gbk_codec.dart';

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
        // A stock desktop-Chrome header set, matched against a capture of the
        // school's own page making a real submission. The previous UA ended in
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
          // The portal's own XHRs send these. Whether the server enforces them
          // is unknown — but a request that differs from the browser's in a
          // field we could just as easily match is a difference we would have
          // to rule out first if the server ever starts refusing us.
          'X-Requested-With': 'XMLHttpRequest',
          'Origin': baseUrl ?? AppConstants.campusBaseUrl,
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
///
/// Writes to two places with different rules:
///
/// * `AppLogger` — the log file. Path and status only, as before.
/// * [grabLogBus] — the on-screen live log, which additionally carries the
///   request body and a response excerpt, because "what did we send and what
///   came back" is the whole point of that panel. Both go through
///   [LogSanitizer] first: the login body contains an RSA-encrypted password
///   and the response headers carry cookies.
class _CampusLoggingInterceptor extends Interceptor {
  _CampusLoggingInterceptor(this._accountId);

  final String _accountId;
  final _logger = AppLogger('Campus');

  /// Longest response excerpt shown in the live log. Enough for the whole
  /// envelope of a normal reply; an HTML error page gets cut off, which is
  /// itself the useful signal.
  static const _maxBodyChars = 600;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('[$_accountId] → ${options.method} ${options.path}');
    grabLogBus.log(
      GrabLogKind.request,
      '→ ${options.method} ${options.path}',
      accountId: _accountId,
      detail: _excerpt(options.data),
    );
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
    grabLogBus.log(
      GrabLogKind.response,
      '← ${response.statusCode} ${response.requestOptions.path}',
      accountId: _accountId,
      // Responses are ResponseType.bytes (GBK is decoded downstream), so a
      // raw byte list would render as "[123, 34, ...]". Decode leniently —
      // this is a preview, and a malformed byte must not throw here.
      detail: _excerpt(_decodePreview(response.data)),
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
    grabLogBus.log(
      GrabLogKind.failure,
      '✗ ${err.response?.statusCode ?? '网络错误'} '
      '${err.requestOptions.path}',
      accountId: _accountId,
      detail: LogSanitizer.sanitize(err.message ?? err.type.name),
    );
    handler.next(err);
  }

  /// GBK/UTF-8 tolerant preview of a byte body.
  String? _decodePreview(Object? data) {
    if (data is! List<int>) return data?.toString();
    final head = data.length > _maxBodyChars
        ? data.sublist(0, _maxBodyChars)
        : data;
    try {
      return decodeGbk(Uint8List.fromList(head));
    } on Object {
      return String.fromCharCodes(head.where((b) => b >= 0x20 && b < 0x7f));
    }
  }

  String? _excerpt(Object? data) {
    if (data == null) return null;
    final text = LogSanitizer.sanitize(data.toString());
    if (text.isEmpty) return null;
    return text.length > _maxBodyChars
        ? '${text.substring(0, _maxBodyChars)}…'
        : text;
  }
}
