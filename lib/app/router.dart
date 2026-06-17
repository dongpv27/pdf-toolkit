import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/image_to_pdf_screen.dart';
import '../screens/merge_pdf_screen.dart';
import '../screens/compress_pdf_screen.dart';

/// App route paths and names kept in one place to avoid magic strings.
abstract class AppRoutes {
  static const home = '/';
  static const imageToPdf = '/image-to-pdf';
  static const mergePdf = '/merge-pdf';
  static const compressPdf = '/compress-pdf';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.imageToPdf,
      name: 'imageToPdf',
      builder: (context, state) => const ImageToPdfScreen(),
    ),
    GoRoute(
      path: AppRoutes.mergePdf,
      name: 'mergePdf',
      builder: (context, state) => const MergePdfScreen(),
    ),
    GoRoute(
      path: AppRoutes.compressPdf,
      name: 'compressPdf',
      builder: (context, state) => const CompressPdfScreen(),
    ),
  ],
);
