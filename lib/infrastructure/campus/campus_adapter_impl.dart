/// Campus adapter implementation.
///
/// Implements all campus system operations using an isolated [CampusClient].
/// Handles GBK decoding, RSA login, cookie management, and response parsing.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/infrastructure/campus/campus_adapter.dart';
import 'package:nkgrabber/infrastructure/campus/campus_client_factory.dart';
import 'package:nkgrabber/infrastructure/campus/crypto/rsa_encryptor.dart';
import 'package:nkgrabber/infrastructure/campus/encoding/gbk_codec.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';

class CampusAdapterImpl implements CampusAdapter {
  CampusAdapterImpl({required CampusClient client}) : _client = client;

  final CampusClient _client;
  final _logger = AppLogger('CampusAdapter');

  /// Per-account serial queue to prevent concurrent campus requests.
  final _queue = _RequestQueue();

  int _campusClockOffsetMs = 0;

  @override
  int get campusClockOffsetMs => _campusClockOffsetMs;

  @override
  Future<LoginResult> loginWithPassword(
    String account,
    String password,
  ) async {
    return _queue.add(() async {
      // Step 1: Get login page to extract RSA public key and kid.
      final welcomeResponse = await _client.dio.get<List<int>>(
        '/zhxy/welcome',
      );
      final html = _decodeResponse(welcomeResponse);

      final rsaParams = RsaEncryptor.extractFromHtml(html);
      if (rsaParams == null) {
        throw const CampusException(
          message: '无法从登录页面提取加密参数',
          type: CampusExceptionType.loginFailed,
        );
      }

      // Step 2: Encrypt password with RSA PKCS1v1.5.
      final encryptedPassword = RsaEncryptor.encrypt(
        password,
        rsaParams.pubKey,
      );

      // Step 3: POST login request.
      final loginResponse = await _client.dio.post<List<int>>(
        '/zhxy/rrtlogin/loginWithYzm.jsmeb',
        data: 'params=${Uri.encodeComponent('[$account,$encryptedPassword,,${rsaParams.kid}]')}',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      final loginBody = _decodeAndParseJson(loginResponse);
      _updateClockOffset(loginResponse);

      if (loginBody['status'] != true && loginBody['status'] != 'true') {
        final msg =
            loginBody['msg'] as String? ?? loginBody['message'] as String?;
        if (msg != null && msg.contains('验证码')) {
          throw const CampusException(
            message: '需要验证码',
            type: CampusExceptionType.captchaRequired,
          );
        }
        throw CampusException(
          message: msg ?? '登录失败',
          type: CampusExceptionType.loginFailed,
        );
      }

      // Step 4: Follow SSO redirect to obtain gdpk cookie.
      await _client.dio.get<List<int>>('/njs_3033/xsxk2');

      // Step 5: Extract gdpk from cookies.
      final cookies = await _client.cookieJar.loadForRequest(
        Uri.parse('${_client.dio.options.baseUrl}/njs_3033/'),
      );
      final gdpk = cookies
          .where((c) => c.name == 'gdpk')
          .map((c) => c.value)
          .firstOrNull;

      if (gdpk == null || gdpk.isEmpty) {
        throw const CampusException(
          message: '未获取到选课会话',
          type: CampusExceptionType.loginFailed,
        );
      }

      // Step 6: Fetch student profile.
      final profile = await _fetchProfile();

      _logger.info('Login successful: ${profile.studentName}');

      return LoginResult(
        gdpk: gdpk,
        studentNo: profile.studentNo,
        studentName: profile.studentName,
      );
    });
  }

  @override
  Future<StudentProfile> validateCookie(String gdpk) async {
    return _queue.add(() async {
      // Set the gdpk cookie.
      await _client.setCookie(
        'gdpk',
        gdpk,
        Uri.parse(_client.dio.options.baseUrl).host,
      );

      return _fetchProfile();
    });
  }

  @override
  Future<List<SelectionBatch>> listBatches() async {
    return _queue.add(() async {
      final response = await _client.dio.post<List<int>>(
        '/njs_3033/xsxk/getStudentXkList',
        data: '',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      _updateClockOffset(response);
      final body = _decodeAndParseJson(response);

      final dataList = body['data'] as List<dynamic>? ?? [];
      return dataList.map((item) {
        final map = item as Map<String, dynamic>;
        return SelectionBatch(
          xkid: map['xkid']?.toString() ?? '',
          xkms: map['xkms']?.toString() ?? '',
          batchName: map['xkmc']?.toString() ?? map['pcmc']?.toString() ?? '',
          zdxk: (map['zdxk'] as num?)?.toInt() ?? 1,
          kssj: map['kssj']?.toString() ?? '',
          jssj: map['jssj']?.toString() ?? '',
        );
      }).toList();
    });
  }

  @override
  Future<List<Course>> listCourses(String xkid) async {
    return _queue.add(() async {
      final response = await _client.dio.post<List<int>>(
        '/njs_3033/xsxk_Xbk/getXbkByXkid',
        data: 'xkid=$xkid',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      _updateClockOffset(response);
      final body = _decodeAndParseJson(response);

      final dataList = body['data'] as List<dynamic>? ?? [];
      return dataList.map((item) {
        final map = item as Map<String, dynamic>;
        return Course(
          kmh: map['kmh']?.toString() ?? '',
          courseName: map['kcmc']?.toString() ?? '',
          xbkid: map['xbkid']?.toString(),
          teacherName: map['jsxm']?.toString(),
          capacity: (map['setzrs'] as num?)?.toInt(),
          selected: (map['setyxzrs'] as num?)?.toInt(),
          remaining: (map['setwxzrs'] as num?)?.toInt(),
        );
      }).toList();
    });
  }

  @override
  Future<List<SelectionRecord>> listSelections(String xkid) async {
    return _queue.add(() async {
      final response = await _client.dio.post<List<int>>(
        '/njs_3033/xsxk_Xbk/getStudentXkJlList',
        data: 'xkid=$xkid',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      _updateClockOffset(response);
      final body = _decodeAndParseJson(response);

      final dataList = body['data'] as List<dynamic>? ?? [];
      return dataList.map((item) {
        final map = item as Map<String, dynamic>;
        return SelectionRecord(
          kmh: map['kmh']?.toString() ?? '',
          courseName: map['kcmc']?.toString() ?? '',
        );
      }).toList();
    });
  }

  @override
  Future<SubmitResult> submit(SubmitSelection command) async {
    return _queue.add(() async {
      final kmhDtoList = command.kmhList.join(',');
      final response = await _client.dio.post<List<int>>(
        '/njs_3033/xsxk_Xbk/saveStudentXkJs',
        data: 'xkid=${command.xkid}'
            '&xkms=${command.xkms}'
            '&sftj=1'
            '&kms=${command.kmhList.length}'
            '&kmhDtoList=$kmhDtoList',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      _updateClockOffset(response);
      final body = _decodeAndParseJson(response);

      final success = body['status'] == true || body['status'] == 'true';
      final result = body['result'] as Map<String, dynamic>?;
      final msg = result?['msg']?.toString() ??
          body['msg']?.toString() ??
          body['message']?.toString();

      return SubmitResult(
        success: success,
        message: msg,
      );
    });
  }

  @override
  Future<WithdrawResult> withdraw(String xkid) async {
    return _queue.add(() async {
      final response = await _client.dio.post<List<int>>(
        '/njs_3033/xsxk_Xbk/xschXbkxkCz',
        data: 'xkid=$xkid',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
      _updateClockOffset(response);
      final body = _decodeAndParseJson(response);

      final success = body['status'] == true || body['status'] == 'true';
      final msg = body['msg']?.toString() ?? body['message']?.toString();

      return WithdrawResult(
        success: success,
        message: msg,
      );
    });
  }

  // -- Private helpers -------------------------------------------------------

  /// Fetch student profile from the current session.
  Future<StudentProfile> _fetchProfile() async {
    // Attempt to get student info from a known endpoint.
    final response = await _client.dio.post<List<int>>(
      '/njs_3033/xsxk/getStudentXkList',
      data: '',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
    _updateClockOffset(response);
    final body = _decodeAndParseJson(response);

    // If the session is invalid, the server returns an error.
    if (body['status'] == false || body['status'] == 'false') {
      throw const CampusException(
        message: '会话已过期',
        type: CampusExceptionType.sessionExpired,
      );
    }

    // Extract student info from user data.
    final userData = body['user'] as Map<String, dynamic>?;
    final studentNo = userData?['xh']?.toString() ?? '';
    final studentName = userData?['xm']?.toString() ?? '';

    if (studentNo.isEmpty) {
      throw const CampusException(
        message: '无法获取学生信息',
        type: CampusExceptionType.sessionExpired,
      );
    }

    return StudentProfile(
      studentNo: studentNo,
      studentName: studentName,
    );
  }

  /// Decode a raw byte response to a string, handling GBK.
  String _decodeResponse(Response<List<int>> response) {
    final data = response.data;
    if (data == null) return '';
    return decodeGbk(Uint8List.fromList(data));
  }

  /// Decode raw bytes and parse as JSON.
  Map<String, dynamic> _decodeAndParseJson(Response<List<int>> response) {
    final text = _decodeResponse(response);
    if (text.isEmpty) {
      throw const CampusException(
        message: '服务器返回空响应',
        type: CampusExceptionType.unknownResponse,
      );
    }
    try {
      final parsed = json.decode(text);
      if (parsed is Map<String, dynamic>) return parsed;
      throw const CampusException(
        message: '响应格式错误',
        type: CampusExceptionType.unknownResponse,
      );
    } on FormatException {
      throw const CampusException(
        message: '响应不是有效的JSON',
        type: CampusExceptionType.unknownResponse,
      );
    }
  }

  /// Update campus clock offset from response Date header.
  void _updateClockOffset(Response<dynamic> response) {
    final dateHeader = response.headers.value('date');
    if (dateHeader != null) {
      final serverDate = HttpDate.parse(dateHeader);
      final localDate = DateTime.now().toUtc();
      _campusClockOffsetMs =
          serverDate.difference(localDate).inMilliseconds;
      _client.lastResponseDate = serverDate;
    }
  }
}

/// HTTP Date parsing helper.
class HttpDate {
  const HttpDate._();

  /// Parse an HTTP Date header value (RFC 7231).
  static DateTime parse(String dateStr) {
    // HTTP dates are typically in the format:
    // "Mon, 21 Jul 2026 05:00:00 GMT"
    try {
      return _parseRfc1123(dateStr);
    } catch (_) {
      // Fallback: try general parsing.
      return DateTime.tryParse(dateStr)?.toUtc() ?? DateTime.now().toUtc();
    }
  }

  static DateTime _parseRfc1123(String s) {
    // "Mon, 21 Jul 2026 05:00:00 GMT"
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
      'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = s.replaceAll(',', '').split(RegExp(r'\s+'));
    // parts: [Mon, 21, Jul, 2026, 05:00:00, GMT]
    final day = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year = int.parse(parts[3]);
    final timeParts = parts[4].split(':');
    return DateTime.utc(
      year,
      month,
      day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      int.parse(timeParts[2]),
    );
  }
}

/// Simple per-account serial request queue.
///
/// Ensures that only one campus request runs at a time per account (§7.4).
class _RequestQueue {
  Future<void>? _last;

  Future<T> add<T>(Future<T> Function() task) async {
    // Wait for the previous task to complete.
    while (_last != null) {
      try {
        await _last;
      } catch (_) {
        // Ignore errors from previous tasks.
      }
    }

    final completer = Completer<T>();
    _last = completer.future.then<void>((_) {}).catchError((_) {});

    try {
      final result = await task();
      completer.complete(result);
      return result;
    } catch (e, s) {
      completer.completeError(e, s);
      rethrow;
    } finally {
      _last = null;
    }
  }
}
