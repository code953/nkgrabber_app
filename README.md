# NKgrabber 抢课程序

高校选课辅助客户端，支持 Android、Windows、Linux、macOS、iOS 五端。

## 下载

前往 [Releases](https://github.com/code953/nkgrabber_app/releases) 下载对应平台的安装包。

| 平台 | 文件 | 说明 |
|------|------|------|
| Android | `app-*-release.apk` | 按 CPU 架构分包，多数手机选 `arm64-v8a` |
| Windows | `nkgrabber-windows-x64.zip` | 解压后运行 `nkgrabber.exe` |
| Linux | `nkgrabber-linux-x64.tar.gz` | 解压后运行 `./install.sh` 添加桌面项，或直接运行 `./nkgrabber` |
| macOS | `nkgrabber-macos-universal.dmg` | 见下方说明 |

每次发布附带 `SHA256SUMS.txt`，可用于校验下载完整性。

**macOS 用户注意**：安装包未经 Apple 公证，首次打开会被 Gatekeeper 拦截。
需在「访达」中右键点击应用图标 →「打开」，再在弹窗中确认。

**iOS 暂不提供安装包**。CI 只做编译验证，分发 iOS 应用需要 Apple 开发者账号。

## 功能

- 多账号管理（密码/Cookie 模式）
- 课程目标配置与优先级
- 受控自动提交调度
- 本地设置：请求间隔、间隔下限、账号数与并发上限

除学校选课系统本身，客户端不与任何服务端通信 —— 无授权激活、无检查更新、
无崩溃上报、无远程配置。

## 技术栈

- Flutter + Dart (>=3.5)
- 状态管理: Riverpod
- 本地数据库: SQLite + Drift
- 架构: presentation → application → domain → infrastructure

## 开发环境

### 前置条件

- Flutter SDK >= 3.24 (Stable channel)
- Dart SDK >= 3.5
- Android Studio / VS Code
- 对应平台编译工具链

### 安装依赖

```bash
flutter pub get
```

### 代码生成

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行

```bash
flutter run
```

### 测试

```bash
flutter test
```

### 构建

```bash
# Android
flutter build apk --split-per-abi

# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## 目录结构

```
lib/
├─ app/                    # 主题、路由、Shell 页
├─ core/
│  ├─ errors/             # AppException 与错误映射
│  ├─ logging/            # 脱敏日志
│  ├─ security/           # 平台安全存储
│  └─ utils/
├─ features/
│  ├─ accounts/           # 账号管理
│  ├─ courses/            # 课程设置
│  ├─ grabber/            # 抢课调度器
│  └─ settings/           # 设置
├─ infrastructure/
│  ├─ database/           # Drift 表、DAO、迁移
│  └─ campus/             # 学校系统适配器
└─ main.dart
```

## 平台支持

| 平台 | 最低版本 | 架构 |
|------|----------|------|
| Android | API 24 (7.0) | arm64-v8a, armeabi-v7a, x86_64 |
| iOS | 14.0 | arm64 |
| macOS | 12.0 | Universal (Apple Silicon + Intel) |
| Windows | 10 20H2+ | x64 |
| Linux | glibc >= 2.31 | x64 |

## 安全说明

- 密码与 Cookie 仅存储在平台安全存储中，Cookie 不落盘
- 每个账号使用独立的 Dio 实例与内存 CookieJar，会话互不干扰
- 日志自动脱敏，不输出敏感信息
- 学校账号数据不上传任何服务端 —— 客户端只与学校选课系统通信

## 许可

本项目采用 [GNU General Public License v3.0](LICENSE) 授权。

你可以自由使用、修改和分发本软件，但基于本项目的衍生作品必须同样以 GPL-3.0
开源。

## 免责声明

本项目仅供学习与技术交流使用。

使用者应自行遵守所在学校的选课规定与相关规章制度，并对使用本软件产生的一切
后果负责。作者不对因使用本软件导致的任何损失或处分承担责任。

若你所在学校明确禁止使用此类工具，请不要使用。
