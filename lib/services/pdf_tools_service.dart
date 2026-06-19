import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// One page kept in an "organize" operation: which source page it is, and how
/// many quarter-turns clockwise to rotate it (0..3).
class PageEdit {
  const PageEdit({required this.sourceIndex, this.quarterTurns = 0});

  final int sourceIndex;
  final int quarterTurns;
}

/// Page-level PDF operations (organize, split, export to images), fully offline.
///
/// Reorder / rotate / delete are lossless (pages are copied as templates and
/// rotated via the page `/Rotate` attribute). Export-to-images rasterizes pages.
class PdfToolsService {
  const PdfToolsService();

  Future<int> pageCount(String path) async {
    final doc = PdfDocument(inputBytes: await File(path).readAsBytes());
    final count = doc.pages.count;
    doc.dispose();
    return count;
  }

  /// Renders each page to a small PNG for thumbnails (display only).
  Future<List<Uint8List>> renderThumbnails(String path, {double dpi = 36}) async {
    final bytes = await File(path).readAsBytes();
    final thumbs = <Uint8List>[];
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      thumbs.add(await page.toPng());
    }
    return thumbs;
  }

  /// Renders a single page (by 0-based index) to a PNG — used by the in-app
  /// viewer to render pages lazily as the user scrolls.
  Future<Uint8List> renderPagePng(
    Uint8List bytes,
    int pageIndex, {
    double dpi = 120,
  }) async {
    await for (final page in Printing.raster(bytes, pages: [pageIndex], dpi: dpi)) {
      return page.toPng();
    }
    throw Exception('Could not render page ${pageIndex + 1}');
  }

  /// Rebuilds the PDF using [edits] as the new page order, applying rotations
  /// and dropping any source page not present. Saved to the documents dir.
  Future<File> organize(
    String srcPath,
    List<PageEdit> edits, {
    String? fileName,
  }) async {
    final bytes = await File(srcPath).readAsBytes();
    final outBytes = await compute(_organize, _OrganizeParams(bytes, edits));

    final dir = await getApplicationDocumentsDirectory();
    final name = _withPdf(fileName, 'organized_${_stamp()}');
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(outBytes);
    return file;
  }

  /// Splits the PDF into one file per page. Returns the created files.
  Future<List<File>> splitToSinglePages(
    String srcPath, {
    String? baseName,
  }) async {
    final bytes = await File(srcPath).readAsBytes();
    final pages = await compute(_splitPages, bytes);

    final dir = await getApplicationDocumentsDirectory();
    final base = (baseName == null || baseName.trim().isEmpty)
        ? 'page'
        : baseName.trim();
    final files = <File>[];
    for (var i = 0; i < pages.length; i++) {
      final f = File('${dir.path}/${base}_${i + 1}.pdf');
      await f.writeAsBytes(pages[i]);
      files.add(f);
    }
    return files;
  }

  /// Extracts pages [from]..[to] (1-based, inclusive) into a single new PDF.
  Future<File> extractRange(
    String srcPath,
    int from,
    int to, {
    String? fileName,
  }) async {
    final bytes = await File(srcPath).readAsBytes();
    final outBytes =
        await compute(_extractRange, _RangeParams(bytes, from, to));

    final dir = await getApplicationDocumentsDirectory();
    final name = _withPdf(fileName, 'extract_${from}_${to}_${_stamp()}');
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(outBytes);
    return file;
  }

  /// Renders every page to a JPEG saved in the documents dir. Returns the files.
  Future<List<File>> toImages(
    String srcPath, {
    double dpi = 150,
    int quality = 85,
    String? baseName,
  }) async {
    final bytes = await File(srcPath).readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final base = (baseName == null || baseName.trim().isEmpty)
        ? 'image'
        : baseName.trim();

    final files = <File>[];
    var index = 1;
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      final jpeg = await compute(
        _encodeJpg,
        _JpgParams(page.pixels, page.width, page.height, quality),
      );
      final f = File('${dir.path}/${base}_$index.jpg');
      await f.writeAsBytes(jpeg);
      files.add(f);
      index++;
    }
    return files;
  }

  String _withPdf(String? name, String fallback) {
    final n = (name == null || name.trim().isEmpty) ? fallback : name.trim();
    return n.toLowerCase().endsWith('.pdf') ? n : '$n.pdf';
  }

  int _stamp() => DateTime.now().millisecondsSinceEpoch;
}

// --- isolate params -------------------------------------------------------

class _OrganizeParams {
  const _OrganizeParams(this.bytes, this.edits);
  final Uint8List bytes;
  final List<PageEdit> edits;
}

class _RangeParams {
  const _RangeParams(this.bytes, this.from, this.to);
  final Uint8List bytes;
  final int from;
  final int to;
}

class _JpgParams {
  const _JpgParams(this.pixels, this.width, this.height, this.quality);
  final Uint8List pixels;
  final int width;
  final int height;
  final int quality;
}

// --- isolate workers ------------------------------------------------------

PdfPageRotateAngle _angle(int quarterTurns) {
  switch (quarterTurns % 4) {
    case 1:
      return PdfPageRotateAngle.rotateAngle90;
    case 2:
      return PdfPageRotateAngle.rotateAngle180;
    case 3:
      return PdfPageRotateAngle.rotateAngle270;
    default:
      return PdfPageRotateAngle.rotateAngle0;
  }
}

Future<Uint8List> _organize(_OrganizeParams p) async {
  final source = PdfDocument(inputBytes: p.bytes);
  final output = PdfDocument();
  try {
    for (final edit in p.edits) {
      if (edit.sourceIndex < 0 || edit.sourceIndex >= source.pages.count) {
        continue;
      }
      final srcPage = source.pages[edit.sourceIndex];
      final size = srcPage.size;
      final template = srcPage.createTemplate();

      output.pageSettings.margins.all = 0;
      output.pageSettings.size = size;
      final newPage = output.pages.add();
      newPage.graphics.drawPdfTemplate(template, Offset.zero, size);
      if (edit.quarterTurns % 4 != 0) {
        newPage.rotation = _angle(edit.quarterTurns);
      }
    }
    return Uint8List.fromList(await output.save());
  } finally {
    output.dispose();
    source.dispose();
  }
}

Future<List<Uint8List>> _splitPages(Uint8List bytes) async {
  final source = PdfDocument(inputBytes: bytes);
  final out = <Uint8List>[];
  try {
    for (var i = 0; i < source.pages.count; i++) {
      final single = PdfDocument();
      final srcPage = source.pages[i];
      final size = srcPage.size;
      single.pageSettings.margins.all = 0;
      single.pageSettings.size = size;
      final newPage = single.pages.add();
      newPage.graphics.drawPdfTemplate(srcPage.createTemplate(), Offset.zero, size);
      out.add(Uint8List.fromList(await single.save()));
      single.dispose();
    }
    return out;
  } finally {
    source.dispose();
  }
}

Future<Uint8List> _extractRange(_RangeParams p) async {
  final source = PdfDocument(inputBytes: p.bytes);
  final output = PdfDocument();
  try {
    final from = (p.from - 1).clamp(0, source.pages.count - 1);
    final to = (p.to - 1).clamp(0, source.pages.count - 1);
    final lo = from <= to ? from : to;
    final hi = from <= to ? to : from;
    for (var i = lo; i <= hi; i++) {
      final srcPage = source.pages[i];
      final size = srcPage.size;
      output.pageSettings.margins.all = 0;
      output.pageSettings.size = size;
      final newPage = output.pages.add();
      newPage.graphics.drawPdfTemplate(srcPage.createTemplate(), Offset.zero, size);
    }
    return Uint8List.fromList(await output.save());
  } finally {
    output.dispose();
    source.dispose();
  }
}

Uint8List _encodeJpg(_JpgParams p) {
  final rgba = img.Image.fromBytes(
    width: p.width,
    height: p.height,
    bytes: p.pixels.buffer,
    numChannels: 4,
  );
  return Uint8List.fromList(img.encodeJpg(rgba, quality: p.quality));
}
