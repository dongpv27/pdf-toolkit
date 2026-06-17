import 'package:flutter/material.dart';

/// A large, tappable card used on the home screen to launch a tool.
class ToolCard extends StatelessWidget {
  const ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBackground,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Optional per-tool icon tile colors. Default to the primary (blue) tile.
  final Color? iconBackground;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tileBg = iconBackground ?? colors.primaryContainer;
    final tileFg = iconColor ?? colors.onPrimaryContainer;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shadowColor: colors.shadow.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: tileFg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
