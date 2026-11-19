import 'dart:ui';

enum DetectionKind { shelfRow, product, empty }

class Detection {
  Detection({
    required this.kind,
    required this.label,
    required this.confidence,
    required this.rect,
  });

  final DetectionKind kind;
  final String label;
  final double confidence;
  final Rect rect;

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
  String get fullLabel => '$label · $confidencePercent';

  Detection copyWith({String? label}) {
    return Detection(
      kind: kind,
      label: label ?? this.label,
      confidence: confidence,
      rect: rect,
    );
  }

  Color get color {
    switch (kind) {
      case DetectionKind.shelfRow:
        return const Color(0xFF00E5FF);
      case DetectionKind.product:
        return const Color(0xFF69F0AE);
      case DetectionKind.empty:
        return const Color(0xFFFFAB40);
    }
  }
}

class FrameDetections {
  const FrameDetections({
    required this.shelves,
    required this.products,
    required this.imageWidth,
    required this.imageHeight,
    this.inferenceMs = 0,
  });

  final List<Detection> shelves;
  final List<Detection> products;
  final int imageWidth;
  final int imageHeight;
  final int inferenceMs;

  List<Detection> get all => [...shelves, ...products];

  int get productCount =>
      products.where((d) => d.kind == DetectionKind.product).length;

  int get emptyCount =>
      products.where((d) => d.kind == DetectionKind.empty).length;

  int get avgConfidencePercent {
    final list = all;
    if (list.isEmpty) return 0;
    final total = list.fold(0.0, (sum, d) => sum + d.confidence);
    return ((total / list.length) * 100).round();
  }

  double get avgConfidence {
    final list = all;
    if (list.isEmpty) return 0.0;
    final total = list.fold(0.0, (sum, d) => sum + d.confidence);
    return total / list.length;
  }

  /// Brand or package names read from product boxes. Generic "Product" is omitted.
  String get namedProductsLabel {
    final names = <String>[];
    for (final d in products) {
      if (d.kind != DetectionKind.product) continue;
      if (d.label == 'Product' || d.label.trim().isEmpty) continue;
      if (names.contains(d.label)) continue;
      names.add(d.label);
      if (names.length == 4) break;
    }
    return names.join(', ');
  }
}
