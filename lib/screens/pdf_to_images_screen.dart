import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_tools_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/result_dialog.dart';

/// Exports each page of a PDF to a JPEG image.
class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

enum _Quality {
  low('Low', 96, 70),
  medium('Medium', 150, 85),
  high('High', 220, 92);

  const _Quality(this.label, this.dpi, this.jpgQuality);
  final String label;
  final double dpi;
  final int jpgQuality;
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  static const Color _accent = Color(0xFFDB2777); // pink

  final PdfToolsService _service = const PdfToolsService();

  PlatformFile? _file;
  int _pageCount = 0;
  _Quality _quality = _Quality.medium;
  bool _busy = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final picked = result?.files.singleOrNull;
      if (picked == null || picked.path == null) return;
      final count = await _service.pageCount(picked.path!);
      if (!mounted) return;
      setState(() {
        _file = picked;
        _pageCount = count;
      });
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not open PDF: $e');
    }
  }

  Future<void> _convert() async {
    if (_file == null || _busy) return;
    setState(() => _busy = true);
    try {
      final base = _file!.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      final files = await _service.toImages(
        _file!.path!,
        dpi: _quality.dpi,
        quality: _quality.jpgQuality,
        baseName: base,
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'Exported ${files.length} image(s).');
      await showMultiFileResultDialog(
        context,
        title: 'Exported to images',
        message: 'Created ${files.length} JPG image(s) in My Files folder. '
            'Use "Share all" to save them to your gallery.',
        filePaths: files.map((f) => f.path).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Images'),
        actions: [
          if (_file != null)
            IconButton(
              tooltip: 'Change',
              onPressed: _busy ? null : _pickFile,
              icon: const Icon(Icons.swap_horiz),
            ),
        ],
      ),
      body: _file == null
          ? EmptyStateView(
              icon: Icons.collections_outlined,
              title: 'PDF to images',
              message: 'Pick a PDF to export each page as a JPG image.',
              actionLabel: 'Pick PDF',
              onAction: _pickFile,
              accentColor: _accent,
            )
          : _buildBody(),
      bottomNavigationBar: _file == null ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: _accent),
            title: Text(_file!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('$_pageCount page(s)'),
          ),
        ),
        const SizedBox(height: 24),
        Text('Image quality', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final q in _Quality.values)
          RadioListTile<_Quality>(
            value: q,
            groupValue: _quality,
            onChanged: _busy ? null : (v) => setState(() => _quality = v!),
            activeColor: _accent,
            title: Text(q.label),
            subtitle: Text('${q.dpi.toInt()} DPI'),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _busy ? null : _convert,
          icon: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.image_outlined),
          label: Text(_busy ? 'Exporting...' : 'Export $_pageCount image(s)'),
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
    );
  }
}
