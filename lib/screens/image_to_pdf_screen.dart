import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_to_pdf_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
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

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
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

    setState(() => _isConverting = true);
    try {
      final result = await _service.convert(
        _images.map((x) => x.path).toList(),
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
              message: 'Pick photos from your gallery to combine them into a single PDF.',
              actionLabel: 'Pick Images',
              onAction: _isConverting ? null : _pickImages,
              accentColor: _accent,
            )
          : _buildGrid(),
      bottomNavigationBar: _images.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(image.path), fit: BoxFit.cover),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isConverting ? null : () => _removeImage(index),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
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
