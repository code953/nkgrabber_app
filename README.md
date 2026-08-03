# NKgrabber 抢课程序

高校选课辅助客户端，支持 Android、Windows、Linux、macOS、iOS 五端。

## 功能

- 授权激活与校验
- 多账号管理（密码/Cookie 模式）
- 课程目标配置与优先级
- 受控自动提交调度
- 安全更新与崩溃上报

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
├─ app/                    # 启动、主题、路由、全局 Provider
├─ core/
│  ├─ errors/             # AppException 与错误映射
│  ├─ logging/            # 脱敏日志
│  ├─ network/            # BackendApiClient 基础设施
│  ├─ security/           # 平台安全存储
│  └─ utils/
├─ features/
│  ├─ license/            # 激活与授权
│  ├─ accounts/           # 账号管理
│  ├─ courses/            # 课程设置
│  ├─ grabber/            # 抢课调度器
│  ├─ settings/           # 设置
│  └─ updater/            # 更新
├─ infrastructure/
│  ├─ database/           # Drift 表、DAO、迁移
│  ├─ campus/             # 学校系统适配器
│  └─ backend/            # 服务端 DTO 与 Repository
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

- 密码、Cookie、设备令牌仅存储在平台安全存储中
- 日志自动脱敏，不输出敏感信息
- 更新包经 SHA-256 + Ed25519 签名双重校验
- 学校账号数据不上传业务服务端

## 许可

私有项目，未经授权禁止分发。
