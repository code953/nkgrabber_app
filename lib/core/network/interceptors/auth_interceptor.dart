/// Auth interceptor.
///
/// Attaches `Authorization: Bearer <deviceToken>` header when a token
/// is available. Handles 401 responses by triggering re-activation flow.
library;

import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.deviceTokenGetter,
    required this.onTokenInvalid,
  });

  final String? Function() deviceTokenGetter;
  final void Function() onTokenInvalid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = deviceTokenGetter();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onTokenInvalid();
    }
    handler.next(err);
  }
}
