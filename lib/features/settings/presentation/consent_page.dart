/// First-run consent page for crash reporting disclosure.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nkgrabber/app/router.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _disableCrashReporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用须知')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.privacy_tip_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                '崩溃日志上报说明',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                '为改进产品质量，本应用默认开启崩溃日志上报。'
                '上报内容仅包含脱敏堆栈信息、应用版本和平台信息，'
                '绝不包含您的账号、密码、Cookie、激活码或课程数据。',
              ),
              const SizedBox(height: 24),
              const Text('上报内容包含：'),
              const SizedBox(height: 8),
              const Text('• 安装 ID 哈希（不可逆）'),
              const Text('• 应用版本、平台、架构'),
              const Text('• 崩溃类型与脱敏堆栈（仅文件名/行号）'),
              const Text('• 发生时间'),
              const SizedBox(height: 16),
              const Text('绝不上报：'),
              const SizedBox(height: 8),
              const Text('• 账号、密码、Cookie、设备令牌'),
              const Text('• 激活码、学号、姓名'),
              const Text('• 课程 ID / 名称、请求体、日志正文'),
              const Spacer(),
              CheckboxListTile(
                value: _disableCrashReporting,
                onChanged: (v) =>
                    setState(() => _disableCrashReporting = v ?? false),
                title: const Text('始终关闭崩溃上报'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // TODO: Save consent and crash reporting preference.
                    context.go(AppRoutes.activation);
                  },
                  child: const Text('我已知悉，继续使用'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
