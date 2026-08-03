/// Request ID interceptor.
///
/// Attaches a unique ULID to every outgoing request as `X-Request-Id`
/// for log correlation and idempotent deduplication.
library;

import 'package:dio/dio.dart';
import 'package:ulid/ulid.dart';

class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Request-Id'] = Ulid().toString();
    handler.next(options);
  }
}
