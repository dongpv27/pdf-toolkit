import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  AdService.instance.loadAds();
  runApp(const PdfToolkitApp());
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
