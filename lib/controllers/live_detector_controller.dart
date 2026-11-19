import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/detection_model.dart';
import '../services/image_preprocessor_service.dart';
import '../services/scan_history_service.dart';
import '../services/yolo_detector_service.dart';

class LiveDetectorController extends GetxController {
  final cameraReady = false.obs;
  final detecting = true.obs;
  final recording = false.obs;
  final confidence = 0.35.obs;
  final error = RxnString();
  final detections = Rxn<FrameDetections>();

  CameraController? cameraController;

  bool _busy = false;
  int _frameSkip = 0;
  int _shelfEvery = 0;
  List<Detection> _lastShelves = const [];

  YoloDetectorService get _detector => Get.find<YoloDetectorService>();
  ScanHistoryService get _history => Get.find<ScanHistoryService>();

  @override
  void onInit() {
    super.onInit();
    initCamera();
  }

  Future<void> initCamera() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted) {
      error.value = 'Camera permission denied';
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: mic.isGranted,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.startImageStream(onFrame);
      cameraController = controller;
      cameraReady.value = true;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> onFrame(CameraImage image) async {
    if (!detecting.value || _busy || cameraController == null) return;
    _frameSkip = (_frameSkip + 1) % 2;
    if (_frameSkip != 0) return;

    _busy = true;
    try {
      final input = ImagePreprocessorService.fromCameraImage(
        image,
        sensorOrientation: cameraController!.description.sensorOrientation,
        lensDirection: cameraController!.description.lensDirection,
      );

      final runShelf = _shelfEvery % 3 == 0;
      _shelfEvery++;

      final result = await _detector.detect(
        input,
        productConf: confidence.value,
        shelfConf: 0.25,
        runShelf: runShelf,
      );

      if (runShelf) {
        _lastShelves = result.shelves;
      }

      detections.value = FrameDetections(
        shelves: _lastShelves,
        products: result.products,
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        inferenceMs: result.inferenceMs,
      );
    } catch (_) {
      // Drop failed frames.
    } finally {
      _busy = false;
    }
  }

  void setDetecting(bool value) => detecting.value = value;

  void setConfidence(double value) => confidence.value = value;

  Future<void> toggleRecording() async {
    final c = cameraController;
    if (c == null || !c.value.isInitialized) return;

    if (recording.value) {
      final file = await c.stopVideoRecording();
      recording.value = false;
      // Save last live detections with this video session.
      final dets = detections.value;
      if (dets != null) {
        await _history.addFromDetection(
          result: dets,
          source: 'video',
          customTitle: 'Video scan',
        );
      }
      Get.snackbar(
        'Video saved',
        dets == null
            ? file.path
            : '${dets.shelves.length} shelves, ${dets.productCount} products · ${file.path}',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (!c.value.isStreamingImages) {
        await c.startImageStream(onFrame);
      }
      return;
    }

    if (c.value.isStreamingImages) {
      await c.stopImageStream();
    }
    await c.startVideoRecording();
    recording.value = true;
  }

  Future<void> captureStill() async {
    final c = cameraController;
    if (c == null || !c.value.isInitialized) return;
    final wasStreaming = c.value.isStreamingImages;
    if (wasStreaming) await c.stopImageStream();
    final file = await c.takePicture();
    try {
      final bytes = await file.readAsBytes();
      final decoded = ImagePreprocessorService.decodeFileBytes(bytes);
      if (decoded != null) {
        final input = ImagePreprocessorService.fromImage(decoded);
        final result = await _detector.detect(
          input,
          productConf: confidence.value,
        );
        detections.value = result;
        final thumb = await _history.saveThumbnail(bytes);
        await _history.addFromDetection(
          result: result,
          source: 'live',
          imagePath: thumb,
        );
        Get.snackbar(
          'Scan saved',
          '${result.shelves.length} shelves, ${result.productCount} products',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar('Photo saved', file.path, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Capture failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (wasStreaming && !recording.value) {
        await c.startImageStream(onFrame);
      }
    }
  }

  @override
  void onClose() {
    final c = cameraController;
    cameraController = null;
    if (c != null) {
      if (c.value.isStreamingImages) {
        c.stopImageStream().whenComplete(c.dispose);
      } else {
        c.dispose();
      }
    }
    super.onClose();
  }
}
