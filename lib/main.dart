/// NKgrabber application entry point.
///
/// Initializes logging, secure storage, database, and crash reporting
/// before launching the main app widget within a Riverpod ProviderScope.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/app/router.dart';
import 'package:nkgrabber/app/theme.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging system
  AppLogger.init();

  AppLogger('main').info('NKgrabber starting...');

  runApp(
    const ProviderScope(
      child: NKGrabberApp(),
    ),
  );
}

class NKGrabberApp extends ConsumerWidget {
  const NKGrabberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Read theme mode from settings provider.
    const themeMode = AppThemeMode.system;
    final router = createRouter();

    return MaterialApp.router(
      title: 'NKgrabber',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeMode),
      darkTheme: AppTheme.darkTheme(themeMode),
      themeMode: AppTheme.themeMode(themeMode),
      routerConfig: router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
    );
  }
}
