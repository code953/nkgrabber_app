/// Logging interceptor for backend requests.
///
/// Logs sanitized request/response info using [AppLogger].
/// Sensitive headers and body fields are redacted.
library;

import 'package:dio/dio.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';

class BackendLoggingInterceptor extends Interceptor {
  final _logger = AppLogger('BackendApi');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug(
      '→ ${options.method} ${options.path}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _logger.debug(
      '← ${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sanitizedUrl = LogSanitizer.sanitize(
      err.requestOptions.uri.toString(),
    );
    _logger.warn(
      '✗ ${err.response?.statusCode ?? 'N/A'} $sanitizedUrl: '
      '${err.message ?? 'unknown error'}',
    );
    handler.next(err);
  }
}
