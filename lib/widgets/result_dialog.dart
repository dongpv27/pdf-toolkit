import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../services/ad_service.dart';
import 'app_snackbar.dart';

/// Success dialog shown after a PDF is created/merged/compressed. Offers Open,
/// Share and Done actions.
///
/// An interstitial ad (at most every few operations) is shown **before** the
/// dialog and we wait for it to close first, so the ad never ends up hidden
/// behind the Open/Share/Done actions. The result is presented only after the
/// ad is dismissed.
Future<void> showResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String filePath,
  Widget? extra,
}) async {
  await AdService.instance.maybeShowInterstitial();
  if (!context.mounted) return;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 40),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (extra != null) ...[
              const SizedBox(height: 12),
              extra,
            ],
            const SizedBox(height: 12),
            Text('Saved to:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(filePath, style: theme.textTheme.bodySmall),
          ],
        ),
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await OpenFilex.open(filePath);
              if (result.type != ResultType.done && dialogContext.mounted) {
                AppSnackBar.error(dialogContext, 'No app found to open the PDF.');
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
          ),
          TextButton.icon(
            onPressed: () {
              Share.shareXFiles([XFile(filePath)]);
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}
