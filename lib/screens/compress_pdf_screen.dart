import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_compress_service.dart';
import '../services/pdf_tools_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filename_dialog.dart';
import '../widgets/result_dialog.dart';

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  // Accent matching the amber "Compress PDF" tile on the home screen.
  static const Color _accent = Color(0xFFD97706);

  final PdfCompressService _service = const PdfCompressService();
  final PdfToolsService _tools = const PdfToolsService();

  // Above this many bytes per page a PDF is treated as scan/photo-heavy, so the
  // "Smaller size" (rasterize) mode is recommended over lossless.
  static const int _imageHeavyBytesPerPage = 200 * 1024;

  PlatformFile? _file;
  CompressionMode _mode = CompressionMode.smart;
  CompressionMode? _recommended;
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
      setState(() {
        _file = picked;
        _recommended = null;
      });

      // Heuristic: lots of bytes per page → likely scanned/photo PDF, where
      // lossless does little, so recommend (and pre-select) "Smaller size".
      try {
        final pages = await _tools.pageCount(picked.path!);
        final bytesPerPage =
            pages > 0 ? picked.size / pages : picked.size.toDouble();
        final rec = bytesPerPage > _imageHeavyBytesPerPage
            ? CompressionMode.strong
            : CompressionMode.smart;
        if (!mounted) return;
        setState(() {
          _recommended = rec;
          _mode = rec;
        });
      } catch (_) {
        // Keep the default mode if the PDF can't be inspected.
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not pick file: $e');
    }
  }

  Future<void> _compress() async {
    final file = _file;
    if (file == null || _isCompressing) return;

    final base = file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final name = await promptFileName(
      context,
      defaultName: '${base}_compressed',
      accent: _accent,
    );
    if (name == null || !mounted) return;

    setState(() => _isCompressing = true);
    try {
      final result = _mode == CompressionMode.smart
          ? await _service.compressSmart(file.path!, fileName: name)
          : await _service.compress(file.path!, level: _level, fileName: name);
      if (!mounted) return;
      AppSnackBar.success(context, 'PDF compressed successfully.');
      final savedPercent = (result.savedRatio * 100).toStringAsFixed(1);
      final String message;
      if (result.savedRatio > 0) {
        message = 'Saved $savedPercent% of the original size.';
      } else if (_mode == CompressionMode.smart) {
        // Lossless couldn't shrink it — for scanned/photo PDFs the "Smaller
        // size" mode usually can.
        message = 'Already optimized — no size reduction.\n'
            'For scanned or photo PDFs, try the "Smaller size" mode.';
      } else {
        message = 'Already optimized — no size reduction.';
      }
      await showResultDialog(
        context,
        title: 'PDF compressed',
        message: message,
        filePath: result.path,
        extra: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sizeRow('Original', result.originalBytes),
            const SizedBox(height: 4),
            _sizeRow('Compressed', result.compressedBytes),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Compression failed: $e');
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
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
              accentColor: _accent,
            )
          : _buildBody(file),
      bottomNavigationBar: file == null ? null : _buildBottomBar(),
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
            leading: const Icon(
              Icons.picture_as_pdf_outlined,
              color: _accent,
            ),
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
          'Compression mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final mode in CompressionMode.values)
          RadioListTile<CompressionMode>(
            value: mode,
            groupValue: _mode,
            onChanged:
                _isCompressing ? null : (v) => setState(() => _mode = v!),
            activeColor: _accent,
            title: Row(
              children: [
                Text(mode.label),
                if (mode == _recommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(mode.description),
          ),
        if (_mode == CompressionMode.strong) ...[
          const SizedBox(height: 8),
          Text(
            'Strength',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final level in CompressionLevel.values)
            RadioListTile<CompressionLevel>(
              value: level,
              groupValue: _level,
              onChanged: _isCompressing
                  ? null
                  : (value) => setState(() => _level = value!),
              activeColor: _accent,
              title: Text(level.label),
              subtitle: Text(level.description),
            ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _mode == CompressionMode.smart
                      ? 'Lossless: text stays selectable. Best for text & mixed '
                          'PDFs. Already-optimized PDFs may shrink only a little.'
                      : 'Pages are re-rendered as images, so text may no longer '
                          'be selectable. Best for scanned or photo PDFs.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _isCompressing ? null : _compress,
          icon: _isCompressing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.compress_outlined),
          label: Text(_isCompressing ? 'Compressing...' : 'Compress PDF'),
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
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
