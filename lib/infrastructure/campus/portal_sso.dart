/// Portal SSO handshake that exchanges a logged-in session for a `gdpk` cookie.
///
/// Logging in to the portal is not enough to reach the course-selection app: a
/// bare `GET /njs_3033/xsxk2` answers **403**. The app is registered with
/// `ssolx = 5`, which the portal's own `sso_login()` renders as
///
///     {origin}{appurl}[&|?]token={token}&apiUrl={origin}{apiurl}&userid={userid}
///
/// so the token, the api url and the student id all have to be threaded through
/// the redirect before the course-selection host will mint `gdpk`.
///
/// `appurl` carries a per-deployment `ssoappid`, so the registry has to be read
/// at runtime — hardcoding the path would break on any other campus.
library;

import 'package:nkgrabber/core/errors/app_exception.dart';

/// The SSO link type this client knows how to assemble.
///
/// The portal defines 0–6; only 5 is used by the course-selection app. Any
/// other value means the school re-registered the app with a different SSO
/// scheme, which needs a code change rather than a guessed URL.
const _supportedSsolx = 5;

/// Values scraped from the portal home page after a successful login.
class PortalSession {
  const PortalSession({required this.token, required this.userId});

  /// Short-lived SSO token. A credential — never log it.
  final String token;

  /// The student number the portal reports for this session.
  final String userId;
}

/// One entry of the portal's application registry.
class PortalApp {
  const PortalApp({
    required this.appUrl,
    required this.apiUrl,
    required this.ssolx,
  });

  /// App path including its per-deployment query string.
  final String appUrl;

  /// API base the app is told to call back into (`/gdpk` here).
  final String apiUrl;

  /// SSO link type; see [_supportedSsolx].
  final int ssolx;
}

/// Extract the SSO token and student id from the portal home page HTML.
///
/// Both are emitted as plain `var` assignments in an inline script.
PortalSession? parsePortalSession(String html) {
  final token = RegExp(
    r'''mycenter_token\s*=\s*["']([^"']+)["']''',
  ).firstMatch(html)?.group(1);
  final userId = RegExp(
    r'''mycenter_userid\s*=\s*["']([^"']+)["']''',
  ).firstMatch(html)?.group(1);

  if (token == null || token.isEmpty) return null;
  if (userId == null || userId.isEmpty) return null;

  return PortalSession(token: token, userId: userId);
}

/// Pick the course-selection app out of the portal's registry rows.
///
/// Rows are matched on the app path rather than the display name, because `mc`
/// is school-authored text ("学生选课") that a school could rename freely.
PortalApp? findCourseSelectionApp(List<Map<String, dynamic>> rows) {
  for (final row in rows) {
    final appUrl = row['appurl']?.toString();
    if (appUrl == null || !appUrl.contains('xsxk')) continue;

    final ssolx = switch (row['ssolx']) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? -1,
      _ => -1,
    };

    return PortalApp(
      appUrl: appUrl,
      apiUrl: row['apiurl']?.toString() ?? '',
      ssolx: ssolx,
    );
  }
  return null;
}

/// Build the SSO URL that yields the `gdpk` cookie.
///
/// [origin] is the scheme+host of the campus system, without a trailing slash.
String buildSsoUrl({
  required String origin,
  required PortalApp app,
  required PortalSession session,
}) {
  if (app.ssolx != _supportedSsolx) {
    throw CampusException(
      message:
          '学校选课入口的登录方式已变更（ssolx=${app.ssolx}），'
          '当前版本无法处理，请等待客户端升级',
      type: CampusExceptionType.loginFailed,
    );
  }

  final separator = app.appUrl.contains('?') ? '&' : '?';
  final apiUrl = app.apiUrl.startsWith('http')
      ? app.apiUrl
      : '$origin${app.apiUrl}';

  return '$origin${app.appUrl}$separator'
      'token=${Uri.encodeQueryComponent(session.token)}'
      '&apiUrl=${Uri.encodeQueryComponent(apiUrl)}'
      '&userid=${Uri.encodeQueryComponent(session.userId)}';
}

/// Extract the student's display name from the portal home page.
///
/// Present as `<sapn id="user_name">姓名</sapn>` (the platform's own typo) and
/// duplicated in the account menu's `title`. Returns null rather than throwing:
/// the name is display-only, and login must not fail over cosmetics.
String? parsePortalUserName(String html) {
  final byId = RegExp(
    '''id=["']user_name["'][^>]*>([^<]+)<''',
  ).firstMatch(html)?.group(1);
  if (byId != null && byId.trim().isNotEmpty) return byId.trim();

  final byTitle = RegExp(
    '''class=["'][^"']*userName[^"']*["'][^>]*title=["']([^"']+)["']''',
  ).firstMatch(html)?.group(1);
  if (byTitle != null && byTitle.trim().isNotEmpty) return byTitle.trim();

  return null;
}
