import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../models/capture_mode.dart';
import '../models/detection_model.dart';
import '../services/image_preprocessor_service.dart';
import '../services/product_label_service.dart';
import '../services/scan_history_service.dart';
import '../services/yolo_detector_service.dart';

class PhotoDetectController extends GetxController {
  final mode = CaptureMode.camera.obs;
  final recording = false.obs;
  final processing = false.obs;
  final error = RxnString();
  final detections = Rxn<FrameDetections>();
  final previewBytes = Rxn<Uint8List>();
  final videoPath = RxnString();
  final cameraReady = false.obs;

  CameraController? cameraController;
  XFile? _photo;

  YoloDetectorService get _detector => Get.find<YoloDetectorService>();
  ProductLabelService get _labels => Get.find<ProductLabelService>();
  ScanHistoryService get _history => Get.find<ScanHistoryService>();

  /// 'photo' | 'video' from Get.arguments
  String entryMode = 'photo';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['mode'] is String) {
      entryMode = args['mode'] as String;
    }
    initCamera();
  }

  @override
  void onReady() {
    super.onReady();
    if (entryMode == 'video') {
      Get.snackbar(
        'Record video',
        'Tap Record Video to start capturing the shelf.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      error.value = 'Camera permission denied';
      return;
    }
    await Permission.microphone.request();

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      cameraController = controller;
      cameraReady.value = true;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> capture() async {
    final c = cameraController;
    if (c == null || !c.value.isInitialized || recording.value) return;
    final file = await c.takePicture();
    final bytes = await file.readAsBytes();
    _photo = file;
    videoPath.value = null;
    previewBytes.value = bytes;
    detections.value = null;
    mode.value = CaptureMode.review;
  }

  Future<void> toggleVideo() async {
    final c = cameraController;
    if (c == null || !c.value.isInitialized) return;
    if (recording.value) {
      final file = await c.stopVideoRecording();
      recording.value = false;
      videoPath.value = file.path;
      // After video stops, grab a still frame and run AI detection.
      await _captureAndDetectFromVideo(c);
      return;
    }
    await c.startVideoRecording();
    recording.value = true;
  }

  /// Takes a still after video recording and runs YOLO detection.
  Future<void> _captureAndDetectFromVideo(CameraController c) async {
    processing.value = true;
    mode.value = CaptureMode.review;
    try {
      // Small delay so camera session settles after video stop.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final still = await c.takePicture();
      final bytes = await still.readAsBytes();
      _photo = still;
      previewBytes.value = bytes;

      final decoded = ImagePreprocessorService.decodeFileBytes(bytes);
      if (decoded == null) throw Exception('Could not decode video frame');
      final input = ImagePreprocessorService.fromImage(decoded);
      final result = await _withNames(decoded, await _detector.detect(input));
      detections.value = result;
      mode.value = CaptureMode.result;
      await _saveScan(
        result,
        bytes,
        source: 'video',
        title: 'Video scan',
      );
      Get.snackbar(
        'Video + detection saved',
        _savedMessage(result),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = e.toString();
      mode.value = CaptureMode.review;
      Get.snackbar(
        'Video saved',
        'Detection failed: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processing.value = false;
    }
  }

  void retake() {
    _photo = null;
    videoPath.value = null;
    previewBytes.value = null;
    detections.value = null;
    mode.value = CaptureMode.camera;
  }

  void goToCamera() => mode.value = CaptureMode.camera;

  Future<void> process() async {
    if (_photo == null && videoPath.value == null) return;
    processing.value = true;

    try {
      // If only video exists (no still yet), capture one now for AI.
      if (_photo == null) {
        final c = cameraController;
        if (c == null || !c.value.isInitialized) {
          Get.snackbar(
            'Cannot process',
            'Camera not ready. Retake and capture a photo.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        await _captureAndDetectFromVideo(c);
        return;
      }

      final bytes = await _photo!.readAsBytes();
      final decoded = ImagePreprocessorService.decodeFileBytes(bytes);
      if (decoded == null) throw Exception('Could not decode image');
      final input = ImagePreprocessorService.fromImage(decoded);
      final result = await _withNames(decoded, await _detector.detect(input));
      detections.value = result;
      previewBytes.value = bytes;
      mode.value = CaptureMode.result;
      await _saveScan(
        result,
        bytes,
        source: videoPath.value != null ? 'video' : 'photo',
      );
    } catch (e) {
      error.value = e.toString();
    } finally {
      processing.value = false;
    }
  }

  Future<void> processAsset(String assetPath) async {
    processing.value = true;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final decoded = ImagePreprocessorService.decodeFileBytes(bytes);
      if (decoded == null) throw Exception('Could not decode asset');
      final input = ImagePreprocessorService.fromImage(decoded);
      final result = await _withNames(decoded, await _detector.detect(input));
      previewBytes.value = bytes;
      detections.value = result;
      mode.value = CaptureMode.result;
      _photo = null;
      videoPath.value = null;
      await _saveScan(result, bytes, source: 'photo', title: 'Test image scan');
    } catch (e) {
      error.value = e.toString();
    } finally {
      processing.value = false;
    }
  }

  Future<FrameDetections> _withNames(
    img.Image image,
    FrameDetections result,
  ) {
    return _labels.annotate(image, result);
  }

  String _savedMessage(FrameDetections result) {
    final names = result.namedProductsLabel;
    final counts =
        '${result.shelves.length} lanes, ${result.productCount} products · ${result.avgConfidencePercent}% conf';
    if (names.isEmpty) return counts;
    return '$names · $counts';
  }

  Future<void> _saveScan(
    FrameDetections result,
    List<int> bytes, {
    required String source,
    String? title,
  }) async {
    final thumb = await _history.saveThumbnail(bytes);
    await _history.addFromDetection(
      result: result,
      source: source,
      imagePath: thumb,
      customTitle: title,
    );
  }

  @override
  void onClose() {
    cameraController?.dispose();
    cameraController = null;
    super.onClose();
  }
}
