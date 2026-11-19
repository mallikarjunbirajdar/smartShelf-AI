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
}
