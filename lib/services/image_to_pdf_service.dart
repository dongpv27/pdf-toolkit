import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Result of a successful conversion.
class ConversionResult {
  const ConversionResult({required this.file, required this.pageCount});

  final File file;
  final int pageCount;

  String get path => file.path;
}

/// Converts images into a single PDF document, fully offline.
///
/// Each image is placed on its own A4 page, scaled to fit while keeping its
/// aspect ratio. The generated file is written to the app's documents
/// directory, which requires no runtime storage permission.
class ImageToPdfService {
  const ImageToPdfService();

  /// Builds a PDF from [imagePaths] and saves it locally.
  ///
  /// Throws [ArgumentError] if [imagePaths] is empty.
  Future<ConversionResult> convert(
    List<String> imagePaths, {
    String? fileName,
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('At least one image is required.');
    }

    // Build the PDF on a background isolate so the UI stays responsive even
    // for many / large images.
    final bytes = await compute(_buildImagePdf, imagePaths);

    final outputDir = await getApplicationDocumentsDirectory();
    final name = _resolveFileName(fileName);
    final file = File('${outputDir.path}/$name');
    await file.writeAsBytes(bytes);

    return ConversionResult(file: file, pageCount: imagePaths.length);
  }

  String _resolveFileName(String? fileName) {
    if (fileName != null && fileName.trim().isNotEmpty) {
      final trimmed = fileName.trim();
      return trimmed.toLowerCase().endsWith('.pdf')
          ? trimmed
          : '$trimmed.pdf';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'images_$timestamp.pdf';
  }
}

/// Runs on a background isolate (via `compute`). Reads each image and builds a
/// single PDF, one image per A4 page, returning the encoded bytes.
Future<Uint8List> _buildImagePdf(List<String> imagePaths) async {
  final document = pw.Document();

  for (final path in imagePaths) {
    final bytes = File(path).readAsBytesSync();
    final image = pw.MemoryImage(bytes);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  return document.save();
}
