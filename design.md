# 抢课程序｜客户端独立设计文档

<aside>
🤖

本页是可独立交给 AI 进行 Vibe Coding 的客户端实现规格。实现时不得依赖父页面补充上下文；文中已包含技术选型、业务规则、服务端契约、学校接口适配、数据模型和验收标准。

</aside>

<aside>
📌

**文档结构**：§1–§3 边界与术语；§4 业务服务端契约；§5–§7 本地数据、账号与学校接口；§8–§9 课程目标与调度器；§10–§11 交互与发布；§12–§13 测试与验收；§14 交付物；§15 待决策项；附录 A 修订记录。所有变更集中记录在附录 A，正文不再散落变更说明。

</aside>

## 0. 阅读与实施顺序

AI 实现者建议按下列顺序落地，避免返工：

1. 通读全文并回填 §15 待决策项；未决项不得凭猜测编码。
2. 搭建工程骨架（§2）、CI 与签名占位（§11）。
3. 建立 Drift schema 与迁移（§5.1）、平台安全存储抽象（§5.2）。
4. 实现 `BackendApiClient` 与授权流程（§3–§4）。
5. 实现 `CampusAdapter` 与账号管理（§6–§7）。
6. 实现课程目标、调度器、状态机（§8–§9）。
7. 完成 UI、更新、验收测试（§10、§12–§13）。

## 1. 产品目标与边界

使用 Flutter 开发 Android、Windows、Linux、macOS、iOS 五端统一客户端，提供授权校验、账号管理、课程目标设置、受控请求调度、版本更新和本地数据管理。

### 1.1 目标用户与使用场景

- 高校在读学生本人，具备合法选课资格且熟悉本校选课流程。
- 用户自行准备学校账号密码或 `gdpk` Cookie；产品不提供账号获取渠道，也不提供代抢或代人操作。
- 主要使用场景：抢课开放前提前配置目标，开放后由本客户端在授权额度内自动定时提交。

### 1.2 非目标（Non-Goals）

- 不做班级、代抢、账号池等多用户代理场景。
- 不提供应用内支付；激活码通过运营渠道单独发放与管理。
- 不接管学校验证码识别、风控破解或短信验证。
- 不引入社交、推荐、广告或第三方 SDK 型行为分析。
- 不为学校返回结果背书，最终以学校系统为准。

### 1.3 强制边界

- 客户端直接访问学校系统 `http://campus.nks.edu.cn`；业务服务端不代理学校登录、查询或提交请求。
- 学校账号、密码、`JSESSIONID`、`gdpk` Cookie 只允许保存在用户设备，禁止上传业务服务端。
- 不绕过验证码、风控、身份认证或学校访问限制；遇到验证码或风控立即暂停。
- 不保证选课成功，学校返回结果为最终依据。
- 不提供离线抢课：业务授权无法在线校验时不得启动或继续任务。
- 任务异常退出后不自动恢复，必须由用户重新确认并启动。

## 2. 固定技术栈

- Flutter + Dart，五端同一版本周期发布。
- 状态管理：Riverpod。
- 本地数据库：SQLite + Drift，必须使用迁移管理 schema 版本。
- 分层：`presentation → application → domain → infrastructure`。
- 学校请求与业务服务端请求必须使用两个完全隔离的 HTTP Client 和 Cookie Jar。

### 2.1 推荐目录

```
lib/
├─ app/                    # 启动、主题、路由、全局 Provider
├─ core/
│  ├─ errors/             # AppException 与错误映射
│  ├─ logging/            # 脱敏日志
│  ├─ network/            # BackendApiClient 基础设施
│  ├─ security/           # 平台安全存储
│  └─ utils/
├─ features/
│  ├─ license/
│  ├─ accounts/
│  ├─ courses/
│  ├─ grabber/
│  ├─ settings/
│  └─ updater/
├─ infrastructure/
│  ├─ database/           # Drift 表、DAO、迁移
│  ├─ campus/             # CampusAdapter 实现
│  └─ backend/            # 服务端 DTO 与 Repository
└─ main.dart
```

### 2.2 工具链与最低平台版本

- Flutter Stable（`>=3.24`）、Dart（`>=3.5`）；精确版本锁定在仓库 `.tool-versions` 与 CI 中。
- Android：`minSdk 24`，`targetSdk` 与 CI 编译版本保持一致；架构 `arm64-v8a`、`armeabi-v7a`、`x86_64`。
- iOS：`iOS 14+`。
- macOS：`macOS 12+`，Apple Silicon 与 Intel 双架构 (`universal`)。
- Windows：`Windows 10 20H2+`，仅 `x64`。
- Linux：`glibc >= 2.31`（Ubuntu 20.04+），仅 `x64`，需系统提供 Secret Service。

### 2.3 横切关注点

- **国际化**：默认简体中文；使用 Flutter i18n 抽出全部字符串并预留英文 arb 文件，英文本身不列入首版验收。
- **可访问性**：颜色对比度符合 WCAG AA；关键按钮提供屏幕阅读器语义标签。
- **系统代理**：桌面端跟随系统代理（`HTTPS_PROXY`/`ALL_PROXY` 或 OS 代理），移动端跟随系统 Wi-Fi/VPN；首版不实现应用内代理表单。
- **崩溃/诊断上报**：崩溃日志**默认开启（opt-out）**，设置页可关闭（对应 §15 D-10）；开启时使用 `POST /api/v1/telemetry/crash` 上报脱敏堆栈、平台、应用版本与 `installId` 哈希，绝不上报账号、Cookie、令牌、激活码、学号姓名或课程数据。除崩溃上报外，默认关闭一切其他远程遥测。
- **时钟依赖**：所有过期、间隔、冷却均以稳定时钟源为准（见 §7.3）。
- **多实例**：桌面端使用单实例锁，检测到已运行则激活现有窗口；移动端天然单实例。

## 3. 核心术语与权益

| 术语 | 定义 |
| --- | --- |
| `installId` | 首次启动生成并持久化的 UUID，不使用 IMEI、MAC 等硬件标识 |
| `deviceToken` | 激活后服务端签发的设备授权令牌，保存于安全存储 |
| 档次 Plan | 包含账号上限、最小请求间隔、最大并发账号数和授权有效天数 |
| `xkid` | 学校选课批次 ID |
| `xbkid` | 学校限选块 ID，既用于展示也用于提交（见 §7.1） |
| `kmh` | 提交选课时使用的课目号；本部署实测等于 `xbkid` |

固定授权规则：

- 每个激活码只能绑定 1 台设备。
- 用户可自助解绑；成功解绑后 24 小时才能绑定新设备。
- 授权期限从首次激活开始，`expiresAt = activatedAt + plan.licenseDurationDays`。
- 未激活用户最多添加 1 个账号，但不能启动抢课。
- 权益降低导致账号超限时，按 `createdAt` 从新到旧停用超额账号；删除其他账号释放名额后，按创建时间从早到晚恢复。

## 4. 业务服务端 API 契约

### 4.1 基础约定

- Base URL：`https://nkgrabber.code953.top`
- 前缀：`/api/v1`
- JSON 编码：UTF-8；时间：ISO 8601 UTC。
- 每次请求发送：`X-Request-Id`（客户端生成的 ULID，用于日志排查与幂等去重）、`X-App-Version`、`X-Platform`、`X-Install-Id`。
- 需授权接口发送：`Authorization: Bearer <deviceToken>`。
- 请求默认超时：连接 5 s、读取 10 s；对 `POST /licenses/*` 允许一次自动重试，同一 `X-Request-Id` 视为幂等。
- 客户端与服务端时钟偏差以响应 `serverTime` 为准，本地维护滚动平均 `serverClockOffsetMs`，用于展示到期时间与冷却倒计时。当 `|offset| > 10 分钟` 时禁止启动抢课，改为提示用户校准系统时间。

统一响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "ok",
  "requestId": "01J...",
  "serverTime": "2026-07-21T05:00:00Z",
  "data": {}
}
```

失败时 `success=false`，客户端同时判断 HTTP 状态与 `code`。

### 4.2 错误码行为

| HTTP | `code` | 客户端行为 |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | 显示字段错误，不重试 |
| 401 | `TOKEN_INVALID` | 清除令牌，进入重新激活流程 |
| 403 | `LICENSE_INACTIVE` / `LICENSE_EXPIRED` | 停止任务并禁用抢课 |
| 403 | `DEVICE_LIMIT_REACHED` | 提示激活码已绑定其他设备 |
| 409 | `UNBIND_COOLDOWN_ACTIVE` | 显示 `data.availableAt`，不重试 |
| 429 | `RATE_LIMITED` | 按 `Retry-After` 等待 |
| 500 | `INTERNAL_ERROR` | 有限次数指数退避 |
| 503 | `SERVICE_UNAVAILABLE` | 停止受限功能并提示联网重试 |

### 4.3 激活

`POST /api/v1/licenses/activate`

```json
{
  "licenseCode": "XXXX-XXXX-XXXX-XXXX",
  "installId": "UUID",
  "deviceName": "953-PC",
  "platform": "windows",
  "appVersion": "1.0.0"
}
```

成功 `data`：

```json
{
  "deviceToken": "token",
  "license": {
    "status": "active",
    "activatedAt": "2026-07-21T05:00:00Z",
    "expiresAt": "2027-07-21T05:00:00Z",
    "plan": {
      "id": "pro",
      "name": "Pro",
      "maxAccounts": 5,
      "minRequestIntervalMs": 1000,
      "maxConcurrentAccounts": 3,
      "licenseDurationDays": 365,
      "maxDevices": 1,
      "unbindCooldownHours": 24
    }
  }
}
```

### 4.4 在线校验

`POST /api/v1/licenses/validate`

```json
{ "installId": "UUID", "appVersion": "1.0.0" }
```

返回最新 `license` 与 `plan`，可包含轮换后的 `deviceToken`。调用时机：应用启动、开始任务前、长任务期间定时。任何在线校验失败都不能使用本地快照放行抢课。

### 4.5 自助解绑

`POST /api/v1/licenses/deactivate`

```json
{ "installId": "UUID" }
```

成功后删除本地设备令牌和授权快照，不删除学校账号。重新绑定处于冷却期时展示服务端返回的 `availableAt`。

### 4.6 公共配置

`GET /api/v1/app/config?platform=windows&appVersion=1.0.0`

```json
{
  "success": true,
  "code": "OK",
  "message": "ok",
  "requestId": "01J...",
  "serverTime": "2026-07-21T05:00:00Z",
  "data": {
    "maintenance": false,
    "maintenanceMessage": null,
    "minimumSupportedVersion": "1.0.0",
    "supportUrl": null
  }
}
```

请求限制只来源于档次：`effectiveIntervalMs = max(userIntervalMs, plan.minRequestIntervalMs)`；最大并发账号数为 `plan.maxConcurrentAccounts`，不存在额外全局硬下限。

### 4.7 检查更新

`GET /api/v1/app/releases/latest?platform=windows&arch=x64&currentVersion=1.0.0&channel=stable`

```json
{
  "success": true,
  "code": "OK",
  "message": "ok",
  "requestId": "01J...",
  "serverTime": "2026-07-21T05:00:00Z",
  "data": {
    "version": "1.1.0",
    "mandatory": false,
    "publishedAt": "2026-07-20T00:00:00Z",
    "releaseNotes": "更新说明",
    "downloadUrl": "https://openlist.example.com/...",
    "sha256": "64位十六进制摘要",
    "signature": "Base64编码的Ed25519签名"
  }
}
```

无更新返回 HTTP 200 和 `data: null`。第一版只展示 Stable；内部 DTO 保留 `channel`。下载后必须先校验 SHA-256，再使用客户端内置 Ed25519 公钥验证发布清单签名，最后验证平台原生签名。

## 5. 本地数据与安全存储

### 5.1 Drift 实体

所有主键使用 `TEXT`（UUID v4），时间使用 `TEXT` 存 ISO 8601 UTC，布尔使用 `INTEGER 0/1`；数值区间在应用层校验。

```
Account
- id              TEXT    PK
- displayName     TEXT    NOT NULL           # "姓名（学号后四位）"
- studentNo       TEXT    NOT NULL
- loginType       TEXT    NOT NULL CHECK IN ('password','cookie')
- credentialRef   TEXT    NULL               # 平台安全存储引用 ID
- cookieJarRef    TEXT    NOT NULL           # 独立 Cookie Jar 引用
- status          TEXT    NOT NULL           # validating|ready|expired|captchaRequired|networkError|disabledByPlan
- lastValidatedAt TEXT    NULL
- ephemeral       INTEGER NOT NULL DEFAULT 0
- enabled         INTEGER NOT NULL DEFAULT 1
- disabledReason  TEXT    NULL
- createdAt       TEXT    NOT NULL
- updatedAt       TEXT    NOT NULL

CourseTarget
- id           TEXT    PK
- accountId    TEXT    NOT NULL FK Account.id ON DELETE CASCADE
- xkid         TEXT    NOT NULL
- xkms         TEXT    NOT NULL              # 批次模式，提交时原样带回
- kmh          TEXT    NOT NULL              # 提交用课目号（本部署实测 == xbkid）
- xbkid        TEXT    NULL                  # 限选块 ID
- batchName    TEXT    NOT NULL              # 快照
- courseName   TEXT    NOT NULL              # 快照
- priority     INTEGER NOT NULL DEFAULT 0    # 数值越小越优先
- enabled      INTEGER NOT NULL DEFAULT 1
- snapshotAt   TEXT    NOT NULL

GrabTask
- id                  TEXT    PK
- accountId           TEXT    NOT NULL FK Account.id ON DELETE CASCADE
- targetIdsJson       TEXT    NOT NULL       # JSON 数组，保存 CourseTarget.id
- status              TEXT    NOT NULL       # idle|preparing|running|paused|stopped|success|failed|interrupted|authExpired|captchaRequired
- effectiveIntervalMs INTEGER NOT NULL
- startedAt           TEXT    NULL
- stoppedAt           TEXT    NULL
- lastResultJson      TEXT    NULL           # 脱敏后的最近一次结果快照

LicenseSnapshot (单行)
- planId                TEXT    NOT NULL
- planName              TEXT    NOT NULL
- maxAccounts           INTEGER NOT NULL
- minRequestIntervalMs  INTEGER NOT NULL
- maxConcurrentAccounts INTEGER NOT NULL
- licenseDurationDays   INTEGER NOT NULL
- expiresAt             TEXT    NOT NULL
- validatedAt           TEXT    NOT NULL
- maxDevices            INTEGER NOT NULL DEFAULT 1
- unbindCooldownHours   INTEGER NOT NULL DEFAULT 24
# LicenseSnapshot 仅用于 UI 显示和检测本地过期；抢课前必须完成一次成功的在线校验（§4.4）。

AppSettings (单行)
- theme          TEXT    NOT NULL DEFAULT 'system'   # simple|anime|system
- userIntervalMs INTEGER NOT NULL DEFAULT 1000
- updateChannel  TEXT    NOT NULL DEFAULT 'stable'
- logLevel       TEXT    NOT NULL DEFAULT 'info'     # debug|info|warn|error
- locale         TEXT    NOT NULL DEFAULT 'zh_CN'
```

索引建议：`CourseTarget(accountId, xkid)`、`GrabTask(accountId, status)`。级联删除仅对 `CourseTarget`、`GrabTask` 生效；`LicenseSnapshot` 与 `AppSettings` 是单行表。

### 5.2 敏感信息

- 密码、Cookie、`deviceToken` 只存平台安全存储；Drift 中只存引用。
- 允许“记住密码”，不要求本地主密码。
- Android 使用 Keystore，iOS/macOS 使用 Keychain，Windows 使用 Credential Manager/DPAPI，Linux 使用 Secret Service。
- Linux 没有可用系统密钥环时禁用“记住密码”，不得降级为明文、配置文件或可逆本地加密。
- 日志不得出现完整密码、Cookie、激活码或令牌。

## 6. 账号管理

### 6.1 账号密码模式

1. 请求学校登录页并动态提取 RSA `pubKey` 和 `kid`。
2. 仅在内存中使用明文密码，使用学校公钥加密后提交。
3. 跟随 SSO 跳转取得 `gdpk`。
4. 查询学号和姓名，展示给用户确认。
5. 用户选择记住密码时写入系统安全存储；否则只保存当前会话。
6. 每次启动可使用已保存凭证刷新 Cookie；刷新最多自动尝试一次。

### 6.2 Cookie 模式

- 用户输入 `gdpk`，客户端查询身份后要求确认。
- 该账号 `ephemeral=true`，应用正常退出时删除账号记录和 Cookie。
- Cookie 失效时提示用户重新输入，不尝试使用其他账号 Cookie。

### 6.3 账号状态

`validating`、`ready`、`expired`、`captchaRequired`、`networkError`、`disabledByPlan`。

展示名称采用“姓名（学号后四位）”，数据库和业务逻辑使用本地 UUID，不能以姓名作为唯一键。

## 7. 学校系统 CampusAdapter

```dart
abstract interface class CampusAdapter {
  Future<LoginResult> loginWithPassword(String account, Secret password);
  Future<StudentProfile> validateCookie(String gdpk);
  Future<List<SelectionBatch>> listBatches(Session session);
  Future<List<Course>> listCourses(Session session, String xkid);
  Future<List<SelectionRecord>> listSelections(Session session, String xkid);
  Future<SubmitResult> submit(Session session, SubmitSelection command);
  Future<WithdrawResult> withdraw(Session session, String xkid);
}
```

### 7.1 上游接口映射

下表已按 campus.nks.edu.cn 实测校正。**实测结论优先于本节的历史描述** —— 凡与实际响应冲突之处，以代码与 `test/campus_parsing_test.dart` 中的逐字 fixture 为准。

| 能力 | 接口 | 关键数据 |
| --- | --- | --- |
| 获取登录参数 | `GET /zhxy/welcome` | HTML 隐藏 input 中的 `pubKey`、`kid`（**不是** JS 变量） |
| 密码登录 | `POST /zhxy/rrtlogin/loginWithYzm.jsmeb` | 请求体是 **JSON** `{"params":[账号,RSA密码,验证码,kid]}`，Content-Type 仍写 form-encoded |
| 门户会话 | `GET /zhxy` | HTML 中的 `mycenter_token`、`mycenter_userid` |
| 应用注册表 | `POST /zhxy/app/getAllAppsByUser.jsmeb` | `appurl`（含各校独立 `ssoappid`）、`apiurl`、`ssolx` |
| 换取选课会话 | 门户 SSO，`ssolx=5` | `{origin}{appurl}[&\|?]token=…&apiUrl=…&userid=…` → `gdpk` |
| 批次列表 | `POST /njs_3033/xsxk/getStudentXkList` | `xkid`, `xkms`, `zdxk`, `mc`, `kssj`, `jssj`, `xsid` |
| 课程列表 | `POST /njs_3033/xsxk_Xbk/getXbkByXkid` | `result.xbkList[]`：`xbkid`, `xbkmc`, `jsxm`, `rsyq`, `yxrs`, `syme`, `xbkxf` |
| 批次/名额 | `POST /njs_3033/xsxk_Xbk/getXbkXkqkAndXsXkqk` | `setzrs`, `setyxzrs`, `setwxzrs` |
| 已选记录 | `POST /njs_3033/xsxk_Xbk/getStudentXkJlList` | `kmh`, `kmmc`, `xm`；用于启动前幂等判断 |
| 正式提交 | `POST /njs_3033/xsxk_Xbk/saveStudentXkJs` | `xkid`, `xkms`, `sftj=1`, `kms`, `kmhDtoList`（JSON 数组 `[{"kmh":"…"}]`） |
| 撤回 | `POST /njs_3033/xsxk_Xbk/xschXbkxkCz` | `xkid` |

关于 SSO：登录门户**不足以**进入选课应用，裸 `GET /njs_3033/xsxk2` 返回 403。该应用注册为 `ssolx=5`，必须把 `token`、`apiUrl`、`userid` 三个参数穿过跳转，选课主机才会下发 `gdpk`。`appurl` 携带各部署独立的 `ssoappid`，只能运行时读注册表。遇到其他 `ssolx` 取值时抛出可读错误，不猜 URL。

**SSO 跳转必须逐跳手动跟随。** 实测链路为 `xsxk2` →(302，下发 `gdpk`) `loginRedirect` →(302) `xsxk2`，`gdpk` 只在第 0 跳下发。dio 的 `followRedirects` 在 HTTP adapter 内实现，位于拦截器链**下方**，CookieManager 看不到中间响应，`gdpk` 从未进入 jar，末跳空 cookie 抵达被拒 403。因此 `_followSsoRedirects` 关闭自动跟随、逐跳请求，使每个响应都经过拦截器。

**门户会发畸形 Set-Cookie。** 每个登录后响应都多带一行裸的 `Set-Cookie: HttpOnly=`（本意是给 `JSESSIONID` 追加 `HttpOnly` 属性，写成了独立 header）。`dart:io` 拒绝解析，而 `CookieManager` 用 `.toList()` 强制求值整条链，一处抛异常会连带丢弃**同一响应里合法的 `JSESSIONID`**，表现为 `DioException [unknown]: null`。故必须启用 `ignoreInvalidCookies: true`（`dio_cookie_manager >= 3.4.0`），只跳过坏片段 —— 这也是浏览器的行为。

关于课程列表：上游行**不携带 `kmh`**，只有 `xbkid`；学校自己的页面也是拿 `xbkid` 提交。已实测确认一条已选记录的 `kmh` 与 `xbkList` 中某行的 `xbkid` 完全一致，故本客户端以 `xbkid` 作为提交 ID。

**提交路径未经实测**：本部署唯一批次已于 2026-04-18 结束，实际提交会改动真实学生的选课记录。`kmhDtoList` 的形状取自页面脚本 `saveStudentXkJs({…, kmhDtoList: JSON.stringify([{kmh: …}])})`，代码中已标注 UNVERIFIED。

### 7.2 编解码和判定

- 上游为明文 HTTP。**本部署实测为 UTF-8**；`decodeGbk` 先尝试严格 UTF-8 解码，失败才回落 GB18030，因此两种编码都能处理。
- 请求体：选课侧接口用 `application/x-www-form-urlencoded`；门户侧 `.jsmeb` 接口的 Content-Type 也写 form-encoded，但**实际内容是 JSON**（学校自己的脚本即如此，真正 form-encoded 的 `params=[...]` 会被拒为「参数格式非法」）。
- 每个账号使用独立 Cookie Jar，禁止跨账号复用。
- `kms` 必须等于 `kmhDtoList.length`，且不超过批次 `zdxk`。
- HTTP 200 不代表成功。响应统一为 `{"result": …, "status": 200}` 或 `{"error":{"code","message"}}`：
    - `status` 是 **HTTP 风格的整数**（200），不是布尔值 —— `status == true` 永远不成立。
    - 负载在 `result` 下，**从来不在 `data` 下**。
    - 缺少 `result` 字段是「响应看不懂」；`result` 为 `null` 是「确实没有数据」。二者不可混为一谈。
    - `error.code == -32604`、`status` 401/601 → 会话失效；`status` 602 → 服务器繁忙（取自学校 `ajaxRequest` 包装器的处理）。
    - 命令类接口另有 `result.code`，`"0"` 为成功，其余配 `result.msg`。
    - 同一字段在不同接口类型不一致（`zdxk` 是字符串 `"2"`，`xkms` 是数字 `0`），必须经 `campusInt`/`campusString` 归一化。
- 解包逻辑集中在 `lib/infrastructure/campus/campus_envelope.dart`，不在各调用点重复。
- 所有路径、字段解析和错误映射集中在适配器，不允许 UI 引用学校接口字符串。

### 7.3 时间同步策略

- 抢课关键时刻是批次开放时间 `kssj` 与结束时间 `jssj`（来自 `getStudentXkList`）。
- 使用学校最近一次响应的 `Date` HTTP 头计算 `campusClockOffsetMs`，与业务服务端 `serverTime` 相互印证。
- 若两者偏差 `> 60 s`，警告用户并暂停调度；`≤ 60 s` 时以学校 `Date` 头为准。
- 批次开放前**不发起任何抢课相关请求**，也不做预热（对应 §15 D-03）；用户需在批次开放后手动点击"开始抢课"才进入调度。若 `now < kssj`，`start` 操作直接拒绝并提示等待。

### 7.4 网络与 Cookie 隔离

- 每个学校账号：独立 `Dio` 实例 + 独立内存 Cookie Jar，Cookie 不落盘。
- 业务服务端使用另一个 `Dio` 实例，只发送业务凭证，禁止携带学校 Cookie。
- 严禁在同一账号并发发起多个学校请求；账号内部使用队列串行执行。

### 7.5 批次字段处理（对应 D-11：xkms 稳定 / zdxk 可变）

根据 D-11 最终结论：`xkms` 采用**固定枚举**方案，`zdxk` 采用**每批次实时读取**方案。

- **`xkms`（选课模式）** — 客户端把取值固化为下列枚举，提交时原样带回 `saveStudentXkJs`；分类逻辑集中在 `lib/infrastructure/campus/xkms_enum.dart`：
    - `"1"` = 抢选
    - `"2"` = 正选
    - `"3"` = 补退选
    - `"0"` = **选课已结束**（实测：本部署唯一批次即报 `xkms=0`）
    
    `"0"` 是学校的一个真实终态，**不是解析失败**。把它当作「无法识别」并提示等待客户端升级，会让用户去追一个根本不存在的客户端 bug —— 批次只是结束了。因此不可提交的原因分两类：
    
    - **已结束**（`"0"`）→ 提示「该批次选课已结束」，批次选择器直接禁用该批次。
    - **确实未知**（枚举外的其他取值）→ 目标置 `failed`，提示「无法识别的选课模式，请等待客户端升级」。
    
    两种情况都**不做保守默认提交**，以避免向学校发送意义不确定的请求。学校若新增批次场景（如"预选"），必须发布带新枚举项的新版客户端。
    
- **`zdxk`（每次最多提交条数）** — 每次进入 `running` 前必须重新调用 `getStudentXkList` 读取最新值，**不缓存跨批次**。调度器在拼装 `kmhDtoList` 时严格校验 `kms == kmhDtoList.length ≤ zdxk`；若目标总数超过当前 `zdxk`，自动拆分成多轮提交（见 §9.5）。
- **不引入远程覆盖目录**：不新增 `AppSettings.campusOverrideUrl`，不实现 `assets/campus/xkms-catalog.json` 加载或校验逻辑，相关代码路径一律不落地。

## 8. 课程设置

- 先选账号，再读取批次、课程、名额和已选记录。
- 保存目标必须包含：`accountId`、`xkid`、`xkms`、`kmh`、`xbkid?`、课程名、批次名、`snapshotAt`。
- UI 明确区分展示 ID `xbkid` 与提交 ID `kmh`。
- 每个账号可设置多个目标与优先级；同批次提交数量不超过 `zdxk`。
- 启动任务前刷新批次和课程标识，禁止盲目使用陈旧快照。

## 9. 抢课调度器

### 9.1 状态机

```
idle → preparing → running → success
                  ↘ paused
                  ↘ stopped
                  ↘ interrupted
                  ↘ authExpired
                  ↘ captchaRequired
                  ↘ failed
```

### 9.2 并发、间隔与时长

- 单个账号内部严格串行。
- 多账号最多并行 `plan.maxConcurrentAccounts` 个。
- `effectiveIntervalMs = max(userIntervalMs, plan.minRequestIntervalMs)`。
- 同一目标任一时刻最多存在一个执行实例。
- **单次任务最大连续运行时长 30 分钟**（对应 §15 D-13）：到时后调度器自动停止，任务置 `stopped` 并要求用户重新确认才能再次启动；不与 `jssj` 自动挂钩，避免长跑影响系统稳定与账号安全。

### 9.3 执行流程

1. **授权检查**：调用 `POST /licenses/validate`；失败进入 `authExpired`。
2. **前置校验**：批次时间窗口、目标完整性（`kmh`、`xkid`、`xkms` 非空）、账号状态为 `ready`；任一不通过进入 `failed`。
3. **幂等检查**：调用 `getStudentXkJlList` 查询已选记录；对每个目标匹配 `kmh`，命中则该目标直接置 `success` 且不进入运行队列。
4. **无预热**：抢课需用户手动触发；调度器不做批次开放前的连接建立、Cookie 刷新或空请求（对应 §15 D-03）。若 `now < kssj`，`start` 操作直接拒绝并提示用户等待批次开放。
5. **提交循环**：进入 `running`，按 `effectiveIntervalMs` 直接提交 `saveStudentXkJs`；不逐轮查名额；每一轮请求必须满足 `kms == kmhDtoList.length` 且 `kms ≤ zdxk`。
6. **单目标成功**：立即从该账号的待办队列移除对应目标，剩余目标继续。
7. **全部目标结束**：账号任务置 `success`（至少一个成功）或 `failed`（全部失败），保存脱敏回执。
8. **用户停止**：立即取消待执行调度；正在进行的 HTTP 请求完成后按正常结果记录，最终置 `stopped`。
9. **进程异常退出**：下次启动时将 `running`/`preparing` 状态的 `GrabTask` 置为 `interrupted`，仅展示给用户，绝不自动恢复。

### 9.4 重试分类

- 网络超时、连接重置、学校 5xx：指数退避并加入小幅随机抖动，且不得小于有效间隔。
- 参数错误、批次关闭、达到上限、课程冲突：不重试。
- Cookie 过期：密码模式刷新一次；Cookie 模式要求重新输入。
- 验证码或风控：立即暂停，不自动处理或绕过。
- 业务服务端授权校验失败：安全停止全部任务。

### 9.5 目标优先级与冲突

- 同账号多目标按 `priority` 升序排队；同 `priority` 目标按 `createdAt` 先到先提交。
- 单次 `saveStudentXkJs` 的 `kmhDtoList` 条数不得超过 `zdxk`，超出必须拆分成多轮。
- 学校返回"课程冲突""容量已满""不在选课时段"等业务失败码时，将该目标置为 `failed` 并保留原文；不自动切换到用户未指定的替代目标。
- 首版不支持"备选目标"链；如需该能力应在 §15 待决策项（D-04）确认后再实现。

### 9.6 观测与诊断

- 每次提交请求记录：`accountId`（脱敏为学号后四位）、`xkid`、`kmh`、`durationMs`、`resultCode`、`retryCount`。
- 保留最近 3 次任务运行日志与最近 200 条请求条目，超出滚动清理。
- 用户可从"设置 → 导出诊断包"生成 zip；导出前强制脱敏并再次提示用户复核。

## 10. 页面与交互

### 10.0 启动与首次运行

1. 启动 splash：加载本地设置 → 检查系统时钟 → 读取 `LicenseSnapshot`。
2. 判断是否首次运行：无 `installId` 时生成并持久化 UUID，写入平台安全存储。
3. 并行拉取 `GET /app/config`（含 `maintenance`）与 `GET /app/releases/latest`；均使用系统代理，超时 10 s 后允许离线进入（抢课仍禁用）。
4. 若 `maintenance=true` 或 `minimumSupportedVersion` 高于当前版本，进入拦截页面，仅允许查看提示、退出或跳转支持链接。
5. 无有效授权则跳转激活页；已授权则跳转主界面。

### 10.1 页面清单

1. **启动/授权页**：公共配置、版本检查、激活、授权状态、解绑与冷却时间。
2. **账号管理**：添加密码账号、添加临时 Cookie、刷新、删除、超限停用说明。
3. **课程设置**：账号、批次、课程、目标、优先级、快照时间。
4. **抢课页**：任务状态、实际间隔、并发数、最近结果、开始/停止。
5. **设置页**：主题（简约 / 二次元 / 跟随系统，**不支持自定义主题包**，对应 D-09）、用户间隔、日志级别、导出诊断包（明文 zip，对应 D-07）、"检查更新"按钮（D-08）、崩溃上报开关（默认开启，D-10）、数据清理与账号解绑。
6. **更新页**：版本、说明、是否强更、下载进度、SHA-256 与 Ed25519 校验结果。
7. **首次运行同意页**：告知崩溃日志默认开启并列出脱敏范围，提供"始终关闭"入口后再进入主界面（D-10）。

## 11. 更新、发布与 CI

- 第一版仅 Stable，不在 UI 中提供 Beta 切换。
- GitHub Actions 对五端执行格式检查、静态分析、测试、构建、摘要计算和 Ed25519 签名，并创建 GitHub Release。
- 生产下载使用 OpenList HTTPS 直链。

### 11.1 各平台产物（D-01、D-02）

- **Android**：`arm64-v8a`、`armeabi-v7a`、`x86_64` 三份 APK；首版不上架 Play Store。
- **Windows**：`x64` 便携版 zip + NSIS 安装包。
- **macOS**：Universal `.dmg` + notarization。
- **Linux**：`AppImage` 与 `deb`（仅 `x64`）；不提供 Snap/Flatpak/rpm。
- **iOS**：保留构建流水线与签名步骤，但首版**不上架、不企业签名、不侧载**，仅供开发者本机调试与后续预留；管理后台 `releases` 表暂不登记 iOS 记录，`GET /app/releases/latest?platform=ios` 返回 `data: null`。

### 11.2 崩溃与诊断上报（D-10）

- **默认开启（opt-out）**：首次运行需要用户在"首次运行同意页"看到脱敏说明才能进入主界面；随时可在设置页关闭，关闭后立即停止上报并清空待发队列。
- 只上报：`installId` 哈希、`appVersion`、`platform`、`arch`、`locale`、崩溃类型、脱敏堆栈（保留文件名/行号）、发生时间、少量上下文标签。
- **绝不上报**：账号、密码、Cookie、`deviceToken`、激活码、学号姓名、课程 ID/名、请求体、日志正文。
- 客户端接口：`POST /api/v1/telemetry/crash`，无需授权令牌；使用 `X-Install-Id` 关联去重。
- 失败时最多重试 3 次并放弃；不阻塞用户操作，不常驻后台服务；关闭状态下不产生任何网络请求。

### 11.3 更新检查策略（D-08）

- 触发时机：应用启动时自动检查一次；设置页提供"检查更新"按钮手动触发。不做定时轮询。
- 强更版本在启动检查命中时立即拦截主界面，只能升级或退出。

## 12. 测试要求

- Domain：权益、账号超限、间隔计算、状态机、重试分类单元测试。
- Drift：迁移、DAO、级联删除和敏感字段缺失测试。
- Backend API：固定请求/响应契约和错误码测试。
- CampusAdapter：使用脱敏 fixture 测试编码、HTML 提取、Cookie、响应信封、SSO URL 拼装、`xkms` 分类、成功/失败响应。fixture 必须是**真实响应的逐字摘录**（敏感值替换为结构相同的占位符）—— 手写的近似 fixture 正是当初让这批缺陷溜过去的原因。见 `test/campus_parsing_test.dart`。
- 调度器：Fake Clock 测试间隔、停止、并发、异常退出、授权失效。
- 五端至少完成启动、激活、更新、账号隔离和安全存储冒烟测试。

## 13. 验收标准

### 13.1 功能与安全

- 任意账号的 Cookie 不会被另一个账号使用（可通过日志中的 Cookie Jar 引用抽查确认）。
- 未激活或在线校验失败时无法启动抢课（UI 按钮禁用 + 后台守卫双重拦截）。
- 账号超限时只停用最新添加项，不删除数据；释放名额后按 `createdAt` 从早到晚自动恢复。
- 实际请求间隔永远 `>= plan.minRequestIntervalMs`，抖动仅上浮不下浮。
- `kms == kmhDtoList.length` 且 `kms <= zdxk`；同一目标成功后不再重复提交。
- 停止后不产生新请求，异常退出后不自动恢复；对应任务显示为 `interrupted`。
- 日志、诊断包和错误上报中不含完整密码、Cookie、激活码或令牌。
- 更新包 SHA-256、Ed25519 签名与平台原生签名三项校验全部成功后才允许安装；任一失败即中止并提示。

### 13.2 可观测指标（首版可在诊断包中验证）

- 单账号一次提交端到端耗时（含加密与网络）P95 `< 800 ms`。
- 首次冷启动到主界面 P95 `< 3 s`（桌面端）、`< 4 s`（移动端）。
- 稳态内存：3 账号并发运行时 `< 400 MB`（桌面端）。
- 应用崩溃在 30 分钟冒烟测试内为 0。

## 14. AI 实现交付物

交付代码时必须包含：

1. 可运行的五端 Flutter 工程和 README。
2. Drift schema、迁移和 DAO。
3. Riverpod Provider/Notifier 与状态机。
4. `BackendApiClient`、完整 DTO 和错误映射。
5. `CampusAdapter` 接口、实现及脱敏 fixture 测试。
6. 调度器、取消机制、Fake Clock 测试。
7. 平台安全存储封装和日志脱敏。
8. GitHub Actions 五端构建、摘要与签名工作流。
9. `.env.example`，不得包含真实密钥或账号。
10. 运行、测试、构建、签名和发布说明。

## 15. 决策状态（Decisions）

2026-07-23 确认：**D-01–D-14 全部定稿**，无待决项。

### 15.1 定稿结论

| 编号 | 议题 | 结论 | 落地位置 |
| --- | --- | --- | --- |
| D-01 | iOS 分发渠道 | 保留 iOS 适配与构建，首版**不做任何分发**（不上架、不企业签名、不侧载） | §11.1；服务端 `releases` 表暂不登记 iOS |
| D-02 | Linux 安装包格式 | `AppImage`  • `deb`（仅 x64） | §11.1 |
| D-03 | 批次开放前的预热策略 | **不预热**；用户手动点击"开始抢课"后直接进入提交循环 | §7.3、§9.3 步骤 4 |
| D-04 | 目标失败后的备选目标链 | 首版不支持 | §9.5 |
| D-05 | 激活码格式 | 纯字母数字，正则 `^[A-Z0-9]{4}(-[A-Z0-9]{4}){3}$`（16 位 + 3 连字符） | 激活输入组件与服务端 §7.1 生成规则共用同一正则 |
| D-06 | 解绑冷却期管理员强制释放 | **不支持**；客服流程走人工联系用户等待冷却 | 服务端 §1.1 |
| D-07 | 诊断包导出格式 | 明文 zip（强制脱敏后导出） | §9.6、§10.1 |
| D-08 | 自动检查更新频率 | 启动时自动检查一次 + 设置页手动按钮；**不定时轮询** | §11.3 |
| D-09 | 主题 | 仅内置"简约 / 二次元 / 跟随系统"，**不支持自定义主题包** | §10.1、§5.1 `AppSettings.theme` |
| D-10 | 崩溃日志远程上报 | **默认开启（opt-out）**，设置页可关闭；上报内容严格脱敏 | §2.3、§11.2；服务端新增 `POST /api/v1/telemetry/crash` |
| D-11 | 学校 `xkms`、`zdxk` 字段是否可能随批次变化 | `xkms` **固定枚举**（`1`抢选 / `2`正选 / `3`补退选 / `0`选课已结束；枚举外取值失败并提示升级）；`zdxk` **每批次实时读取**（每次进入 running 前重新调用 `getStudentXkList`，不缓存） | §7.5；`0` 为 2026-08 实测补入的已知终态，与"未知取值"分开处理；未来学校新增批次模式（如"预选"）必须发新版客户端 |
| D-12 | 账号/目标配置导入导出 | 不支持（与"账号密码不出设备"策略一致） | §8、§14 |
| D-13 | 抢课任务最大连续运行时长 | **30 分钟**；到时自动停止并要求用户重新确认 | §9.2 |
| D-14 | 服务端接口签名 | 仅 Bearer Token，**不追加 HMAC** | §4.1；服务端 §4.1 无变化 |

## 附录 A. 修订记录

| 日期 | 版本 | 作者 | 变更摘要 |
| --- | --- | --- | --- |
| 2026-08-26 | v1.5 | Claude | §7.1 补入两处传输层实测结论：SSO 跳转必须逐跳手动跟随（`gdpk` 只在第 0 跳下发，dio 的自动跟随在拦截器链下方，末跳空 cookie 被拒 403）；门户每个登录后响应多发一行畸形的 `Set-Cookie: HttpOnly=`，会连带丢弃同响应中合法的 `JSESSIONID`，须启用 `ignoreInvalidCookies`。二者即"添加账号失败"的根因，均由抓原始字节定位、并以 loopback server 端到端测试锁定 |
| 2026-08-26 | v1.4 | Claude | 按 campus.nks.edu.cn 实测校正学校接口章节：§7.1 补入门户会话/应用注册表/`ssolx=5` SSO 三步，登录体改为 JSON，课程列表字段按实际响应列出，`kmh` 由 `xbkid` 提供（§3 术语与 §5.1 `CourseTarget` 同步）；§7.2 改写为完整的响应信封契约（`status` 是整数、负载在 `result`、缺 `result` 与 `result: null` 的区别、401/601/602 映射、字段类型不一致），编码更正为「实测 UTF-8，`decodeGbk` 先试 UTF-8 再回落」；§7.5 与 D-11 补入 `xkms="0"` = 选课已结束这一已知终态，与"未知取值"分开处理；§12 要求 fixture 为真实响应逐字摘录。提交路径因唯一批次已于 2026-04-18 结束而未实测，已在 §7.1 与代码中标注 UNVERIFIED |
| 2026-07-23 | v1.3 | Notion AI | D-11 最终定稿：`xkms` 采用固定枚举（`1/2/3` = 抢选/正选/补退选）、`zdxk` 每批次实时读取；§7.5 由"兼容层（视为可变）"改写为"字段处理（xkms 稳定 / zdxk 可变）"，删除远程覆盖目录与 `AppSettings.campusOverrideUrl` 相关设计；§15 合并为单一"定稿结论"表（D-11 行插入至 D-10 与 D-12 之间）并移除 §15.2；服务端无变更 |
| 2026-07-23 | v1.2 | Notion AI | 根据产品负责人回答固化 §15 中 D-01–D-10、D-12–D-14 为定稿（D-11 保留为待确认）；同步更新 §2.3 崩溃上报默认策略、§7.3 移除预热、§7.5 新增学校字段兼容层（建议方案）、§9.2 最大运行时长 30 min、§9.3 提交步骤、§10.1 设置项与首次运行同意页、§11 各平台产物与 §11.2/§11.3 崩溃与更新策略；服务端同步新增崩溃上报接口、激活码格式与不支持强制解绑 |
| 2026-07-22 | v1.1 | Notion AI | 新增阅读顺序、构建矩阵、横切关注点、时间同步、启动流程、可观测指标、目标优先级/观测诊断、待决策项与修订记录；细化数据模型字段类型与索引；补充目标用户与非目标；补齐幂等/时钟偏差要求 |
| 2026-07-21 | v1.0 | 953 | 初版设计文档 |

<aside>
⚠️

AI 不得自行新增服务端选课代理、离线授权、验证码绕过、全局请求硬下限或任务自动恢复。如学校接口字段无法从本页确定，应将其封装为可配置适配器并添加待验证测试，不得在 UI 中硬编码猜测。

</aside>