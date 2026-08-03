/// App info interceptor.
///
/// Attaches `X-App-Version`, `X-Platform`, and `X-Install-Id` headers
/// to every outgoing request.
library;

import 'package:dio/dio.dart';

class AppInfoInterceptor extends Interceptor {
  AppInfoInterceptor({
    required this.installIdGetter,
    required this.appVersionGetter,
    required this.platformGetter,
  });

  final String Function() installIdGetter;
  final String Function() appVersionGetter;
  final String Function() platformGetter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-App-Version'] = appVersionGetter();
    options.headers['X-Platform'] = platformGetter();
    options.headers['X-Install-Id'] = installIdGetter();
    handler.next(options);
  }
}
