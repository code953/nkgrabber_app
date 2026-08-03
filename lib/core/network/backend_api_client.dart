/// Backend API client using Dio.
///
/// Configured with base URL, timeouts, and all required interceptors.
/// This client handles communication with the NKgrabber backend server.
library;

import 'package:dio/dio.dart';
import 'package:nkgrabber/core/network/interceptors/app_info_interceptor.dart';
import 'package:nkgrabber/core/network/interceptors/auth_interceptor.dart';
import 'package:nkgrabber/core/network/interceptors/clock_sync_interceptor.dart';
import 'package:nkgrabber/core/network/interceptors/error_interceptor.dart';
import 'package:nkgrabber/core/network/interceptors/logging_interceptor.dart';
import 'package:nkgrabber/core/network/interceptors/request_id_interceptor.dart';
import 'package:nkgrabber/core/utils/constants.dart';

/// Creates a configured [Dio] instance for the backend API.
///
/// Attaches interceptors for: request ID, app info, auth, clock sync,
/// error mapping, and logging (in that order).
Dio createBackendClient({
  required String Function() installIdGetter,
  required String Function() appVersionGetter,
  required String Function() platformGetter,
  required String? Function() deviceTokenGetter,
  required void Function(String) onDeviceTokenRotated,
  required void Function(int) onClockOffsetUpdated,
  required void Function() onTokenInvalid,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.backendBaseUrl,
      connectTimeout: AppConstants.backendConnectTimeout,
      receiveTimeout: AppConstants.backendReceiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Interceptors are executed in order for requests,
  // and in reverse order for responses/errors.
  dio.interceptors.addAll([
    RequestIdInterceptor(),
    AppInfoInterceptor(
      installIdGetter: installIdGetter,
      appVersionGetter: appVersionGetter,
      platformGetter: platformGetter,
    ),
    AuthInterceptor(
      deviceTokenGetter: deviceTokenGetter,
      onTokenInvalid: onTokenInvalid,
    ),
    ClockSyncInterceptor(onOffsetUpdated: onClockOffsetUpdated),
    ErrorInterceptor(),
    BackendLoggingInterceptor(),
  ]);

  return dio;
}
