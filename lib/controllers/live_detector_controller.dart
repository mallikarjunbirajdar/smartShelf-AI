import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../models/detection_model.dart';
import '../services/image_preprocessor_service.dart';
import '../services/product_label_service.dart';
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
  int _ocrTick = 0;
  int _nameTick = 0;
  List<Detection> _lastShelves = const [];
  final List<_TrackedName> _names = [];

  YoloDetectorService get _detector => Get.find<YoloDetectorService>();
  ProductLabelService get _labels => Get.find<ProductLabelService>();
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
      final oriented = ImagePreprocessorService.orientCameraImage(
        image,
        sensorOrientation: cameraController!.description.sensorOrientation,
        lensDirection: cameraController!.description.lensDirection,
      );
      final input = ImagePreprocessorService.fromImage(oriented);

      final runShelf = _shelfEvery % 2 == 0;
      _shelfEvery++;

      final result = await _detector.detect(
        input,
        productConf: confidence.value,
        shelfConf: 0.20,
        runShelf: runShelf,
      );

      if (runShelf) {
        _lastShelves = result.shelves;
      }

      final products = await _nameLiveProducts(oriented, result.products);

      detections.value = FrameDetections(
        shelves: _lastShelves,
        products: products,
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        inferenceMs: result.inferenceMs,
      );
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  Future<List<Detection>> _nameLiveProducts(
    img.Image image,
    List<Detection> products,
  ) async {
    _nameTick++;
    var named = _applyKnownNames(products);
    final waiting = named
        .where(
          (d) =>
              d.kind == DetectionKind.product &&
              d.label == 'Product' &&
              _shouldRead(d),
        )
        .toList();
    _ocrTick++;
    if (_ocrTick % 6 != 0 || waiting.isEmpty) return named;

    named = await _labels.applyNames(
      image,
      named,
      limit: 4,
      shouldRead: (d) =>
          d.kind == DetectionKind.product &&
          d.label == 'Product' &&
          _shouldRead(d),
    );
    _remember(named, waiting);
    return named;
  }

  void setDetecting(bool value) => detecting.value = value;

  void setConfidence(double value) => confidence.value = value;

  Future<void> toggleRecording() async {
    final c = cameraController;
    if (c == null || !c.value.isInitialized) return;

    if (recording.value) {
      final file = await c.stopVideoRecording();
      recording.value = false;
      try {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final still = await c.takePicture();
        final bytes = await still.readAsBytes();
        final decoded = ImagePreprocessorService.decodeFileBytes(bytes);
        String? thumb = await _history.saveThumbnail(bytes);

        FrameDetections? dets = detections.value;
        if (decoded != null) {
          final input = ImagePreprocessorService.fromImage(decoded);
          final detected = await _detector.detect(
            input,
            productConf: confidence.value,
          );
          dets = await _labels.annotate(decoded, detected);
          detections.value = dets;
        }

        if (dets != null) {
          await _history.addFromDetection(
            result: dets,
            source: 'video',
            customTitle: 'Video scan',
            imagePath: thumb,
          );
          final names = dets.namedProductsLabel;
          Get.snackbar(
            'Video + detection saved',
            names.isEmpty
                ? '${dets.shelves.length} lanes, ${dets.productCount} products'
                : '$names · ${dets.productCount} products',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Video saved',
            file.path,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
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
          dets == null ? file.path : 'Saved without preview: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
        final detected = await _detector.detect(
          input,
          productConf: confidence.value,
        );
        final result = await _labels.annotate(decoded, detected);
        detections.value = result;
        final thumb = await _history.saveThumbnail(bytes);
        await _history.addFromDetection(
          result: result,
          source: 'live',
          imagePath: thumb,
        );
        final names = result.namedProductsLabel;
        Get.snackbar(
          'Scan saved',
          names.isEmpty
              ? '${result.shelves.length} lanes, ${result.productCount} products · ${result.avgConfidencePercent}% conf'
              : '$names · ${result.productCount} products',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color.fromARGB(255, 254, 255, 255),
          colorText: Color.fromARGB(255, 0, 8, 19),
        );
      } else {
        Get.snackbar(
          'Photo saved',
          file.path,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Capture failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
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

  List<Detection> _applyKnownNames(List<Detection> products) {
    return products.map((det) {
      if (det.kind != DetectionKind.product) return det;
      final track = _trackFor(det.rect);
      if (track?.name == null) return det;
      track!.rect = det.rect;
      track.seen = _nameTick;
      return det.copyWith(label: track.name!);
    }).toList();
  }

  bool _shouldRead(Detection det) {
    final track = _trackFor(det.rect);
    if (track == null) return true;
    if (track.name != null) return false;
    return track.tries < 2;
  }

  void _remember(List<Detection> products, List<Detection> attempted) {
    for (final det in products) {
      if (det.kind != DetectionKind.product) continue;
      final tried = attempted.any((item) => _iou(item.rect, det.rect) > 0.45);
      var track = _trackFor(det.rect);
      if (track == null) {
        track = _TrackedName(det.rect, _nameTick);
        _names.add(track);
      }
      track.rect = det.rect;
      track.seen = _nameTick;
      if (det.label != 'Product') {
        track.name = det.label;
      } else if (tried) {
        track.tries++;
      }
    }
    _names.removeWhere((track) => _nameTick - track.seen > 24);
  }

  _TrackedName? _trackFor(Rect rect) {
    _TrackedName? best;
    var bestIou = 0.35;
    for (final track in _names) {
      final score = _iou(track.rect, rect);
      if (score > bestIou) {
        bestIou = score;
        best = track;
      }
    }
    return best;
  }

  double _iou(Rect a, Rect b) {
    final left = a.left > b.left ? a.left : b.left;
    final top = a.top > b.top ? a.top : b.top;
    final right = a.right < b.right ? a.right : b.right;
    final bottom = a.bottom < b.bottom ? a.bottom : b.bottom;
    final w = right - left;
    final h = bottom - top;
    if (w <= 0 || h <= 0) return 0;
    final inter = w * h;
    final union = a.width * a.height + b.width * b.height - inter;
    if (union <= 0) return 0;
    return inter / union;
  }
}

class _TrackedName {
  _TrackedName(this.rect, this.seen);

  Rect rect;
  String? name;
  int tries = 0;
  int seen;
}
