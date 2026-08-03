/// Error interceptor.
///
/// Maps HTTP status codes and backend `code` field values to typed
/// [AppException] instances for consistent error handling throughout the app.
library;

import 'package:dio/dio.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapDioError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    // Network-level errors (no response received).
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return const NetworkException(
        message: '连接超时，请检查网络',
        type: NetworkExceptionType.timeout,
      );
    }

    if (err.type == DioExceptionType.connectionError) {
      return const NetworkException(
        message: '无法连接服务器',
        type: NetworkExceptionType.noConnection,
      );
    }

    // Server responded with an error status code.
    final response = err.response;
    if (response == null) {
      return NetworkException(
        message: err.message ?? '网络请求失败',
        type: NetworkExceptionType.unknown,
      );
    }

    final data = response.data;
    final code = data is Map<String, dynamic>
        ? data['code'] as String?
        : null;
    final message = data is Map<String, dynamic>
        ? (data['message'] as String?) ?? '未知错误'
        : '未知错误';

    return _mapStatusAndCode(response.statusCode ?? 0, code, message, data);
  }

  AppException _mapStatusAndCode(
    int statusCode,
    String? code,
    String message,
    dynamic data,
  ) {
    switch (statusCode) {
      case 400:
        return NetworkException(
          message: message,
          type: NetworkExceptionType.badRequest,
        );
      case 401:
        return const AuthException(
          message: '设备令牌无效，请重新激活',
          type: AuthExceptionType.tokenInvalid,
        );
      case 403:
        return _mapForbidden(code, message);
      case 409:
        if (code == 'UNBIND_COOLDOWN_ACTIVE') {
          final availableAt = _extractAvailableAt(data);
          final suffix =
              availableAt != null ? '，可在 $availableAt 后重试' : '';
          return AuthException(
            message: '解绑冷却中$suffix',
            type: AuthExceptionType.unbindCooldown,
          );
        }
        return NetworkException(
          message: message,
          type: NetworkExceptionType.conflict,
        );
      case 429:
        return const NetworkException(
          message: '请求过于频繁，请稍后重试',
          type: NetworkExceptionType.rateLimited,
        );
      case 500:
        return const NetworkException(
          message: '服务器内部错误',
          type: NetworkExceptionType.serverError,
        );
      case 503:
        return const MaintenanceException(message: '服务暂时不可用');
      default:
        return NetworkException(
          message: message,
          type: NetworkExceptionType.unknown,
        );
    }
  }

  AppException _mapForbidden(String? code, String message) {
    switch (code) {
      case 'LICENSE_INACTIVE':
        return const AuthException(
          message: '授权已失效',
          type: AuthExceptionType.licenseInactive,
        );
      case 'LICENSE_EXPIRED':
        return const AuthException(
          message: '授权已过期',
          type: AuthExceptionType.licenseExpired,
        );
      case 'DEVICE_LIMIT_REACHED':
        return const AuthException(
          message: '该激活码已绑定其他设备',
          type: AuthExceptionType.deviceLimitReached,
        );
      default:
        return AuthException(
          message: message,
          type: AuthExceptionType.forbidden,
        );
    }
  }

  String? _extractAvailableAt(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        return inner['availableAt'] as String?;
      }
    }
    return null;
  }
}
