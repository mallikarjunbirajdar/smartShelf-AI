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

    final ordered = [
      ...detections.where((d) => d.kind == DetectionKind.shelfRow),
      ...detections.where((d) => d.kind != DetectionKind.shelfRow),
    ];

    for (final det in ordered) {
      final rect = Rect.fromLTRB(
        det.rect.left * scale + dx,
        det.rect.top * scale + dy,
        det.rect.right * scale + dx,
        det.rect.bottom * scale + dy,
      );
      if (rect.width <= 1 || rect.height <= 1) continue;

      final isLane = det.kind == DetectionKind.shelfRow;

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = det.color.withValues(alpha: isLane ? 0.28 : 0.14);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLane ? 3.5 : 2.0
        ..color = det.color;

      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);

      if (isLane) {
        final tick = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = det.color;
        canvas.drawLine(
          Offset(rect.left, rect.center.dy),
          Offset(rect.left + 10, rect.center.dy),
          tick,
        );
        canvas.drawLine(
          Offset(rect.right - 10, rect.center.dy),
          Offset(rect.right, rect.center.dy),
          tick,
        );
      }

      if (!showLabels) continue;

      final label =
          '${det.label} · ${(det.confidence * 100).toStringAsFixed(0)}%';
      var maxLabelWidth = rect.width < 128 ? 128.0 : rect.width;
      final viewCap = size.width * 0.72;
      if (maxLabelWidth > viewCap) maxLabelWidth = viewCap;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF07151B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: maxLabelWidth);

      final labelW = tp.width + 10;
      final labelH = tp.height + 6;
      var labelLeft = rect.left;
      var labelTop = rect.top - labelH - 3;

      if (labelTop < 0) labelTop = rect.top + 2;
      if (labelLeft + labelW > size.width) {
        labelLeft = (size.width - labelW).clamp(0.0, size.width);
      }
      if (labelLeft < 0) labelLeft = 0;
      if (labelTop + labelH > size.height) {
        labelTop = (size.height - labelH).clamp(0.0, size.height);
      }

      final bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(labelLeft, labelTop, labelW, labelH),
        const Radius.circular(4),
      );
      canvas.drawRRect(bg, Paint()..color = det.color);
      tp.paint(canvas, Offset(labelLeft + 5, labelTop + 3));
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
