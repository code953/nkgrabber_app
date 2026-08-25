import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'NKgrabber'**
  String get appTitle;

  /// No description provided for @startupLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载...'**
  String get startupLoading;

  /// No description provided for @activationTitle.
  ///
  /// In zh, this message translates to:
  /// **'激活授权'**
  String get activationTitle;

  /// No description provided for @activationHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入激活码'**
  String get activationHint;

  /// No description provided for @activationButton.
  ///
  /// In zh, this message translates to:
  /// **'激活'**
  String get activationButton;

  /// No description provided for @activationSuccess.
  ///
  /// In zh, this message translates to:
  /// **'激活成功'**
  String get activationSuccess;

  /// No description provided for @activationFormatError.
  ///
  /// In zh, this message translates to:
  /// **'激活码格式错误，请输入 XXXX-XXXX-XXXX-XXXX 格式'**
  String get activationFormatError;

  /// No description provided for @navAccounts.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get navAccounts;

  /// No description provided for @navCourses.
  ///
  /// In zh, this message translates to:
  /// **'课程'**
  String get navCourses;

  /// No description provided for @navGrabber.
  ///
  /// In zh, this message translates to:
  /// **'抢课'**
  String get navGrabber;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @accountsTitle.
  ///
  /// In zh, this message translates to:
  /// **'账号管理'**
  String get accountsTitle;

  /// No description provided for @accountsAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加账号'**
  String get accountsAdd;

  /// No description provided for @accountsAddPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码登录'**
  String get accountsAddPassword;

  /// No description provided for @accountsAddCookie.
  ///
  /// In zh, this message translates to:
  /// **'Cookie 登录'**
  String get accountsAddCookie;

  /// No description provided for @accountsSchoolId.
  ///
  /// In zh, this message translates to:
  /// **'学号'**
  String get accountsSchoolId;

  /// No description provided for @accountsPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get accountsPassword;

  /// No description provided for @accountsCookie.
  ///
  /// In zh, this message translates to:
  /// **'gdpk Cookie'**
  String get accountsCookie;

  /// No description provided for @accountsRememberPassword.
  ///
  /// In zh, this message translates to:
  /// **'记住密码'**
  String get accountsRememberPassword;

  /// No description provided for @accountsConfirmIdentity.
  ///
  /// In zh, this message translates to:
  /// **'确认身份：{name}（{lastFour}）'**
  String accountsConfirmIdentity(String name, String lastFour);

  /// No description provided for @accountStatusReady.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get accountStatusReady;

  /// No description provided for @accountStatusExpired.
  ///
  /// In zh, this message translates to:
  /// **'会话过期'**
  String get accountStatusExpired;

  /// No description provided for @accountStatusCaptcha.
  ///
  /// In zh, this message translates to:
  /// **'需要验证码'**
  String get accountStatusCaptcha;

  /// No description provided for @accountStatusNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误'**
  String get accountStatusNetwork;

  /// No description provided for @accountStatusDisabled.
  ///
  /// In zh, this message translates to:
  /// **'超额停用'**
  String get accountStatusDisabled;

  /// No description provided for @accountStatusValidating.
  ///
  /// In zh, this message translates to:
  /// **'验证中'**
  String get accountStatusValidating;

  /// No description provided for @coursesTitle.
  ///
  /// In zh, this message translates to:
  /// **'课程设置'**
  String get coursesTitle;

  /// No description provided for @coursesSelectAccount.
  ///
  /// In zh, this message translates to:
  /// **'选择账号'**
  String get coursesSelectAccount;

  /// No description provided for @coursesSelectBatch.
  ///
  /// In zh, this message translates to:
  /// **'选择批次'**
  String get coursesSelectBatch;

  /// No description provided for @coursesBatchGrab.
  ///
  /// In zh, this message translates to:
  /// **'抢选'**
  String get coursesBatchGrab;

  /// No description provided for @coursesBatchNormal.
  ///
  /// In zh, this message translates to:
  /// **'正选'**
  String get coursesBatchNormal;

  /// No description provided for @coursesBatchSupplement.
  ///
  /// In zh, this message translates to:
  /// **'补退选'**
  String get coursesBatchSupplement;

  /// No description provided for @coursesAddTarget.
  ///
  /// In zh, this message translates to:
  /// **'添加目标'**
  String get coursesAddTarget;

  /// No description provided for @coursesTargetPriority.
  ///
  /// In zh, this message translates to:
  /// **'优先级'**
  String get coursesTargetPriority;

  /// No description provided for @grabberTitle.
  ///
  /// In zh, this message translates to:
  /// **'抢课'**
  String get grabberTitle;

  /// No description provided for @grabberStart.
  ///
  /// In zh, this message translates to:
  /// **'开始抢课'**
  String get grabberStart;

  /// No description provided for @grabberStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get grabberStop;

  /// No description provided for @grabberPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get grabberPause;

  /// No description provided for @grabberStateIdle.
  ///
  /// In zh, this message translates to:
  /// **'未运行'**
  String get grabberStateIdle;

  /// No description provided for @grabberStatePreparing.
  ///
  /// In zh, this message translates to:
  /// **'准备中'**
  String get grabberStatePreparing;

  /// No description provided for @grabberStateRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get grabberStateRunning;

  /// No description provided for @grabberStateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已成功'**
  String get grabberStateSuccess;

  /// No description provided for @grabberStatePaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get grabberStatePaused;

  /// No description provided for @grabberStateStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get grabberStateStopped;

  /// No description provided for @grabberStateInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'异常中断'**
  String get grabberStateInterrupted;

  /// No description provided for @grabberStateAuthExpired.
  ///
  /// In zh, this message translates to:
  /// **'授权失效'**
  String get grabberStateAuthExpired;

  /// No description provided for @grabberStateCaptcha.
  ///
  /// In zh, this message translates to:
  /// **'需要验证码'**
  String get grabberStateCaptcha;

  /// No description provided for @grabberStateFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get grabberStateFailed;

  /// No description provided for @grabberInterval.
  ///
  /// In zh, this message translates to:
  /// **'请求间隔'**
  String get grabberInterval;

  /// No description provided for @grabberIntervalMs.
  ///
  /// In zh, this message translates to:
  /// **'{ms} 毫秒'**
  String grabberIntervalMs(int ms);

  /// No description provided for @grabberBatchNotOpen.
  ///
  /// In zh, this message translates to:
  /// **'批次尚未开放，请等待开放后再启动'**
  String get grabberBatchNotOpen;

  /// No description provided for @grabberTimeout.
  ///
  /// In zh, this message translates to:
  /// **'任务已运行 30 分钟，已自动停止，请重新确认后启动'**
  String get grabberTimeout;

  /// No description provided for @grabberClockWarning.
  ///
  /// In zh, this message translates to:
  /// **'系统时钟偏差过大，请校准后重试'**
  String get grabberClockWarning;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSimple.
  ///
  /// In zh, this message translates to:
  /// **'简约'**
  String get settingsThemeSimple;

  /// No description provided for @settingsThemeAnime.
  ///
  /// In zh, this message translates to:
  /// **'二次元'**
  String get settingsThemeAnime;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsThemeSystem;

  /// No description provided for @settingsInterval.
  ///
  /// In zh, this message translates to:
  /// **'用户请求间隔'**
  String get settingsInterval;

  /// No description provided for @settingsLogLevel.
  ///
  /// In zh, this message translates to:
  /// **'日志级别'**
  String get settingsLogLevel;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'导出诊断包'**
  String get settingsDiagnostics;

  /// No description provided for @settingsDiagnosticsHint.
  ///
  /// In zh, this message translates to:
  /// **'导出前将强制脱敏，请导出后自行复核'**
  String get settingsDiagnosticsHint;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsUnbind.
  ///
  /// In zh, this message translates to:
  /// **'解绑设备'**
  String get settingsUnbind;

  /// No description provided for @settingsUnbindConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认解绑？解绑后 24 小时内无法绑定新设备。'**
  String get settingsUnbindConfirm;

  /// No description provided for @settingsUnbindCooldown.
  ///
  /// In zh, this message translates to:
  /// **'冷却中，{time} 后可重新绑定'**
  String settingsUnbindCooldown(String time);

  /// No description provided for @updateTitle.
  ///
  /// In zh, this message translates to:
  /// **'版本更新'**
  String get updateTitle;

  /// No description provided for @updateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateMandatory.
  ///
  /// In zh, this message translates to:
  /// **'此版本为强制更新'**
  String get updateMandatory;

  /// No description provided for @updateDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载更新'**
  String get updateDownload;

  /// No description provided for @updateVerifying.
  ///
  /// In zh, this message translates to:
  /// **'校验中...'**
  String get updateVerifying;

  /// No description provided for @updateVerifyFailed.
  ///
  /// In zh, this message translates to:
  /// **'文件校验失败，请重新下载'**
  String get updateVerifyFailed;

  /// No description provided for @updateInstall.
  ///
  /// In zh, this message translates to:
  /// **'安装更新'**
  String get updateInstall;

  /// No description provided for @maintenanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'系统维护中'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceMessage.
  ///
  /// In zh, this message translates to:
  /// **'系统正在维护，请稍后重试'**
  String get maintenanceMessage;

  /// No description provided for @versionTooLow.
  ///
  /// In zh, this message translates to:
  /// **'当前版本过低，请更新后继续使用'**
  String get versionTooLow;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败，请检查网络'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'请求超时，请稍后重试'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器错误，请稍后重试'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get errorUnknown;

  /// No description provided for @errorTokenInvalid.
  ///
  /// In zh, this message translates to:
  /// **'授权失效，请重新激活'**
  String get errorTokenInvalid;

  /// No description provided for @errorLicenseExpired.
  ///
  /// In zh, this message translates to:
  /// **'授权已过期'**
  String get errorLicenseExpired;

  /// No description provided for @errorDeviceLimit.
  ///
  /// In zh, this message translates to:
  /// **'激活码已绑定其他设备'**
  String get errorDeviceLimit;

  /// No description provided for @errorRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请稍后重试'**
  String get errorRateLimited;

  /// No description provided for @errorXkmsUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未识别的选课模式，请等待客户端升级'**
  String get errorXkmsUnknown;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
