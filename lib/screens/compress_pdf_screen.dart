import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/pdf_compress_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  final PdfCompressService _service = const PdfCompressService();

  PlatformFile? _file;
  CompressionLevel _level = CompressionLevel.medium;
  bool _isCompressing = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final picked = result?.files.singleOrNull;
      if (picked == null || picked.path == null) return;
      setState(() => _file = picked);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not pick file: $e');
    }
  }

  Future<void> _compress() async {
    final file = _file;
    if (file == null || _isCompressing) return;

    // Gate saving the compressed file behind a rewarded ad.
    final rewarded = await AdService.instance.showRewardedAd();
    if (!mounted || !rewarded) {
      if (mounted && !rewarded) {
        AppSnackBar.info(context, 'Watch the ad to save your compressed PDF.');
      }
      return;
    }

    setState(() => _isCompressing = true);
    try {
      final result = await _service.compress(file.path!, level: _level);
      if (!mounted) return;
      AppSnackBar.success(context, 'PDF compressed successfully.');
      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Compression failed: $e');
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  void _showResultDialog(CompressionResult result) {
    final savedPercent = (result.savedRatio * 100).toStringAsFixed(1);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 40),
        title: const Text('PDF compressed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sizeRow('Original', result.originalBytes),
            const SizedBox(height: 4),
            _sizeRow('Compressed', result.compressedBytes),
            const Divider(height: 20),
            Text(
              result.savedRatio > 0
                  ? 'Saved $savedPercent%'
                  : 'Already optimized — no size reduction.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            const Text('Saved to:'),
            const SizedBox(height: 4),
            SelectableText(
              result.path,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _sizeRow(String label, int bytes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          _formatSize(bytes),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    return Scaffold(
      appBar: AppBar(title: const Text('Compress PDF')),
      body: file == null
          ? EmptyStateView(
              icon: Icons.compress_outlined,
              title: 'No PDF yet',
              message: 'Pick a PDF file and choose a compression level to reduce its size.',
              actionLabel: 'Pick PDF',
              onAction: _isCompressing ? null : _pickFile,
            )
          : _buildBody(file),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody(PlatformFile file) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_formatSize(file.size)),
            trailing: IconButton(
              tooltip: 'Change',
              icon: const Icon(Icons.swap_horiz),
              onPressed: _isCompressing ? null : _pickFile,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Compression level',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: _isCompressing,
          child: RadioGroup<CompressionLevel>(
            groupValue: _level,
            onChanged: (value) {
              if (value != null) setState(() => _level = value);
            },
            child: Column(
              children: [
                for (final level in CompressionLevel.values)
                  RadioListTile<CompressionLevel>(
                    value: level,
                    title: Text(level.label),
                    subtitle: Text(level.description),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _file == null
            ? FilledButton.icon(
                onPressed: _isCompressing ? null : _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Pick PDF'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              )
            : FilledButton.icon(
                onPressed: _isCompressing ? null : _compress,
                icon: _isCompressing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.compress_outlined),
                label: Text(_isCompressing ? 'Compressing...' : 'Compress PDF'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
