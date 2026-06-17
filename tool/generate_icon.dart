// Generates the PDF Toolkit app icon (no external design tools needed).
//
//   dart run tool/generate_icon.dart
//
// Produces:
//   assets/icon/icon.png            — full 1024 icon (blue bg + document)
//   assets/icon/icon_foreground.png — adaptive foreground (padded, transparent)
//
// Design: a white document with a folded corner, content lines and a blue
// accent line, on a rounded blue (#2563EB) background — trustworthy & modern.

import 'dart:io';

import 'package:image/image.dart' as img;

// Brand palette
final _blue = img.ColorRgba8(0x25, 0x63, 0xEB, 0xFF); // #2563EB primary
final _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
final _grayLine = img.ColorRgba8(0xCB, 0xD5, 0xE1, 0xFF); // #CBD5E1
final _foldGray = img.ColorRgba8(0xD9, 0xE2, 0xEC, 0xFF); // soft fold shade

const _size = 1024;

void main() {
  _writeIcon('assets/icon/icon.png', withBackground: true);
  _writeIcon('assets/icon/icon_foreground.png', withBackground: false);
  stdout.writeln('Icons generated in assets/icon/');
}

void _writeIcon(String path, {required bool withBackground}) {
  final image = img.Image(width: _size, height: _size, numChannels: 4);

  if (withBackground) {
    img.fillRect(image,
        x1: 0, y1: 0, x2: _size - 1, y2: _size - 1, color: _blue, radius: 224);
    _drawDocument(image, left: 287, top: 222, right: 737, bottom: 802,
        fold: 116, lineH: 32, accentW: 197);
  } else {
    // Adaptive foreground: smaller & centered to survive the safe-zone mask.
    _drawDocument(image, left: 332, top: 277, right: 692, bottom: 747,
        fold: 92, lineH: 26, accentW: 156);
  }

  File(path).writeAsBytesSync(img.encodePng(image));
}

void _drawDocument(
  img.Image image, {
  required int left,
  required int top,
  required int right,
  required int bottom,
  required int fold,
  required int lineH,
  required int accentW,
}) {
  // Page body.
  img.fillRect(image,
      x1: left, y1: top, x2: right, y2: bottom, color: _white, radius: 32);

  // Folded top-right corner (dog-ear): a soft-gray triangle.
  img.fillPolygon(image, color: _foldGray, vertices: [
    img.Point(right - fold, top),
    img.Point(right, top),
    img.Point(right, top + fold),
  ]);

  // Content lines.
  final pad = ((right - left) * 0.13).round();
  final lineLeft = left + pad;
  final lineRight = right - pad;
  final radius = lineH ~/ 2;

  // Start below the folded corner, evenly spaced.
  final firstY = top + fold + (lineH * 1.4).round();
  final gap = (lineH * 2.2).round();

  for (var i = 0; i < 3; i++) {
    final y = firstY + gap * i;
    img.fillRect(image,
        x1: lineLeft, y1: y, x2: lineRight, y2: y + lineH,
        color: _grayLine, radius: radius);
  }

  // Blue accent line (shorter) — a pop of brand color.
  final accentY = firstY + gap * 3;
  img.fillRect(image,
      x1: lineLeft, y1: accentY, x2: lineLeft + accentW, y2: accentY + lineH,
      color: _blue, radius: radius);
}
