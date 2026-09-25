/// Application routing configuration using GoRouter.
///
/// The app runs fully offline against the campus system, so there is no
/// startup gate or activation flow — the account list is the entry point.
library;

import 'package:go_router/go_router.dart';
import 'package:nkgrabber/app/shell_page.dart';
import 'package:nkgrabber/features/accounts/presentation/accounts_page.dart';
import 'package:nkgrabber/features/courses/presentation/course_config_page.dart';
import 'package:nkgrabber/features/grabber/presentation/grabber_page.dart';
import 'package:nkgrabber/features/settings/presentation/settings_page.dart';

/// Route path constants.
class AppRoutes {
  const AppRoutes._();

  static const home = '/home';
  static const accounts = '/home/accounts';
  static const addAccount = '/home/accounts/add';
  static const courses = '/home/courses';
  static const grabber = '/home/grabber';
  static const settings = '/home/settings';
}

/// Create the app router.
///
/// The tabs switch without a transition. Tabs are not a push, and with a
/// background image the scaffolds are transparent — a cross-route animation
/// would draw the outgoing and incoming page on top of each other.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.accounts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AccountsPage()),
          ),
          GoRoute(
            path: AppRoutes.courses,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CourseConfigPage()),
          ),
          GoRoute(
            path: AppRoutes.grabber,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GrabberPage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
}
