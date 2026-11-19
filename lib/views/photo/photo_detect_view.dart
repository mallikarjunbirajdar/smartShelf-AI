import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/photo_detect_controller.dart';
import '../../models/capture_mode.dart';
import '../../models/detection_model.dart';
import '../../widgets/detection_painter.dart';

class PhotoDetectView extends GetView<PhotoDetectController> {
  const PhotoDetectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Capture & Process',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.image_outlined),
            onSelected: controller.processAsset,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'assets/test_images/1.jpeg',
                child: Text('Test image 1'),
              ),
              PopupMenuItem(
                value: 'assets/test_images/2.jpg',
                child: Text('Test image 2'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.error.value != null &&
              controller.cameraController == null) {
            return Center(
              child: Text(
                controller.error.value!,
                style: const TextStyle(color: Colors.orange),
              ),
            );
          }
          return switch (controller.mode.value) {
            CaptureMode.camera => _CameraPane(controller: controller),
            CaptureMode.review => _ReviewPane(controller: controller),
            CaptureMode.result => _ResultPane(controller: controller),
          };
        }),
      ),
    );
  }
}

class _CameraPane extends StatelessWidget {
  const _CameraPane({required this.controller});
  final PhotoDetectController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller.cameraController;
      if (!controller.cameraReady.value ||
          c == null ||
          !c.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF69F0AE)),
        );
      }
      return Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CameraPreview(c),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Ctrl(
                icon: Icons.photo_camera,
                label: 'Capture',
                onTap: controller.capture,
              ),
              Obx(
                () => _Ctrl(
                  icon: controller.recording.value
                      ? Icons.stop_circle
                      : Icons.fiber_manual_record,
                  label: controller.recording.value
                      ? 'Stop Video'
                      : 'Record Video',
                  color: Colors.redAccent,
                  onTap: controller.toggleVideo,
                ),
              ),
            ],
          ),
          SizedBox(
            height: (MediaQuery.paddingOf(context).bottom > 0)
                ? MediaQuery.paddingOf(context).bottom + 16.0
                : 28.0,
          ),
        ],
      );
    });
  }
}

class _ReviewPane extends StatelessWidget {
  const _ReviewPane({required this.controller});
  final PhotoDetectController controller;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = bottomInset > 0 ? bottomInset + 16.0 : 32.0;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Obx(() {
              final bytes = controller.previewBytes.value;
              final video = controller.videoPath.value;
              if (bytes != null) {
                return Image.memory(bytes, fit: BoxFit.contain);
              }
              if (video != null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white54, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Video ready\n$video',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ),
        Obx(() {
          if (controller.processing.value) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF69F0AE)),
                  SizedBox(height: 10),
                  Text(
                    'Reading product names…',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.retake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Retake',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.process,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4A3C),
                      foregroundColor: const Color(0xFF69F0AE),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Process',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ResultPane extends StatelessWidget {
  const _ResultPane({required this.controller});
  final PhotoDetectController controller;

  static void _showDetectedLabelsSheet(
    BuildContext context,
    FrameDetections dets,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Detected Items & Scores',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Avg ${dets.avgConfidencePercent}%',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dets.all.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (_, i) {
                      final d = dets.all[i];
                      final isProd = d.kind == DetectionKind.product;
                      final isEmpty = d.kind == DetectionKind.empty;
                      final badgeColor = isProd
                          ? const Color(0xFF10B981)
                          : (isEmpty
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF06B6D4));
                      final badgeBg = isProd
                          ? const Color(0xFFECFDF5)
                          : (isEmpty
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFEFF6FF));
                      final pct = (d.confidence * 100).round();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                d.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: d.confidence.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    badgeColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$pct%',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = bottomInset > 0 ? bottomInset + 16.0 : 32.0;

    return Column(
      children: [
        Obx(() {
          final dets = controller.detections.value;
          if (dets == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip('Lanes', dets.shelves.length),
                  const SizedBox(width: 8),
                  _Chip('Products', dets.productCount),
                  const SizedBox(width: 8),
                  _Chip('Empty', dets.emptyCount),
                  const SizedBox(width: 8),
                  _Chip('Avg Conf', '${dets.avgConfidencePercent}%'),
                  const SizedBox(width: 8),
                  _Chip('${dets.inferenceMs} ms', null),
                ],
              ),
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            final bytes = controller.previewBytes.value;
            final dets = controller.detections.value;
            if (bytes == null) return const SizedBox.shrink();

            final imageSize = dets == null
                ? null
                : Size(dets.imageWidth.toDouble(), dets.imageHeight.toDouble());

            if (dets == null ||
                imageSize == null ||
                imageSize.width <= 0 ||
                imageSize.height <= 0) {
              return Image.memory(bytes, fit: BoxFit.contain);
            }

            final frame = dets;
            final sized = imageSize;

            return LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    (constraints.maxWidth / sized.width <
                        constraints.maxHeight / sized.height)
                    ? constraints.maxWidth / sized.width
                    : constraints.maxHeight / sized.height;
                final viewW = sized.width * scale;
                final viewH = sized.height * scale;

                return Center(
                  child: SizedBox(
                    width: viewW,
                    height: viewH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes, fit: BoxFit.fill),
                        CustomPaint(
                          painter: DetectionPainter(
                            detections: frame.all,
                            imageSize: sized,
                            showLabels: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Obx(() {
          final dets = controller.detections.value;
          if (dets == null || dets.all.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDetectedLabelsSheet(context, dets),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132B34),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1B4A3C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.label_outline_rounded,
                        color: Color(0xFF69F0AE),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${dets.all.length} labels detected · Avg ${dets.avgConfidencePercent}% conf',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4A3C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View all',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF69F0AE),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Color(0xFF69F0AE),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.retake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Retake',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: controller.goToCamera,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4A3C),
                    foregroundColor: const Color(0xFF69F0AE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'New Capture',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Ctrl extends StatelessWidget {
  const _Ctrl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1B4A3C),
            foregroundColor: color ?? const Color(0xFF69F0AE),
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(icon, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2218E0A0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value == null ? label : '$label: $value',
        style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 12),
      ),
    );
  }
}
