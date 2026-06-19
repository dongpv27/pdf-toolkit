import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_tools_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filename_dialog.dart';
import '../widgets/result_dialog.dart';

/// Reorder, rotate and delete pages of a PDF, then save a new file.
class OrganizePdfScreen extends StatefulWidget {
  const OrganizePdfScreen({super.key});

  @override
  State<OrganizePdfScreen> createState() => _OrganizePdfScreenState();
}

class _OrganizePdfScreenState extends State<OrganizePdfScreen> {
  static const Color _accent = Color(0xFF7C3AED); // violet

  final PdfToolsService _service = const PdfToolsService();

  PlatformFile? _file;
  List<Uint8List> _thumbs = const [];
  final List<PageEdit> _pages = [];
  bool _loading = false;
  bool _saving = false;

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
        _loading = true;
        _thumbs = const [];
        _pages.clear();
      });

      final thumbs = await _service.renderThumbnails(picked.path!);
      if (!mounted) return;
      setState(() {
        _thumbs = thumbs;
        _pages
          ..clear()
          ..addAll([for (var i = 0; i < thumbs.length; i++) PageEdit(sourceIndex: i)]);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppSnackBar.error(context, 'Could not open PDF: $e');
      }
    }
  }

  void _rotate(int index) {
    setState(() {
      final p = _pages[index];
      _pages[index] = PageEdit(
        sourceIndex: p.sourceIndex,
        quarterTurns: (p.quarterTurns + 1) % 4,
      );
    });
  }

  void _delete(int index) => setState(() => _pages.removeAt(index));

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    if (_pages.isEmpty || _saving) return;
    final name = await promptFileName(context, defaultName: 'organized', accent: _accent);
    if (name == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final file = await _service.organize(_file!.path!, _pages, fileName: name);
      if (!mounted) return;
      AppSnackBar.success(context, 'PDF saved.');
      await showResultDialog(
        context,
        title: 'PDF saved',
        message: '${_pages.length} page(s) saved.',
        filePath: file.path,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPages = _pages.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organize Pages'),
        actions: [
          if (_file != null)
            IconButton(
              tooltip: 'Change',
              onPressed: _saving ? null : _pickFile,
              icon: const Icon(Icons.swap_horiz),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _file == null
              ? EmptyStateView(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Organize PDF pages',
                  message:
                      'Pick a PDF to reorder, rotate or delete its pages, then save a new file.',
                  actionLabel: 'Pick PDF',
                  onAction: _pickFile,
                  accentColor: _accent,
                )
              : _buildList(),
      bottomNavigationBar: hasPages ? _buildBottomBar() : null,
    );
  }

  Widget _buildList() {
    final scheme = Theme.of(context).colorScheme;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pages.length,
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final page = _pages[index];
        return Card(
          key: ValueKey('page_${page.sourceIndex}'),
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            leading: SizedBox(
              width: 46,
              height: 58,
              child: RotatedBox(
                quarterTurns: page.quarterTurns,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(_thumbs[page.sourceIndex], fit: BoxFit.contain),
                ),
              ),
            ),
            title: Text('Page ${index + 1}'),
            subtitle: Text('Original #${page.sourceIndex + 1}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Rotate',
                  icon: const Icon(Icons.rotate_right),
                  onPressed: _saving ? null : () => _rotate(index),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving ? null : () => _delete(index),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: !_saving,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save PDF (${_pages.length})'),
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
