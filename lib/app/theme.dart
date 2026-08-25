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

  static ThemeData lightTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.simple:
      case AppThemeMode.system:
        return simpleLightTheme();
      case AppThemeMode.anime:
        return animeLightTheme();
    }
  }

  static ThemeData darkTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.simple:
      case AppThemeMode.system:
        return simpleDarkTheme();
      case AppThemeMode.anime:
        return animeDarkTheme();
    }
  }

  static ThemeMode themeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.simple:
      case AppThemeMode.anime:
        return ThemeMode.light;
    }
  }
}
