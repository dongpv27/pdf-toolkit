import 'package:flutter/material.dart';

/// Centralised Material 3 theme for PDF Toolkit.
///
/// A professional "enterprise productivity" palette: a trustworthy blue primary,
/// neutral slate-gray surfaces, and a teal accent — inspired by Google Drive /
/// modern SaaS tools. No red primaries, no playful purple.
class AppTheme {
  AppTheme._();

  // --- Brand palette --------------------------------------------------------
  static const blue = Color(0xFF2563EB); // primary — trust / productivity
  static const blueDeep = Color(0xFF1E3A8A); // on-container text
  static const blueSoft = Color(0xFFDBEAFE); // primary container
  static const slate = Color(0xFF475569); // secondary — neutral
  static const teal = Color(0xFF0D9488); // accent — fresh highlight

  static ThemeData light() => _light();
  static ThemeData dark() => _dark();

  // --- Light ----------------------------------------------------------------
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: blue,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: blueSoft,
    onPrimaryContainer: blueDeep,
    secondary: slate,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E8F0),
    onSecondaryContainer: Color(0xFF1E293B),
    tertiary: teal,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCCFBF1),
    onTertiaryContainer: Color(0xFF134E4A),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF64748B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFE9EEF5),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF93C5FD),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: blue,
  );

  // --- Dark (bonus) ---------------------------------------------------------
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF0B1220),
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFF94A3B8),
    onSecondary: Color(0xFF0B1220),
    secondaryContainer: Color(0xFF334155),
    onSecondaryContainer: Color(0xFFE2E8F0),
    tertiary: Color(0xFF2DD4BF),
    onTertiary: Color(0xFF06251F),
    tertiaryContainer: Color(0xFF134E4A),
    onTertiaryContainer: Color(0xFFCCFBF1),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF0F172A),
    onSurface: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF94A3B8),
    surfaceContainerLowest: Color(0xFF0B1120),
    surfaceContainerLow: Color(0xFF111A2C),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHigh: Color(0xFF273449),
    surfaceContainerHighest: Color(0xFF334155),
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF1E293B),
    inversePrimary: blue,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF60A5FA),
  );

  static ThemeData _light() => _build(_lightScheme);
  static ThemeData _dark() => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surfaceContainerLow,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        shadowColor: scheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),

      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    );
  }
}
