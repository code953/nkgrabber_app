// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'NKgrabber';

  @override
  String get startupLoading => '正在加载...';

  @override
  String get activationTitle => '激活授权';

  @override
  String get activationHint => '请输入激活码';

  @override
  String get activationButton => '激活';

  @override
  String get activationSuccess => '激活成功';

  @override
  String get activationFormatError => '激活码格式错误，请输入 XXXX-XXXX-XXXX-XXXX 格式';

  @override
  String get consentTitle => '使用须知';

  @override
  String get consentCrashReportingDesc =>
      '为改进产品质量，本应用默认开启崩溃日志上报。上报内容仅包含脱敏堆栈信息、应用版本和平台信息，绝不包含您的账号、密码、Cookie、激活码或课程数据。';

  @override
  String get consentDisableOption => '始终关闭崩溃上报';

  @override
  String get consentAgree => '我已知悉，继续使用';

  @override
  String get navAccounts => '账号';

  @override
  String get navCourses => '课程';

  @override
  String get navGrabber => '抢课';

  @override
  String get navSettings => '设置';

  @override
  String get accountsTitle => '账号管理';

  @override
  String get accountsAdd => '添加账号';

  @override
  String get accountsAddPassword => '密码登录';

  @override
  String get accountsAddCookie => 'Cookie 登录';

  @override
  String get accountsSchoolId => '学号';

  @override
  String get accountsPassword => '密码';

  @override
  String get accountsCookie => 'gdpk Cookie';

  @override
  String get accountsRememberPassword => '记住密码';

  @override
  String accountsConfirmIdentity(String name, String lastFour) {
    return '确认身份：$name（$lastFour）';
  }

  @override
  String get accountStatusReady => '正常';

  @override
  String get accountStatusExpired => '会话过期';

  @override
  String get accountStatusCaptcha => '需要验证码';

  @override
  String get accountStatusNetwork => '网络错误';

  @override
  String get accountStatusDisabled => '超额停用';

  @override
  String get accountStatusValidating => '验证中';

  @override
  String get coursesTitle => '课程设置';

  @override
  String get coursesSelectAccount => '选择账号';

  @override
  String get coursesSelectBatch => '选择批次';

  @override
  String get coursesBatchGrab => '抢选';

  @override
  String get coursesBatchNormal => '正选';

  @override
  String get coursesBatchSupplement => '补退选';

  @override
  String get coursesAddTarget => '添加目标';

  @override
  String get coursesTargetPriority => '优先级';

  @override
  String get grabberTitle => '抢课';

  @override
  String get grabberStart => '开始抢课';

  @override
  String get grabberStop => '停止';

  @override
  String get grabberPause => '暂停';

  @override
  String get grabberStateIdle => '未运行';

  @override
  String get grabberStatePreparing => '准备中';

  @override
  String get grabberStateRunning => '运行中';

  @override
  String get grabberStateSuccess => '已成功';

  @override
  String get grabberStatePaused => '已暂停';

  @override
  String get grabberStateStopped => '已停止';

  @override
  String get grabberStateInterrupted => '异常中断';

  @override
  String get grabberStateAuthExpired => '授权失效';

  @override
  String get grabberStateCaptcha => '需要验证码';

  @override
  String get grabberStateFailed => '失败';

  @override
  String get grabberInterval => '请求间隔';

  @override
  String grabberIntervalMs(int ms) {
    return '$ms 毫秒';
  }

  @override
  String get grabberBatchNotOpen => '批次尚未开放，请等待开放后再启动';

  @override
  String get grabberTimeout => '任务已运行 30 分钟，已自动停止，请重新确认后启动';

  @override
  String get grabberClockWarning => '系统时钟偏差过大，请校准后重试';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSimple => '简约';

  @override
  String get settingsThemeAnime => '二次元';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsInterval => '用户请求间隔';

  @override
  String get settingsLogLevel => '日志级别';

  @override
  String get settingsDiagnostics => '导出诊断包';

  @override
  String get settingsDiagnosticsHint => '导出前将强制脱敏，请导出后自行复核';

  @override
  String get settingsCrashReporting => '崩溃日志上报';

  @override
  String get settingsCrashReportingDesc => '帮助我们改进产品质量';

  @override
  String get settingsCheckUpdate => '检查更新';

  @override
  String get settingsUnbind => '解绑设备';

  @override
  String get settingsUnbindConfirm => '确认解绑？解绑后 24 小时内无法绑定新设备。';

  @override
  String settingsUnbindCooldown(String time) {
    return '冷却中，$time 后可重新绑定';
  }

  @override
  String get updateTitle => '版本更新';

  @override
  String updateAvailable(String version) {
    return '发现新版本 $version';
  }

  @override
  String get updateMandatory => '此版本为强制更新';

  @override
  String get updateDownload => '下载更新';

  @override
  String get updateVerifying => '校验中...';

  @override
  String get updateVerifyFailed => '文件校验失败，请重新下载';

  @override
  String get updateInstall => '安装更新';

  @override
  String get maintenanceTitle => '系统维护中';

  @override
  String get maintenanceMessage => '系统正在维护，请稍后重试';

  @override
  String get versionTooLow => '当前版本过低，请更新后继续使用';

  @override
  String get errorNetwork => '网络连接失败，请检查网络';

  @override
  String get errorTimeout => '请求超时，请稍后重试';

  @override
  String get errorServer => '服务器错误，请稍后重试';

  @override
  String get errorUnknown => '未知错误';

  @override
  String get errorTokenInvalid => '授权失效，请重新激活';

  @override
  String get errorLicenseExpired => '授权已过期';

  @override
  String get errorDeviceLimit => '激活码已绑定其他设备';

  @override
  String get errorRateLimited => '请求过于频繁，请稍后重试';

  @override
  String get errorXkmsUnknown => '未识别的选课模式，请等待客户端升级';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';
}
