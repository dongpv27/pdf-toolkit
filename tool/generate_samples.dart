// Generates sample JPG images and PDF files for testing the app on a device
// or emulator.
//   dart run tool/generate_samples.dart
//
// Output (build/samples/):
//   sample_1.jpg ... sample_10.jpg  — for Image→PDF (pick several at once)
//   doc_1.pdf ... doc_4.pdf         — small text PDFs for Merge PDF
//   photos.pdf                      — image-heavy PDF for Compress PDF
//                                     (large on purpose so compression shows
//                                      a real size reduction)

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _palette = <List<int>>[
  [0x25, 0x63, 0xEB], // blue
  [0x16, 0xA3, 0x4A], // green
  [0xD9, 0x77, 0x06], // amber
  [0xDC, 0x26, 0x26], // red
  [0x7C, 0x3A, 0xED], // violet
  [0x0E, 0xA5, 0xE9], // sky
  [0xDB, 0x27, 0x77], // pink
  [0x65, 0xA3, 0x0D], // lime
  [0xEA, 0x58, 0x0C], // orange
  [0x05, 0x96, 0x69], // teal
];

/// A clean, flat-colour labelled card — good for Image→PDF previews.
List<int> _makeImage(int index) {
  final c = _palette[index % _palette.length];
  final image = img.Image(width: 1080, height: 1440, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(c[0], c[1], c[2]));
  img.fillRect(image,
      x1: 120, y1: 300, x2: 960, y2: 1140,
      color: img.ColorRgb8(255, 255, 255), radius: 48);
  img.drawString(image, 'SAMPLE ${index + 1}',
      font: img.arial48, x: 400, y: 690,
      color: img.ColorRgb8(c[0], c[1], c[2]));
  return img.encodeJpg(image, quality: 90);
}

/// A large, noisy "photo-like" image. Random detail keeps the JPG big, so the
/// Compress feature (which re-rasterises at a lower DPI) yields a visible cut.
Uint8List _makePhoto() {
  var image = img.Image(width: 1600, height: 2000, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(120, 130, 150));
  image = img.noise(image, 70); // gaussian noise -> incompressible detail
  return img.encodeJpg(image, quality: 92);
}

Future<void> main() async {
  final dir = Directory('build/samples')..createSync(recursive: true);

  // --- 10 images (Image -> PDF) ---------------------------------------------
  for (var i = 0; i < 10; i++) {
    final path = '${dir.path}/sample_${i + 1}.jpg';
    File(path).writeAsBytesSync(_makeImage(i));
    stdout.writeln('wrote $path');
  }

  // --- 4 small text PDFs (Merge PDF) ----------------------------------------
  for (var i = 0; i < 4; i++) {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Text(
            'Document ${i + 1}',
            style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
    );
    final path = '${dir.path}/doc_${i + 1}.pdf';
    File(path).writeAsBytesSync(await doc.save());
    stdout.writeln('wrote $path');
  }

  // --- 1 image-heavy PDF (Compress PDF) -------------------------------------
  final photoBytes = _makePhoto();
  final photo = pw.MemoryImage(photoBytes);
  final compressDoc = pw.Document();
  for (var page = 0; page < 4; page++) {
    compressDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Image(photo, fit: pw.BoxFit.cover),
      ),
    );
  }
  final photosPath = '${dir.path}/photos.pdf';
  File(photosPath).writeAsBytesSync(await compressDoc.save());
  stdout.writeln('wrote $photosPath');

  stdout.writeln('\nDone. Files in ${dir.path}');
}
