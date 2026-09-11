/// Theme definitions for the NKgrabber app.
///
/// Supports three modes: simple (Material 3 blue), anime (pink/purple),
/// and system (follows platform brightness with simple colors).
library;

import 'package:flutter/material.dart';

/// Available theme modes matching AppSettings.theme field.
enum AppThemeMode {
  simple,
  anime,
  custom,
  system;

  static AppThemeMode fromString(String value) {
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

class AppTheme {
  const AppTheme._();

  // -- Simple theme (Material 3, blue seed) ----------------------------------

  static final _simpleSeedColor = Colors.blue.shade700;

  static ThemeData simpleLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _simpleSeedColor),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  static ThemeData simpleDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _simpleSeedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  // -- Anime theme (pink/purple accents) -------------------------------------

  static const _animeSeedColor = Color(0xFFE91E63);

  static ThemeData animeLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _animeSeedColor,
        primary: const Color(0xFFE91E63),
        secondary: const Color(0xFF9C27B0),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  static ThemeData animeDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _animeSeedColor,
        brightness: Brightness.dark,
        primary: const Color(0xFFF48FB1),
        secondary: const Color(0xFFCE93D8),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  // -- Helpers ---------------------------------------------------------------

  static ThemeData customTheme(Color seedColor, {required bool isDark}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }

  static ThemeData lightTheme(AppThemeMode mode, {Color? customColor}) {
    switch (mode) {
      case AppThemeMode.simple:
      case AppThemeMode.system:
        return simpleLightTheme();
      case AppThemeMode.anime:
        return animeLightTheme();
      case AppThemeMode.custom:
        return customTheme(customColor ?? _simpleSeedColor, isDark: false);
    }
  }

  static ThemeData darkTheme(AppThemeMode mode, {Color? customColor}) {
    switch (mode) {
      case AppThemeMode.simple:
      case AppThemeMode.system:
        return simpleDarkTheme();
      case AppThemeMode.anime:
        return animeDarkTheme();
      case AppThemeMode.custom:
        return customTheme(customColor ?? _simpleSeedColor, isDark: true);
    }
  }

  static ThemeMode themeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.simple:
      case AppThemeMode.anime:
      case AppThemeMode.custom:
        return ThemeMode.light;
    }
  }
}
