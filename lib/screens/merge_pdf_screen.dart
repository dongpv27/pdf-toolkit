import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_merge_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filename_dialog.dart';
import '../widgets/result_dialog.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  // Accent matching the green "Merge PDF" tile on the home screen.
  static const Color _accent = Color(0xFF16A34A);

  final PdfMergeService _service = const PdfMergeService();

  final List<PlatformFile> _files = [];
  bool _isMerging = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (result == null) return;

      // Only keep entries that actually have a readable path, and skip dupes.
      final existingPaths = _files.map((f) => f.path).toSet();
      final added = result.files
          .where((f) => f.path != null && !existingPaths.contains(f.path))
          .toList();

      if (added.isEmpty) return;
      setState(() => _files.addAll(added));
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not pick files: $e');
    }
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _files.removeAt(oldIndex);
      _files.insert(newIndex, item);
    });
  }

  Future<void> _clearAll() async {
    if (_files.isEmpty || _isMerging) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all files?'),
        content: Text('This removes all ${_files.length} selected PDF(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _files.clear());
  }

  Future<void> _merge() async {
    if (_files.length < 2 || _isMerging) return;

    final name = await promptFileName(context, defaultName: 'merged', accent: _accent);
    if (name == null || !mounted) return;

    setState(() => _isMerging = true);
    try {
      final result = await _service.merge(
        _files.map((f) => f.path!).toList(),
        fileName: name,
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'PDFs merged successfully.');
      await showResultDialog(
        context,
        title: 'PDFs merged',
        message: '${result.pageCount} page(s) merged into one PDF.',
        filePath: result.path,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, _errorMessage(e));
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }

  String _errorMessage(Object e) {
    if (e is ArgumentError) return e.message.toString();
    return 'Merge failed: $e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDF'),
        actions: [
          if (_files.isNotEmpty) ...[
            IconButton(
              tooltip: 'Add more',
              onPressed: _isMerging ? null : _pickFiles,
              icon: const Icon(Icons.note_add_outlined),
            ),
            IconButton(
              tooltip: 'Clear all',
              onPressed: _isMerging ? null : _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ],
      ),
      body: _files.isEmpty
          ? EmptyStateView(
              icon: Icons.merge_outlined,
              title: 'No PDFs yet',
              message: 'Pick at least two PDF files to combine them into one document.',
              actionLabel: 'Pick PDFs',
              onAction: _isMerging ? null : _pickFiles,
              accentColor: _accent,
            )
          : _buildList(),
      bottomNavigationBar: _files.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildList() {
    final scheme = Theme.of(context).colorScheme;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _files.length,
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          key: ObjectKey(file),
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.15),
              foregroundColor: _accent,
              child: Text('${index + 1}'),
            ),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_formatSize(file.size)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _isMerging ? null : () => _removeFile(index),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: !_isMerging,
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
    final canMerge = _files.length >= 2 && !_isMerging;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: canMerge ? _merge : null,
          icon: _isMerging
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.merge_outlined),
          label: Text(
            _isMerging ? 'Merging...' : 'Merge PDFs (${_files.length})',
          ),
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
