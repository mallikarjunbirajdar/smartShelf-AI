import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'services/product_label_service.dart';
import 'services/scan_history_service.dart';
import 'services/yolo_detector_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  Get.put(YoloDetectorService(), permanent: true);
  Get.put(ProductLabelService(), permanent: true);
  await Get.putAsync<ScanHistoryService>(
    () async => ScanHistoryService().init(),
    permanent: true,
  );
  runApp(const ShelfAiApp());
}

class ShelfAiApp extends StatelessWidget {
  const ShelfAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SmartShelf AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
          primary: const Color(0xFF3B82F6),
        ),
        textTheme: GoogleFonts.dmSansTextTheme(),
      ),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
