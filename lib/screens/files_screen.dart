import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../services/file_store_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filename_dialog.dart';

/// Library of every PDF the app has produced. Lets the user open, share,
/// rename and delete past outputs.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  static const Color _accent = Color(0xFF6366F1); // indigo

  final FileStoreService _service = const FileStoreService();

  List<StoredFile> _files = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final files = await _service.listPdfs();
    if (!mounted) return;
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _open(StoredFile f) async {
    final result = await OpenFilex.open(f.path);
    if (result.type != ResultType.done && mounted) {
      AppSnackBar.error(context, 'No app found to open the PDF.');
    }
  }

  void _share(StoredFile f) => Share.shareXFiles([XFile(f.path)]);

  Future<void> _rename(StoredFile f) async {
    final base = f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final name = await promptFileName(
      context,
      defaultName: base,
      accent: _accent,
      saveLabel: 'Rename',
    );
    if (name == null) return;
    try {
      await _service.rename(f, name);
      await _load();
      if (mounted) AppSnackBar.success(context, 'Renamed.');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, '$e'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(StoredFile f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('"${f.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.delete(f);
    await _load();
    if (mounted) AppSnackBar.success(context, 'Deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Files'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const EmptyStateView(
                  icon: Icons.folder_open_outlined,
                  title: 'No files yet',
                  message:
                      'PDFs you create, merge or compress will appear here.',
                  accentColor: _accent,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _files.length,
                    itemBuilder: (context, index) => _tile(_files[index]),
                  ),
                ),
    );
  }

  Widget _tile(StoredFile f) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _open(f),
        leading: const Icon(Icons.picture_as_pdf_outlined, color: _accent),
        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${_formatSize(f.size)} · ${_formatDate(f.modified)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'open':
                _open(f);
              case 'share':
                _share(f);
              case 'rename':
                _rename(f);
              case 'delete':
                _delete(f);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'share', child: Text('Share')),
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
