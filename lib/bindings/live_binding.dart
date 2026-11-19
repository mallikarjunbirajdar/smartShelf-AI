import 'package:get/get.dart';

import '../controllers/live_detector_controller.dart';

class LiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveDetectorController>(() => LiveDetectorController());
  }
}
