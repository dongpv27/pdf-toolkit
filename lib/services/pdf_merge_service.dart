import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Result of a successful merge.
class MergeResult {
  const MergeResult({required this.file, required this.pageCount});

  final File file;
  final int pageCount;

  String get path => file.path;
}

/// Merges multiple PDF files into a single document, fully offline.
///
/// Every page of each source PDF is imported, in the given order, into one
/// output document saved to the app's documents directory (no runtime
/// storage permission required).
class PdfMergeService {
  const PdfMergeService();

  /// Merges [pdfPaths] into a single PDF and saves it locally.
  ///
  /// Throws [ArgumentError] if fewer than two files are provided and
  /// [Exception] if a source file cannot be read or parsed.
  Future<MergeResult> merge(
    List<String> pdfPaths, {
    String? fileName,
  }) async {
    if (pdfPaths.length < 2) {
      throw ArgumentError('Select at least two PDF files to merge.');
    }

    final PdfDocument output = PdfDocument();
    final List<PdfDocument> sources = [];

    try {
      for (final path in pdfPaths) {
        final file = File(path);
        if (!await file.exists()) {
          throw Exception('File not found: $path');
        }

        final PdfDocument source;
        try {
          source = PdfDocument(inputBytes: await file.readAsBytes());
        } catch (_) {
          throw Exception('Could not read PDF: ${_baseName(path)}');
        }
        sources.add(source);

        // Copy every page of this source into the output document. Each source
        // page is drawn as a template (a form XObject), which preserves vector
        // text/graphics losslessly while keeping the original page size.
        for (int i = 0; i < source.pages.count; i++) {
          final sourcePage = source.pages[i];
          final size = sourcePage.size;
          final template = sourcePage.createTemplate();

          output.pageSettings.margins.all = 0;
          output.pageSettings.size = size;
          final newPage = output.pages.add();
          newPage.graphics.drawPdfTemplate(template, Offset.zero, size);
        }
      }

      final bytes = await output.save();
      final pageCount = output.pages.count;

      final outputDir = await getApplicationDocumentsDirectory();
      final name = _resolveFileName(fileName);
      final outFile = File('${outputDir.path}/$name');
      await outFile.writeAsBytes(bytes);

      return MergeResult(file: outFile, pageCount: pageCount);
    } finally {
      output.dispose();
      for (final s in sources) {
        s.dispose();
      }
    }
  }

  String _baseName(String path) => path.split(RegExp(r'[\\/]')).last;

  String _resolveFileName(String? fileName) {
    if (fileName != null && fileName.trim().isNotEmpty) {
      final trimmed = fileName.trim();
      return trimmed.toLowerCase().endsWith('.pdf') ? trimmed : '$trimmed.pdf';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'merged_$timestamp.pdf';
  }
}
