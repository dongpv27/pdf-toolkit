import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// User-facing compression strength. Each level maps to a render resolution
/// (DPI) and JPEG quality — lower values = smaller file, lower fidelity.
enum CompressionLevel {
  low('Low', 'Light compression, best quality', 144, 75),
  medium('Medium', 'Balanced size and quality', 110, 55),
  high('High', 'Smallest size', 88, 40);

  const CompressionLevel(this.label, this.description, this.dpi, this.quality);

  final String label;
  final String description;

  /// Rasterization resolution in dots-per-inch.
  final double dpi;

  /// JPEG quality (0-100) for re-encoded pages.
  final int quality;
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
/// Each page is rasterized at the level's DPI and re-encoded as a JPEG, then a
/// new PDF is assembled from those images. This genuinely reduces the size of
/// image-heavy / scanned PDFs. Note: vector text becomes a raster image, so
/// this is a quality-vs-size tradeoff (as in most "compress PDF" tools).
///
/// If rasterizing does not actually shrink the file (e.g. a small text-only
/// PDF), the original bytes are kept so the user never gets a larger file.
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

    final originalBytes = await input.readAsBytes();

    final Uint8List compressed;
    try {
      compressed = await _rasterizeAndReencode(originalBytes, level);
    } catch (_) {
      throw Exception('Could not read PDF: ${_baseName(pdfPath)}');
    }

    // Never hand back a bigger file than we started with.
    final outputBytes =
        compressed.length < originalBytes.length ? compressed : originalBytes;

    final outputDir = await getApplicationDocumentsDirectory();
    final name = _resolveFileName(fileName, level);
    final outFile = File('${outputDir.path}/$name');
    await outFile.writeAsBytes(outputBytes);

    return CompressionResult(
      file: outFile,
      originalBytes: originalBytes.length,
      compressedBytes: outputBytes.length,
    );
  }

  Future<Uint8List> _rasterizeAndReencode(
    Uint8List bytes,
    CompressionLevel level,
  ) async {
    final document = pw.Document();

    await for (final page in Printing.raster(bytes, dpi: level.dpi)) {
      // page.pixels is raw RGBA; re-encode it as a (lossy) JPEG.
      final rgba = img.Image.fromBytes(
        width: page.width,
        height: page.height,
        bytes: page.pixels.buffer,
        numChannels: 4,
      );
      final jpeg = img.encodeJpg(rgba, quality: level.quality);
      final image = pw.MemoryImage(Uint8List.fromList(jpeg));

      // Keep the page's physical size: pixels / dpi * 72 = points.
      final widthPt = page.width / level.dpi * PdfPageFormat.inch;
      final heightPt = page.height / level.dpi * PdfPageFormat.inch;

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(widthPt, heightPt),
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }

    return document.save();
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
