import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// User-facing compression strength.
enum CompressionLevel {
  low('Low', 'Light optimization, best quality'),
  medium('Medium', 'Balanced size and quality'),
  high('High', 'Smallest size');

  const CompressionLevel(this.label, this.description);

  final String label;
  final String description;

  /// Maps to a Syncfusion content-stream compression level.
  PdfCompressionLevel get pdfLevel => switch (this) {
        CompressionLevel.low => PdfCompressionLevel.belowNormal,
        CompressionLevel.medium => PdfCompressionLevel.normal,
        CompressionLevel.high => PdfCompressionLevel.best,
      };
}

/// Result of a compression run.
class CompressionResult {
  const CompressionResult({
    required this.file,
    required this.originalBytes,
    required this.compressedBytes,
  });

  final File file;
  final int originalBytes;
  final int compressedBytes;

  String get path => file.path;

  /// Fraction of size saved (0.0 - 1.0). Clamped at 0 if the file grew.
  double get savedRatio {
    if (originalBytes <= 0) return 0;
    final saved = (originalBytes - compressedBytes) / originalBytes;
    return saved < 0 ? 0 : saved;
  }
}

/// Compresses a single PDF file, fully offline.
///
/// Uses Syncfusion's content-stream compression plus image re-encoding. The
/// result is saved to the app's documents directory (no runtime storage
/// permission required).
class PdfCompressService {
  const PdfCompressService();

  Future<CompressionResult> compress(
    String pdfPath, {
    CompressionLevel level = CompressionLevel.medium,
    String? fileName,
  }) async {
    final input = File(pdfPath);
    if (!await input.exists()) {
      throw Exception('File not found: $pdfPath');
    }

    final originalBytes = await input.length();

    final PdfDocument document;
    try {
      document = PdfDocument(inputBytes: await input.readAsBytes());
    } catch (_) {
      throw Exception('Could not read PDF: ${_baseName(pdfPath)}');
    }

    final List<int> bytes;
    try {
      // Compress page content streams and drop incremental-update history so
      // the whole file is rewritten compactly rather than appended to.
      document.compressionLevel = level.pdfLevel;
      document.fileStructure.incrementalUpdate = false;
      bytes = await document.save();
    } finally {
      document.dispose();
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final name = _resolveFileName(fileName, level);
    final outFile = File('${outputDir.path}/$name');
    await outFile.writeAsBytes(bytes);

    return CompressionResult(
      file: outFile,
      originalBytes: originalBytes,
      compressedBytes: bytes.length,
    );
  }

  String _baseName(String path) => path.split(RegExp(r'[\\/]')).last;

  String _resolveFileName(String? fileName, CompressionLevel level) {
    if (fileName != null && fileName.trim().isNotEmpty) {
      final trimmed = fileName.trim();
      return trimmed.toLowerCase().endsWith('.pdf') ? trimmed : '$trimmed.pdf';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'compressed_${level.name}_$timestamp.pdf';
  }
}
