/// NKgrabber application entry point.
///
/// Initializes logging and local crash capture before launching the main
/// app widget within a Riverpod ProviderScope.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nkgrabber/app/router.dart';
import 'package:nkgrabber/app/theme.dart';
import 'package:nkgrabber/core/logging/app_logger.dart';
import 'package:nkgrabber/core/logging/log_sanitizer.dart';
import 'package:nkgrabber/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging system.
  AppLogger.init();

  final logger = AppLogger('main');
  logger.info('NKgrabber starting...');

  // Capture framework errors locally. Nothing is sent over the network —
  // the message is sanitized and written to the local log so a failed
  // grab task can still be diagnosed after the fact.
  FlutterError.onError = (details) {
    logger.error(
      LogSanitizer.sanitize(details.exceptionAsString()),
      details.exception,
      details.stack,
    );
  };

  // Capture uncaught async errors from the app's zone.
  runZonedGuarded(
    () => runApp(const ProviderScope(child: NKGrabberApp())),
    (error, stackTrace) => logger.error(
      LogSanitizer.sanitize(error.toString()),
      error,
      stackTrace,
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
      // These delegates are not optional. Without them the only
      // MaterialLocalizations on offer is DefaultMaterialLocalizations,
      // which supports 'en' alone — so forcing a zh locale leaves
      // NavigationRail/NavigationBar with no localizations at all.
      // `S` bundles its own delegate plus the three Global* ones.
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('zh'),
    );
  }
}
