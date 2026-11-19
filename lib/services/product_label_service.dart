import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../models/detection_model.dart';

/// Reads the printed name on each detected product box.
class ProductLabelService extends GetxService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  int _fileSeq = 0;

  Future<FrameDetections> annotate(
    img.Image image,
    FrameDetections frame, {
    int limit = 8,
    bool Function(Detection det)? shouldRead,
  }) async {
    final products = await applyNames(
      image,
      frame.products,
      limit: limit,
      shouldRead: shouldRead,
    );
    return FrameDetections(
      shelves: frame.shelves,
      products: products,
      imageWidth: frame.imageWidth,
      imageHeight: frame.imageHeight,
      inferenceMs: frame.inferenceMs,
    );
  }

  Future<List<Detection>> applyNames(
    img.Image image,
    List<Detection> products, {
    int limit = 8,
    bool Function(Detection det)? shouldRead,
  }) async {
    final indexes = <int>[];
    for (var i = 0; i < products.length; i++) {
      final det = products[i];
      if (det.kind != DetectionKind.product) continue;
      if (shouldRead != null && !shouldRead(det)) continue;
      indexes.add(i);
    }
    indexes.sort((a, b) {
      final areaA = products[a].rect.width * products[a].rect.height;
      final areaB = products[b].rect.width * products[b].rect.height;
      return areaB.compareTo(areaA);
    });

    final updated = List<Detection>.from(products);
    for (final index in indexes.take(limit)) {
      try {
        final name = await _readName(image, products[index].rect);
        if (name == null) continue;
        updated[index] = products[index].copyWith(label: name);
      } catch (_) {
        // Keep the generic "Product" label when text cannot be read.
      }
    }
    return updated;
  }

  Future<String?> _readName(img.Image source, Rect rect) async {
    final crop = _crop(source, rect);
    if (crop == null) return null;

    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}shelf_label_${_fileSeq++}.jpg',
    );
    try {
      await file.writeAsBytes(img.encodeJpg(crop, quality: 85), flush: true);
      final recognized = await _recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return _bestName(recognized);
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  img.Image? _crop(img.Image source, Rect rect) {
    final padX = rect.width * 0.06;
    final padY = rect.height * 0.08;
    final left = (rect.left - padX).round().clamp(0, source.width - 1);
    final top = (rect.top - padY).round().clamp(0, source.height - 1);
    final right = (rect.right + padX).round().clamp(left + 1, source.width);
    final bottom = (rect.bottom + padY).round().clamp(top + 1, source.height);
    final width = right - left;
    final height = bottom - top;
    if (width < 24 || height < 16) return null;

    var crop = img.copyCrop(
      source,
      x: left,
      y: top,
      width: width,
      height: height,
    );
    if (crop.width > 420) {
      crop = img.copyResize(crop, width: 420);
    }
    return crop;
  }

  String? _bestName(RecognizedText recognized) {
    final scored = <({String text, double score})>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final cleaned = _cleanLine(line.text);
        if (cleaned == null) continue;
        final confidence = line.confidence ?? 0.75;
        if (confidence < 0.35) continue;
        scored.add((text: cleaned, score: line.boundingBox.height * confidence));
      }
    }
    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.score.compareTo(a.score));
    final name = scored.first.text;
    if (name.length > 36) return '${name.substring(0, 34)}…';
    return name;
  }

  String? _cleanLine(String raw) {
    var text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9%&+]+$'), '');
    if (text.length < 2 || text.length > 48) return null;
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) return null;
    if (_noise.hasMatch(text)) return null;
    if (RegExp(r'^\d').hasMatch(text) &&
        RegExp(r'(ml|l|g|kg|gm|oz|pcs|pk)\b', caseSensitive: false)
            .hasMatch(text)) {
      return null;
    }
    return text;
  }

  static final _noise = RegExp(
    r'^(mrp|mfg|exp|pkd|net|wt|qty|batch|mfd|rs|inr|off|sale|new|best before|ingredients|nutrition|imported|packed)$',
    caseSensitive: false,
  );

  @override
  void onClose() {
    _recognizer.close();
    super.onClose();
  }
}
