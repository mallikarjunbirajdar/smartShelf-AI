import 'package:get/get.dart';

import '../controllers/photo_detect_controller.dart';

class PhotoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhotoDetectController>(() => PhotoDetectController());
  }
}
