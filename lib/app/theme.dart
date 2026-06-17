import 'package:flutter/material.dart';

/// Centralised Material 3 theme for PDF Toolkit.
class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF3D5AFE);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
