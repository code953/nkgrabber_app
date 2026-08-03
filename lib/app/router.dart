/// Application routing configuration using GoRouter.
///
/// Defines all routes and redirect guards for auth state.
library;

import 'package:go_router/go_router.dart';
import 'package:nkgrabber/app/shell_page.dart';
import 'package:nkgrabber/app/startup_page.dart';
import 'package:nkgrabber/features/accounts/presentation/accounts_page.dart';
import 'package:nkgrabber/features/courses/presentation/course_config_page.dart';
import 'package:nkgrabber/features/grabber/presentation/grabber_page.dart';
import 'package:nkgrabber/features/license/presentation/activation_page.dart';
import 'package:nkgrabber/features/settings/presentation/consent_page.dart';
import 'package:nkgrabber/features/settings/presentation/settings_page.dart';

/// Route path constants.
class AppRoutes {
  const AppRoutes._();

  static const startup = '/startup';
  static const consent = '/consent';
  static const activation = '/activation';
  static const home = '/home';
  static const accounts = '/home/accounts';
  static const addAccount = '/home/accounts/add';
  static const courses = '/home/courses';
  static const grabber = '/home/grabber';
  static const settings = '/home/settings';
  static const update = '/update';
}

/// Create the app router.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.startup,
    routes: [
      GoRoute(
        path: AppRoutes.startup,
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        path: AppRoutes.consent,
        builder: (context, state) => const ConsentPage(),
      ),
      GoRoute(
        path: AppRoutes.activation,
        builder: (context, state) => const ActivationPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => const AccountsPage(),
          ),
          GoRoute(
            path: AppRoutes.courses,
            builder: (context, state) => const CourseConfigPage(),
          ),
          GoRoute(
            path: AppRoutes.grabber,
            builder: (context, state) => const GrabberPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}
