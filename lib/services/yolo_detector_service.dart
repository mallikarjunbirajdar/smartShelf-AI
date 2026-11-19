import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../models/detection_model.dart';
import 'image_preprocessor_service.dart';

class YoloDetectorService extends GetxService {
  OrtSession? _productSession;
  OrtSession? _shelfSession;
  bool _initialized = false;

  static const _productAsset =
      'assets/models/detect_product_empty_space.onnx';
  static const _shelfAsset = 'assets/models/segment_shelf_rows.onnx';

  static const productLabels = {0: 'empty', 1: 'product'};
  static const shelfLabels = {0: 'shelf'};

  bool get isReady => _initialized;

  Future<YoloDetectorService> init() async {
    if (_initialized) return this;
    OrtEnv.instance.init();

    final productBytes =
        (await rootBundle.load(_productAsset)).buffer.asUint8List();
    final shelfBytes =
        (await rootBundle.load(_shelfAsset)).buffer.asUint8List();

    final productOptions = OrtSessionOptions()..setIntraOpNumThreads(2);
    final shelfOptions = OrtSessionOptions()..setIntraOpNumThreads(2);

    _productSession = OrtSession.fromBuffer(productBytes, productOptions);
    _shelfSession = OrtSession.fromBuffer(shelfBytes, shelfOptions);
    _initialized = true;
    return this;
  }

  Future<FrameDetections> detect(
    LetterboxResult input, {
    double productConf = 0.35,
    double shelfConf = 0.25,
    bool runShelf = true,
    double iouThreshold = 0.45,
  }) async {
    if (!_initialized) {
      throw StateError('YoloDetectorService not initialized');
    }

    final sw = Stopwatch()..start();
    final tensor = OrtValueTensor.createTensorWithDataList(
      input.tensor,
      [1, 3, ImagePreprocessorService.inputSize, ImagePreprocessorService.inputSize],
    );
    final runOptions = OrtRunOptions();

    final productOutputs = await _productSession!.runAsync(
          runOptions,
          {'images': tensor},
        ) ??
        <OrtValue?>[];

    List<Detection> shelves = const [];
    if (runShelf) {
      final shelfOutputs = await _shelfSession!.runAsync(
            runOptions,
            {'images': tensor},
          ) ??
          <OrtValue?>[];
      shelves = _parseShelf(
        shelfOutputs,
        input,
        confThreshold: shelfConf,
        iouThreshold: iouThreshold,
      );
      _releaseOutputs(shelfOutputs);
    }

    final products = _parseProducts(
      productOutputs,
      input,
      confThreshold: productConf,
      iouThreshold: iouThreshold,
    );

    tensor.release();
    runOptions.release();
    _releaseOutputs(productOutputs);
    sw.stop();

    return FrameDetections(
      shelves: shelves,
      products: products,
      imageWidth: input.sourceWidth,
      imageHeight: input.sourceHeight,
      inferenceMs: sw.elapsedMilliseconds,
    );
  }

  List<Detection> _parseProducts(
    List<OrtValue?>? outputs,
    LetterboxResult input, {
    required double confThreshold,
    required double iouThreshold,
  }) {
    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      return [];
    }

    final data = (outputs.first!.value as List).cast<List>();
    final channels = data.first.cast<List>();
    final numPred = channels[0].length;
    final candidates = <_RawDet>[];

    for (var i = 0; i < numPred; i++) {
      final emptyScore = (channels[4][i] as num).toDouble();
      final productScore = (channels[5][i] as num).toDouble();
      final classId = emptyScore >= productScore ? 0 : 1;
      final conf = classId == 0 ? emptyScore : productScore;
      if (conf < confThreshold) continue;

      candidates.add(
        _RawDet(
          classId,
          conf,
          (channels[0][i] as num).toDouble(),
          (channels[1][i] as num).toDouble(),
          (channels[2][i] as num).toDouble(),
          (channels[3][i] as num).toDouble(),
        ),
      );
    }

    return _nms(candidates, iouThreshold).map((d) {
      return Detection(
        kind: d.classId == 1 ? DetectionKind.product : DetectionKind.empty,
        label: productLabels[d.classId]!,
        confidence: d.conf,
        rect: _toSourceRect(d, input),
      );
    }).toList();
  }

  List<Detection> _parseShelf(
    List<OrtValue?>? outputs,
    LetterboxResult input, {
    required double confThreshold,
    required double iouThreshold,
  }) {
    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      return [];
    }

    final data = (outputs.first!.value as List).cast<List>();
    final channels = data.first.cast<List>();
    final numPred = channels[0].length;
    final candidates = <_RawDet>[];

    for (var i = 0; i < numPred; i++) {
      final conf = (channels[4][i] as num).toDouble();
      if (conf < confThreshold) continue;
      candidates.add(
        _RawDet(
          0,
          conf,
          (channels[0][i] as num).toDouble(),
          (channels[1][i] as num).toDouble(),
          (channels[2][i] as num).toDouble(),
          (channels[3][i] as num).toDouble(),
        ),
      );
    }

    return _nms(candidates, iouThreshold)
        .map(
          (d) => Detection(
            kind: DetectionKind.shelfRow,
            label: shelfLabels[0]!,
            confidence: d.conf,
            rect: _toSourceRect(d, input),
          ),
        )
        .toList();
  }

  Rect _toSourceRect(_RawDet d, LetterboxResult input) {
    final left = (d.cx - d.w / 2 - input.padX) / input.ratio;
    final top = (d.cy - d.h / 2 - input.padY) / input.ratio;
    final right = (d.cx + d.w / 2 - input.padX) / input.ratio;
    final bottom = (d.cy + d.h / 2 - input.padY) / input.ratio;
    return Rect.fromLTRB(
      left.clamp(0, input.sourceWidth.toDouble()),
      top.clamp(0, input.sourceHeight.toDouble()),
      right.clamp(0, input.sourceWidth.toDouble()),
      bottom.clamp(0, input.sourceHeight.toDouble()),
    );
  }

  List<_RawDet> _nms(List<_RawDet> dets, double iouThreshold) {
    dets.sort((a, b) => b.conf.compareTo(a.conf));
    final selected = <_RawDet>[];
    final suppressed = List<bool>.filled(dets.length, false);

    for (var i = 0; i < dets.length; i++) {
      if (suppressed[i]) continue;
      selected.add(dets[i]);
      for (var j = i + 1; j < dets.length; j++) {
        if (suppressed[j]) continue;
        if (dets[i].classId != dets[j].classId) continue;
        if (_iou(dets[i], dets[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return selected;
  }

  double _iou(_RawDet a, _RawDet b) {
    final ax1 = a.cx - a.w / 2;
    final ay1 = a.cy - a.h / 2;
    final ax2 = a.cx + a.w / 2;
    final ay2 = a.cy + a.h / 2;
    final bx1 = b.cx - b.w / 2;
    final by1 = b.cy - b.h / 2;
    final bx2 = b.cx + b.w / 2;
    final by2 = b.cy + b.h / 2;

    final ix1 = math.max(ax1, bx1);
    final iy1 = math.max(ay1, by1);
    final ix2 = math.min(ax2, bx2);
    final iy2 = math.min(ay2, by2);
    final inter = math.max(0, ix2 - ix1) * math.max(0, iy2 - iy1);
    final union = a.w * a.h + b.w * b.h - inter;
    return union <= 0 ? 0 : inter / union;
  }

  void _releaseOutputs(List<OrtValue?>? outputs) {
    if (outputs == null) return;
    for (final o in outputs) {
      o?.release();
    }
  }

  @override
  void onClose() {
    _productSession?.release();
    _shelfSession?.release();
    _productSession = null;
    _shelfSession = null;
    _initialized = false;
    OrtEnv.instance.release();
    super.onClose();
  }
}

class _RawDet {
  _RawDet(this.classId, this.conf, this.cx, this.cy, this.w, this.h);
  final int classId;
  final double conf;
  final double cx;
  final double cy;
  final double w;
  final double h;
}
