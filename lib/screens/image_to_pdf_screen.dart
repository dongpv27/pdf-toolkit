import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_to_pdf_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/filename_dialog.dart';
import '../widgets/result_dialog.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  // Accent matching the blue "Image to PDF" tile on the home screen.
  static const Color _accent = Color(0xFF2563EB);

  final ImagePicker _picker = ImagePicker();
  final ImageToPdfService _service = const ImageToPdfService();

  final List<XFile> _images = [];
  bool _isConverting = false;

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _images.addAll(picked));
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not pick images: $e');
    }
  }

  Future<void> _scan() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures == null || pictures.isEmpty) return;
      setState(() => _images.addAll(pictures.map((p) => XFile(p))));
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Scan failed: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  Future<void> _clearAll() async {
    if (_images.isEmpty || _isConverting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all images?'),
        content: Text('This removes all ${_images.length} selected image(s).'),
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
    if (confirmed == true) setState(() => _images.clear());
  }

  Future<void> _convert() async {
    if (_images.isEmpty || _isConverting) return;

    final name = await promptFileName(context, defaultName: 'images', accent: _accent);
    if (name == null || !mounted) return;

    setState(() => _isConverting = true);
    try {
      final result = await _service.convert(
        _images.map((x) => x.path).toList(),
        fileName: name,
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'PDF created successfully.');
      await showResultDialog(
        context,
        title: 'PDF created',
        message: '${result.pageCount} page(s) created.',
        filePath: result.path,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Conversion failed: $e');
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
        actions: [
          IconButton(
            tooltip: 'Scan document',
            onPressed: _isConverting ? null : _scan,
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          if (_images.isNotEmpty) ...[
            IconButton(
              tooltip: 'Add more',
              onPressed: _isConverting ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            IconButton(
              tooltip: 'Clear all',
              onPressed: _isConverting ? null : _clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ],
      ),
      body: _images.isEmpty
          ? EmptyStateView(
              icon: Icons.image_outlined,
              title: 'No images yet',
              message: 'Pick photos from your gallery — or tap the scan icon to '
                  'capture documents with auto edge-detection — to combine into a PDF.',
              actionLabel: 'Pick Images',
              onAction: _isConverting ? null : _pickImages,
              accentColor: _accent,
            )
          : _buildList(),
      bottomNavigationBar: _images.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildList() {
    final scheme = Theme.of(context).colorScheme;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _images.length,
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final image = _images[index];
        return Card(
          key: ObjectKey(image),
          elevation: 0,
          color: scheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(image.path),
                width: 46,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            title: Text('Page ${index + 1}'),
            subtitle: Text(
              image.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _isConverting ? null : () => _removeImage(index),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: !_isConverting,
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
          onPressed: _isConverting ? null : _convert,
          icon: _isConverting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            _isConverting
                ? 'Converting...'
                : 'Convert to PDF (${_images.length})',
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
}
