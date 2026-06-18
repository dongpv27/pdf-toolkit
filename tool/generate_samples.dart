// Generates a few sample JPG images for testing Image→PDF on the emulator.
//   dart run tool/generate_samples.dart
// Output: build/samples/sample_1.jpg ... sample_3.jpg

import 'dart:io';

import 'package:image/image.dart' as img;

final _palette = <List<int>>[
  [0x25, 0x63, 0xEB], // blue
  [0x16, 0xA3, 0x4A], // green
  [0xD9, 0x77, 0x06], // amber
];

void main() {
  Directory('build/samples').createSync(recursive: true);

  for (var i = 0; i < _palette.length; i++) {
    final c = _palette[i];
    final image = img.Image(width: 1080, height: 1440, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(c[0], c[1], c[2]));

    // White rounded card in the middle.
    img.fillRect(image,
        x1: 120, y1: 300, x2: 960, y2: 1140,
        color: img.ColorRgb8(255, 255, 255), radius: 48);

    // Big number label.
    img.drawString(image, 'SAMPLE ${i + 1}',
        font: img.arial48,
        x: 400, y: 690,
        color: img.ColorRgb8(c[0], c[1], c[2]));

    final path = 'build/samples/sample_${i + 1}.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(image, quality: 90));
    stdout.writeln('wrote $path');
  }
}
