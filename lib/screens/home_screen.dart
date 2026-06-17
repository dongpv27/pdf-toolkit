import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/tool_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Toolkit'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps content readable on tablets / large phones.
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All your PDF tools',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Convert, merge and compress — fully offline.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ToolCard(
                    icon: Icons.image_outlined,
                    title: 'Image to PDF',
                    subtitle: 'Turn photos into a single PDF',
                    iconBackground: const Color(0xFFDBEAFE), // blue
                    iconColor: const Color(0xFF2563EB),
                    onTap: () => context.push(AppRoutes.imageToPdf),
                  ),
                  const SizedBox(height: 12),
                  ToolCard(
                    icon: Icons.merge_outlined,
                    title: 'Merge PDF',
                    subtitle: 'Combine multiple PDFs into one',
                    iconBackground: const Color(0xFFDCFCE7), // green
                    iconColor: const Color(0xFF16A34A),
                    onTap: () => context.push(AppRoutes.mergePdf),
                  ),
                  const SizedBox(height: 12),
                  ToolCard(
                    icon: Icons.compress_outlined,
                    title: 'Compress PDF',
                    subtitle: 'Reduce PDF file size',
                    iconBackground: const Color(0xFFFEF3C7), // amber
                    iconColor: const Color(0xFFD97706),
                    onTap: () => context.push(AppRoutes.compressPdf),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
