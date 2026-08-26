/// Response envelope shared by every campus `.jsmeb` / course-selection call.
///
/// The platform wraps all payloads in a JSON-RPC-ish envelope:
///
///     {"result": <payload>, "status": 200}
///     {"error": {"code": "-32606", "message": "参数格式非法！"}}
///
/// Two traps live here, both of which the original parser fell into:
///
/// * `status` is an **HTTP-like integer** (200), not a boolean. Testing
///   `status == true` is never satisfied, so a check written that way treats
///   every successful response as a failure.
/// * The payload lives under `result`, never under `data`. Reading `data`
///   silently yields an empty list instead of raising — the failure mode is a
///   blank course list rather than an error the user can act on.
///
/// Command endpoints additionally carry `result.code`, where `"0"` means
/// success and anything else pairs with a human-readable `result.msg`.
library;

import 'package:nkgrabber/core/errors/app_exception.dart';

/// Status values the platform's own JS treats as a dead session.
///
/// Taken from the school's `ajaxRequest` wrapper, which redirects to `./quit`
/// on 601/401 and shows a network-trouble toast on 602.
const _sessionExpiredStatuses = {401, 601};
const _serverBusyStatus = 602;

/// Unwrap a campus envelope and return the `result` payload.
///
/// Throws [CampusException] rather than returning null on any non-success
/// shape, so that callers cannot mistake "the session died" for "there are no
/// courses". [what] names the operation for the message the user sees.
Object? unwrapCampusResult(Map<String, dynamic> body, {required String what}) {
  // `error` wins over `result`: a malformed request returns both an error and
  // no payload, and reporting the payload's absence would hide the reason.
  final error = body['error'];
  if (error is Map<String, dynamic>) {
    final code = error['code']?.toString();
    final message = error['message']?.toString() ?? '未知错误';
    // -32604 is the platform's "account expired, re-login" code.
    if (code == '-32604') {
      throw const CampusException(
        message: '登录状态已失效，请重新添加账号',
        type: CampusExceptionType.sessionExpired,
      );
    }
    throw CampusException(
      message: '$what失败：$message',
      type: CampusExceptionType.parameterError,
    );
  }

  final status = _asInt(body['status']);
  if (status != null) {
    if (_sessionExpiredStatuses.contains(status)) {
      throw const CampusException(
        message: '登录状态已失效，请重新添加账号',
        type: CampusExceptionType.sessionExpired,
      );
    }
    if (status == _serverBusyStatus) {
      throw const CampusException(
        message: '学校服务器繁忙，请稍后重试',
        type: CampusExceptionType.unknownResponse,
      );
    }
  }

  if (!body.containsKey('result')) {
    throw CampusException(
      message: '$what失败：响应缺少 result 字段',
      type: CampusExceptionType.unknownResponse,
    );
  }

  return body['result'];
}

/// Unwrap an envelope whose `result` is a list of rows.
///
/// Returns an empty list when the payload is null — "no batches" and "no
/// courses" are both legitimate empty states, unlike a missing `result`.
List<Map<String, dynamic>> unwrapCampusRows(
  Map<String, dynamic> body, {
  required String what,
  String? listKey,
}) {
  final result = unwrapCampusResult(body, what: what);
  if (result == null) return const [];

  final Object? rows;
  if (listKey == null) {
    rows = result;
  } else if (result is Map<String, dynamic>) {
    // An object payload carries its own code/msg pair; surface a failure here
    // rather than returning the empty list its absent list key would imply.
    _throwIfCommandFailed(result, what: what);
    rows = result[listKey];
  } else {
    throw CampusException(
      message: '$what失败：响应格式不符合预期',
      type: CampusExceptionType.unknownResponse,
    );
  }

  if (rows == null) return const [];
  if (rows is! List) {
    throw CampusException(
      message: '$what失败：响应格式不符合预期',
      type: CampusExceptionType.unknownResponse,
    );
  }

  return rows.whereType<Map<String, dynamic>>().toList();
}

/// Unwrap a command envelope, throwing unless `result.code == "0"`.
///
/// Returns the result object so the caller can read `msg`.
Map<String, dynamic> unwrapCampusCommand(
  Map<String, dynamic> body, {
  required String what,
}) {
  final result = unwrapCampusResult(body, what: what);
  if (result is! Map<String, dynamic>) {
    throw CampusException(
      message: '$what失败：响应格式不符合预期',
      type: CampusExceptionType.unknownResponse,
    );
  }
  _throwIfCommandFailed(result, what: what);
  return result;
}

/// Throw when a result object carries a non-zero `code`.
///
/// A result with no `code` at all is treated as success: the read endpoints
/// omit it, and only command endpoints are documented to set it.
void _throwIfCommandFailed(
  Map<String, dynamic> result, {
  required String what,
}) {
  final code = result['code']?.toString();
  if (code == null || code == '0') return;

  final msg = result['msg']?.toString();
  throw CampusException(
    message: msg ?? '$what失败（代码 $code）',
    type: CampusExceptionType.unknownResponse,
  );
}

/// Parse a value the platform may send as either a number or a string.
///
/// The same field is not consistently typed across endpoints — `zdxk` arrives
/// as the string `"2"` from `getStudentXkList` while `xkms` arrives as the
/// number `0`. A plain `as num?` cast returns null for the string form and
/// silently falls back to a default.
int? campusInt(Object? value) => _asInt(value);

int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v.trim()),
  _ => null,
};

/// Read a field the platform sends as either a number or a string.
String? campusString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
