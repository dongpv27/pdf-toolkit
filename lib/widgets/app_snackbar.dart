import 'package:flutter/material.dart';

/// Consistent success / error snackbars used across all screens.
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: Icons.check_circle_outline,
      background: const Color(0xFF1B5E20),
      foreground: Colors.white,
    );
  }

  static void error(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      icon: Icons.error_outline,
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
    );
  }

  static void info(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    _show(
      context,
      message,
      icon: Icons.info_outline,
      background: colors.inverseSurface,
      foreground: colors.onInverseSurface,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
      );
  }
}
