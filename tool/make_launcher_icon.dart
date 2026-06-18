// Builds a launcher-optimized icon from the full Play-Store logo by cropping a
// square region around the document + PDF badge, dropping the bottom feature
// bar ("Image to PDF / Merge / Compress").
//
//   dart run tool/make_launcher_icon.dart
// Input:  assets/icon/logo-app.png   (full square Play-Store logo)
// Output: assets/icon/logo-launcher.png

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/icon/logo-app.png').readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode logo-app.png');
    exit(1);
  }

  final w = src.width;
  final h = src.height;

  // Square region: full height above the feature bar (~72%), shifted slightly
  // left so the PDF badge (which juts left of the document) stays fully inside.
  final side = (h * 0.72).round();
  var x = ((w - side) / 2).round() - 40;
  if (x < 0) x = 0;
  if (x + side > w) x = w - side;

  final cropped = img.copyCrop(src, x: x, y: 0, width: side, height: side);

  File('assets/icon/logo-launcher.png')
      .writeAsBytesSync(img.encodePng(cropped));
  stdout.writeln('wrote assets/icon/logo-launcher.png (${side}x$side)');

  // Play Store listing icon: identical design, exactly 512x512, so the store
  // icon matches the on-device launcher icon.
  final store = img.copyResize(cropped, width: 512, height: 512,
      interpolation: img.Interpolation.cubic);
  File('assets/icon/logo-store-512.png')
      .writeAsBytesSync(img.encodePng(store));
  stdout.writeln('wrote assets/icon/logo-store-512.png (512x512)');
}
