// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NKgrabber';

  @override
  String get startupLoading => 'Loading...';

  @override
  String get activationTitle => 'Activate License';

  @override
  String get activationHint => 'Enter activation code';

  @override
  String get activationButton => 'Activate';

  @override
  String get activationSuccess => 'Activation successful';

  @override
  String get activationFormatError => 'Invalid format. Use XXXX-XXXX-XXXX-XXXX';

  @override
  String get consentTitle => 'Notice';

  @override
  String get consentCrashReportingDesc =>
      'This app sends crash reports by default to improve quality. Reports include only sanitized stack traces, app version, and platform info. They never include your account, password, cookies, activation code, or course data.';

  @override
  String get consentDisableOption => 'Always disable crash reporting';

  @override
  String get consentAgree => 'I understand, continue';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navCourses => 'Courses';

  @override
  String get navGrabber => 'Grab';

  @override
  String get navSettings => 'Settings';

  @override
  String get accountsTitle => 'Account Management';

  @override
  String get accountsAdd => 'Add Account';

  @override
  String get accountsAddPassword => 'Password Login';

  @override
  String get accountsAddCookie => 'Cookie Login';

  @override
  String get accountsSchoolId => 'Student ID';

  @override
  String get accountsPassword => 'Password';

  @override
  String get accountsCookie => 'gdpk Cookie';

  @override
  String get accountsRememberPassword => 'Remember password';

  @override
  String accountsConfirmIdentity(String name, String lastFour) {
    return 'Confirm identity: $name ($lastFour)';
  }

  @override
  String get accountStatusReady => 'Ready';

  @override
  String get accountStatusExpired => 'Session Expired';

  @override
  String get accountStatusCaptcha => 'Captcha Required';

  @override
  String get accountStatusNetwork => 'Network Error';

  @override
  String get accountStatusDisabled => 'Disabled (Over Limit)';

  @override
  String get accountStatusValidating => 'Validating';

  @override
  String get coursesTitle => 'Course Settings';

  @override
  String get coursesSelectAccount => 'Select Account';

  @override
  String get coursesSelectBatch => 'Select Batch';

  @override
  String get coursesBatchGrab => 'Grab';

  @override
  String get coursesBatchNormal => 'Normal';

  @override
  String get coursesBatchSupplement => 'Supplement';

  @override
  String get coursesAddTarget => 'Add Target';

  @override
  String get coursesTargetPriority => 'Priority';

  @override
  String get grabberTitle => 'Course Grabber';

  @override
  String get grabberStart => 'Start';

  @override
  String get grabberStop => 'Stop';

  @override
  String get grabberPause => 'Pause';

  @override
  String get grabberStateIdle => 'Idle';

  @override
  String get grabberStatePreparing => 'Preparing';

  @override
  String get grabberStateRunning => 'Running';

  @override
  String get grabberStateSuccess => 'Success';

  @override
  String get grabberStatePaused => 'Paused';

  @override
  String get grabberStateStopped => 'Stopped';

  @override
  String get grabberStateInterrupted => 'Interrupted';

  @override
  String get grabberStateAuthExpired => 'Auth Expired';

  @override
  String get grabberStateCaptcha => 'Captcha Required';

  @override
  String get grabberStateFailed => 'Failed';

  @override
  String get grabberInterval => 'Request Interval';

  @override
  String grabberIntervalMs(int ms) {
    return '$ms ms';
  }

  @override
  String get grabberBatchNotOpen => 'Batch not open yet, please wait';

  @override
  String get grabberTimeout =>
      'Task ran for 30 minutes and was stopped. Please confirm and restart.';

  @override
  String get grabberClockWarning =>
      'System clock drift too large, please sync your clock';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSimple => 'Simple';

  @override
  String get settingsThemeAnime => 'Anime';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsInterval => 'Request Interval';

  @override
  String get settingsLogLevel => 'Log Level';

  @override
  String get settingsDiagnostics => 'Export Diagnostics';

  @override
  String get settingsDiagnosticsHint =>
      'Data will be sanitized before export. Please review after export.';

  @override
  String get settingsCrashReporting => 'Crash Reporting';

  @override
  String get settingsCrashReportingDesc => 'Help us improve quality';

  @override
  String get settingsCheckUpdate => 'Check for Updates';

  @override
  String get settingsUnbind => 'Unbind Device';

  @override
  String get settingsUnbindConfirm =>
      'Confirm unbind? Cannot rebind for 24 hours.';

  @override
  String settingsUnbindCooldown(String time) {
    return 'Cooling down, can rebind after $time';
  }

  @override
  String get updateTitle => 'Update';

  @override
  String updateAvailable(String version) {
    return 'New version $version available';
  }

  @override
  String get updateMandatory => 'This update is mandatory';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateVerifying => 'Verifying...';

  @override
  String get updateVerifyFailed => 'Verification failed, please re-download';

  @override
  String get updateInstall => 'Install';

  @override
  String get maintenanceTitle => 'Under Maintenance';

  @override
  String get maintenanceMessage =>
      'System is under maintenance, please try again later';

  @override
  String get versionTooLow => 'Version too old, please update to continue';

  @override
  String get errorNetwork => 'Network error, please check connection';

  @override
  String get errorTimeout => 'Request timeout, please try later';

  @override
  String get errorServer => 'Server error, please try later';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get errorTokenInvalid => 'Authorization invalid, please re-activate';

  @override
  String get errorLicenseExpired => 'License expired';

  @override
  String get errorDeviceLimit => 'Activation code bound to another device';

  @override
  String get errorRateLimited => 'Rate limited, please try later';

  @override
  String get errorXkmsUnknown =>
      'Unknown selection mode, please update the app';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';
}
