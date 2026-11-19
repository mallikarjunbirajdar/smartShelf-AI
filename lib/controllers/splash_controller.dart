import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../services/yolo_detector_service.dart';

class SplashController extends GetxController {
  final progress = 0.0.obs;
  final statusText = 'Starting SmartShelf AI…'.obs;

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      statusText.value = 'Preparing camera engine…';
      progress.value = 0.25;
      await Future<void>.delayed(const Duration(milliseconds: 450));

      statusText.value = 'Loading AI models…';
      progress.value = 0.55;
      final detector = Get.find<YoloDetectorService>();
      if (!detector.isReady) {
        await detector.init();
      }

      statusText.value = 'Almost ready…';
      progress.value = 0.9;
      await Future<void>.delayed(const Duration(milliseconds: 350));

      progress.value = 1.0;
      statusText.value = 'Ready';
      await Future<void>.delayed(const Duration(milliseconds: 250));
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      statusText.value = 'Model load failed — continuing';
      progress.value = 1.0;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
