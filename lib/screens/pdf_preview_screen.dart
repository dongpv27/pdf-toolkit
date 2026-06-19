import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pdf_tools_service.dart';

/// Lightweight in-app PDF viewer. Renders pages lazily (one at a time) so it
/// stays responsive and memory-friendly even for large documents.
class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key, required this.path, this.title});

  final String path;
  final String? title;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfToolsService _tools = const PdfToolsService();
  final Map<int, Uint8List> _cache = {};

  Uint8List? _bytes;
  int _pageCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.path);
      final bytes = await file.readAsBytes();
      final count = await _tools.pageCount(widget.path);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _pageCount = count;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<Uint8List> _page(int index) async {
    final cached = _cache[index];
    if (cached != null) return cached;
    final png = await _tools.renderPagePng(_bytes!, index);
    _cache[index] = png;
    return png;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Preview'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.shareXFiles([XFile(widget.path)]),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not open this PDF.\n$_error',
                        textAlign: TextAlign.center),
                  ),
                )
              : _buildPages(),
    );
  }

  Widget _buildPages() {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _pageCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<Uint8List>(
                future: _page(index),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const AspectRatio(
                      aspectRatio: 1 / 1.414, // A4-ish placeholder
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || snap.data == null) {
                    return const AspectRatio(
                      aspectRatio: 1 / 1.414,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    );
                  }
                  return InteractiveViewer(
                    maxScale: 4,
                    child: Image.memory(snap.data!, fit: BoxFit.fitWidth),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper so callers don't need to import the screen directly.
Future<void> openPdfPreview(BuildContext context, String path, {String? title}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PdfPreviewScreen(path: path, title: title),
    ),
  );
}
