/// Backend repository implementation using Dio.
///
/// Implements all backend API operations with proper error handling
/// and response parsing.
library;

import 'package:dio/dio.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/infrastructure/backend/backend_repository.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/app_config_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/latest_release_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/license_activation_dto.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/license_validation_dto.dart';

class BackendRepositoryImpl implements BackendRepository {
  BackendRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<LicenseActivationDto> activateLicense({
    required String licenseCode,
    required String installId,
    required String deviceName,
    required String platform,
    required String appVersion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/licenses/activate',
      data: {
        'licenseCode': licenseCode,
        'installId': installId,
        'deviceName': deviceName,
        'platform': platform,
        'appVersion': appVersion,
      },
    );
    final data = _extractData(response);
    return LicenseActivationDto.fromJson(data);
  }

  @override
  Future<LicenseValidationDto> validateLicense({
    required String installId,
    required String appVersion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/licenses/validate',
      data: {
        'installId': installId,
        'appVersion': appVersion,
      },
    );
    final data = _extractData(response);
    return LicenseValidationDto.fromJson(data);
  }

  @override
  Future<void> deactivateLicense({required String installId}) async {
    await _dio.post<Map<String, dynamic>>(
      '/licenses/deactivate',
      data: {'installId': installId},
    );
  }

  @override
  Future<AppConfigDto> fetchConfig({
    required String platform,
    required String appVersion,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/app/config',
      queryParameters: {
        'platform': platform,
        'appVersion': appVersion,
      },
    );
    final data = _extractData(response);
    return AppConfigDto.fromJson(data);
  }

  @override
  Future<LatestReleaseDto?> checkUpdate({
    required String platform,
    required String arch,
    required String currentVersion,
    required String channel,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/app/releases/latest',
      queryParameters: {
        'platform': platform,
        'arch': arch,
        'currentVersion': currentVersion,
        'channel': channel,
      },
    );
    final body = response.data;
    if (body == null) return null;

    final data = body['data'];
    if (data == null) return null;

    return LatestReleaseDto.fromJson(data as Map<String, dynamic>);
  }

  /// Extract the `data` field from a successful response.
  Map<String, dynamic> _extractData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const NetworkException(
        message: '服务器返回空响应',
        type: NetworkExceptionType.unknown,
      );
    }

    final success = body['success'] as bool? ?? false;
    if (!success) {
      final code = body['code'] as String? ?? 'UNKNOWN';
      final message = body['message'] as String? ?? '未知错误';
      throw NetworkException(
        message: '[$code] $message',
        type: NetworkExceptionType.serverError,
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const NetworkException(
        message: '响应数据格式错误',
        type: NetworkExceptionType.unknown,
      );
    }
    return data;
  }
}
