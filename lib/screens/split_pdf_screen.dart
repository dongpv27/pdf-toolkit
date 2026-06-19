import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pdf_tools_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filename_dialog.dart';
import '../widgets/result_dialog.dart';

/// Splits a PDF: either one file per page, or extract a page range.
class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  static const Color _accent = Color(0xFF0891B2); // cyan

  final PdfToolsService _service = const PdfToolsService();
  final TextEditingController _from = TextEditingController(text: '1');
  final TextEditingController _to = TextEditingController(text: '1');

  PlatformFile? _file;
  int _pageCount = 0;
  bool _busy = false;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

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
        _from.text = '1';
        _to.text = '$count';
      });
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not open PDF: $e');
    }
  }

  Future<void> _splitEach() async {
    if (_file == null || _busy) return;
    setState(() => _busy = true);
    try {
      final base = _baseName();
      final files = await _service.splitToSinglePages(_file!.path!, baseName: base);
      if (!mounted) return;
      AppSnackBar.success(context, 'Split into ${files.length} files.');
      await showMultiFileResultDialog(
        context,
        title: 'Split complete',
        message: 'Created ${files.length} files in My Files (one per page).',
        filePaths: files.map((f) => f.path).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extract() async {
    if (_file == null || _busy) return;
    final from = int.tryParse(_from.text.trim());
    final to = int.tryParse(_to.text.trim());
    if (from == null || to == null || from < 1 || to < 1 || from > _pageCount || to > _pageCount) {
      AppSnackBar.error(context, 'Enter a valid range (1–$_pageCount).');
      return;
    }
    final name = await promptFileName(context, defaultName: 'extract', accent: _accent);
    if (name == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final file = await _service.extractRange(_file!.path!, from, to, fileName: name);
      if (!mounted) return;
      AppSnackBar.success(context, 'Pages extracted.');
      await showResultDialog(
        context,
        title: 'Pages extracted',
        message: 'Pages $from–$to saved as a new PDF.',
        filePath: file.path,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _baseName() =>
      _file!.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
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
              icon: Icons.call_split,
              title: 'Split a PDF',
              message:
                  'Pick a PDF to split into single pages, or extract a page range.',
              actionLabel: 'Pick PDF',
              onAction: _pickFile,
              accentColor: _accent,
            )
          : _buildBody(),
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
        Text('Split into single pages',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _splitEach,
          icon: const Icon(Icons.content_cut),
          label: Text('Split into $_pageCount files'),
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 28),
        Text('Or extract a page range',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numField(_from, 'From')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('–'),
            ),
            Expanded(child: _numField(_to, 'To')),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _extract,
          icon: const Icon(Icons.cut_outlined),
          label: const Text('Extract range'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: _accent),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
