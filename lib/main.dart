/// NKgrabber application entry point.
///
/// Initializes logging, secure storage, database, and crash reporting
/// before launching the main app widget within a Riverpod ProviderScope.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nkgrabber/app/router.dart';
import 'package:nkgrabber/app/theme.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging system.
  AppLogger.init();

  AppLogger('main').info('NKgrabber starting...');

  runApp(
    const ProviderScope(
      child: NKGrabberApp(),
    ),
  );
}

class NKGrabberApp extends ConsumerStatefulWidget {
  const NKGrabberApp({super.key});

  @override
  ConsumerState<NKGrabberApp> createState() => _NKGrabberAppState();
}

class _NKGrabberAppState extends ConsumerState<NKGrabberApp> {
  // Hoist the router so it is not recreated on every build.
  // A new GoRouter instance discards navigation state and resets the stack.
  late final GoRouter _router = createRouter();

  @override
  Widget build(BuildContext context) {
    // TODO: Read theme mode from settings provider.
    const themeMode = AppThemeMode.system;

    return MaterialApp.router(
      title: 'NKgrabber',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeMode),
      darkTheme: AppTheme.darkTheme(themeMode),
      themeMode: AppTheme.themeMode(themeMode),
      routerConfig: _router,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
    );
  }
}



