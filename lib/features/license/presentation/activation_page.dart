/// License activation page.
///
/// Allows the user to enter an activation code to bind this device.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nkgrabber/core/utils/constants.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入激活码';
    }
    final normalized = value.trim().toUpperCase();
    if (!AppConstants.activationCodeRegex.hasMatch(normalized)) {
      return '激活码格式错误，请输入 XXXX-XXXX-XXXX-XXXX 格式';
    }
    return null;
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // TODO: Call BackendRepository.activateLicense() via Riverpod.
    // On success, navigate to home. On failure, show error.

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('激活授权')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.vpn_key_outlined, size: 64),
                const SizedBox(height: 24),
                Text(
                  '输入激活码',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('请输入您的授权激活码以绑定此设备'),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _controller,
                  validator: _validateCode,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp('[A-Za-z0-9-]'),
                    ),
                    LengthLimitingTextInputFormatter(19),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'XXXX-XXXX-XXXX-XXXX',
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _activate,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('激活'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
