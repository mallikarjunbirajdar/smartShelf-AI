import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../models/recent_scan_model.dart';
import '../services/scan_history_service.dart';
import '../services/yolo_detector_service.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final error = RxnString();

  ScanHistoryService get _history => Get.find<ScanHistoryService>();
  YoloDetectorService get _detector => Get.find<YoloDetectorService>();

  /// Live list from photo / live detections (no hardcoded sample data).
  RxList<RecentScan> get recentScans => _history.scans;

  @override
  void onInit() {
    super.onInit();
    _ensureModels();
  }

  Future<void> _ensureModels() async {
    if (_detector.isReady) return;
    try {
      isLoading.value = true;
      error.value = null;
      await _detector.init();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      error.value = e.toString();
    }
  }

  void startLiveDetection() => Get.toNamed(AppRoutes.live);

  void openCapturePhoto() =>
      Get.toNamed(AppRoutes.photo, arguments: {'mode': 'photo'});

  void openRecordVideo() =>
      Get.toNamed(AppRoutes.photo, arguments: {'mode': 'video'});

  Future<void> clearHistory() async {
    await _history.clear();
  }

  Future<void> deleteScan(String id) async {
    await _history.deleteScan(id);
  }
}
