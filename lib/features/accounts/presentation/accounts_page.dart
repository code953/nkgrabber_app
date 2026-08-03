/// Accounts list page.
///
/// Shows all registered campus accounts with status badges.
/// Provides add/remove account actions.
library;

import 'package:flutter/material.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/database/tables/accounts.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire to AccountsNotifier via Riverpod.
    return Scaffold(
      appBar: AppBar(title: const Text('账号管理')),
      body: const _EmptyState(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const AddAccountSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有账号',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('点击右下角按钮添加校园账号'),
        ],
      ),
    );
  }
}

/// Account list tile with status badge.
class AccountListTile extends StatelessWidget {
  const AccountListTile({
    required this.account,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final AccountEntry account;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          account.displayName.isNotEmpty
              ? account.displayName[0]
              : '?',
        ),
      ),
      title: Text(account.displayName),
      subtitle: Text(account.studentNo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusBadge(status: account.status),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AccountStatus.validating => (Colors.orange, '验证中'),
      AccountStatus.ready => (Colors.green, '就绪'),
      AccountStatus.expired => (Colors.red, '已过期'),
      AccountStatus.captchaRequired => (Colors.amber, '需验证码'),
      AccountStatus.networkError => (Colors.grey, '网络错误'),
      AccountStatus.disabledByPlan => (Colors.grey, '已停用'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

/// Bottom sheet for adding a new account.
class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  bool _isPasswordMode = true;
  final _studentNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cookieController = TextEditingController();
  bool _rememberPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _studentNoController.dispose();
    _passwordController.dispose();
    _cookieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '添加账号',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('密码登录')),
              ButtonSegment(value: false, label: Text('Cookie模式')),
            ],
            selected: {_isPasswordMode},
            onSelectionChanged: (set) {
              setState(() => _isPasswordMode = set.first);
            },
          ),
          const SizedBox(height: 16),
          if (_isPasswordMode) ...[
            TextField(
              controller: _studentNoController,
              decoration: const InputDecoration(
                labelText: '学号',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _rememberPassword,
              onChanged: (v) => setState(() => _rememberPassword = v!),
              title: const Text('记住密码'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ] else ...[
            TextField(
              controller: _cookieController,
              decoration: const InputDecoration(
                labelText: 'gdpk Cookie',
                prefixIcon: Icon(Icons.cookie_outlined),
                helperText: '从浏览器开发者工具中复制 gdpk 值',
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    // TODO: Call AccountsNotifier.addByPassword/addByCookie via Riverpod.

    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop();
  }
}
