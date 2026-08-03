/// Startup page — shown while the app performs initial checks.
///
/// Loads config, checks license, and redirects to the appropriate page.
library;

import 'package:flutter/material.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement startup logic with Riverpod provider.
    // For now, show a loading indicator.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载...'),
          ],
        ),
      ),
    );
  }
}
