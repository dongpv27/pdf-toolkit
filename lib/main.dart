import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'services/ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PdfToolkitApp());
  // Gather GDPR/UMP consent and initialize ads in the background so the UI
  // shows immediately. Ads load only after consent allows it.
  AdService.instance.initialize();
}

class PdfToolkitApp extends StatelessWidget {
  const PdfToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PDF Toolkit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
