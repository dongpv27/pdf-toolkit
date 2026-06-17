import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/pdf_merge_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
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

  Future<void> _merge() async {
    if (_files.length < 2 || _isMerging) return;

    // Gate the merge behind a rewarded ad.
    final rewarded = await AdService.instance.showRewardedAd();
    if (!mounted || !rewarded) {
      if (mounted && !rewarded) {
        AppSnackBar.info(context, 'Watch the ad to merge your PDFs.');
      }
      return;
    }

    setState(() => _isMerging = true);
    try {
      final result = await _service.merge(
        _files.map((f) => f.path!).toList(),
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'PDFs merged successfully.');
      _showResultDialog(result);
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

  void _showResultDialog(MergeResult result) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 40),
        title: const Text('PDFs merged'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.pageCount} page(s) saved to:'),
            const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDF'),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              tooltip: 'Add more',
              onPressed: _isMerging ? null : _pickFiles,
              icon: const Icon(Icons.note_add_outlined),
            ),
        ],
      ),
      body: _files.isEmpty
          ? EmptyStateView(
              icon: Icons.merge_outlined,
              title: 'No PDFs yet',
              message: 'Pick at least two PDF files to combine them into one document.',
              actionLabel: 'Pick PDFs',
              onAction: _isMerging ? null : _pickFiles,
            )
          : _buildList(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_formatSize(file.size)),
            trailing: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isMerging ? null : () => _removeFile(index),
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
        child: _files.isEmpty
            ? FilledButton.icon(
                onPressed: _isMerging ? null : _pickFiles,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Pick PDFs'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              )
            : FilledButton.icon(
                onPressed: canMerge ? _merge : null,
                icon: _isMerging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.merge_outlined),
                label: Text(
                  _isMerging ? 'Merging...' : 'Merge PDFs (${_files.length})',
                ),
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
