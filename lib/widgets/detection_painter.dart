import 'package:flutter/material.dart';

import '../models/detection_model.dart';

class DetectionPainter extends CustomPainter {
  DetectionPainter({
    required this.detections,
    required this.imageSize,
    this.showLabels = true,
  });

  final List<Detection> detections;
  final Size imageSize;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;

    final scale = _fitScale(imageSize, size);
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;

    for (final det in detections) {
      final rect = Rect.fromLTRB(
        det.rect.left * scale + dx,
        det.rect.top * scale + dy,
        det.rect.right * scale + dx,
        det.rect.bottom * scale + dy,
      );

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = det.kind == DetectionKind.shelfRow ? 3.0 : 2.0
        ..color = det.color;

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = det.color.withValues(alpha: 0.12);

      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);

      if (!showLabels) continue;

      final label =
          '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            backgroundColor: det.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      final labelTop = (rect.top - tp.height - 2).clamp(0.0, size.height);
      canvas.drawRect(
        Rect.fromLTWH(rect.left, labelTop, tp.width + 6, tp.height + 2),
        Paint()..color = det.color,
      );
      tp.paint(canvas, Offset(rect.left + 3, labelTop + 1));
    }
  }

  double _fitScale(Size image, Size view) {
    return (view.width / image.width < view.height / image.height)
        ? view.width / image.width
        : view.height / image.height;
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.showLabels != showLabels;
  }
}
