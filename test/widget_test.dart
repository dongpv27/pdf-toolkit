// Basic smoke test for the PDF Toolkit home screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_toolkit/main.dart';

void main() {
  testWidgets('Home screen shows the three PDF tools', (tester) async {
    await tester.pumpWidget(const PdfToolkitApp());
    await tester.pump();

    expect(find.text('Image to PDF'), findsOneWidget);
    expect(find.text('Merge PDF'), findsOneWidget);
    expect(find.text('Compress PDF'), findsOneWidget);
  });
}
