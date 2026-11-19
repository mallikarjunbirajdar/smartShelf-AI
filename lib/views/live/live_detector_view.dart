import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/live_detector_controller.dart';
import '../../widgets/detection_painter.dart';

class LiveDetectorView extends GetView<LiveDetectorController> {
  const LiveDetectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            if (controller.cameraReady.value &&
                controller.cameraController != null) {
              final dets = controller.detections.value;
              return Center(
                child: CameraPreview(
                  controller.cameraController!,
                  child: dets == null
                      ? null
                      : CustomPaint(
                          painter: DetectionPainter(
                            detections: dets.all,
                            imageSize: Size(
                              dets.imageWidth.toDouble(),
                              dets.imageHeight.toDouble(),
                            ),
                            showLabels: true,
                          ),
                        ),
                ),
              );
            }
            if (controller.error.value != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    controller.error.value!,
                    style: const TextStyle(color: Colors.orangeAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF69F0AE)),
            );
          }),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'Live Detection',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Obx(
                        () => Switch(
                          value: controller.detecting.value,
                          activeThumbColor: const Color(0xFF69F0AE),
                          onChanged: controller.setDetecting,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final dets = controller.detections.value;
                  if (dets == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _Stat('Lanes', '${dets.shelves.length}'),
                        _Stat('Products', '${dets.productCount}'),
                        _Stat('Empty', '${dets.emptyCount}'),
                        _Stat('Avg Conf', '${dets.avgConfidencePercent}%'),
                        _Stat('ms', '${dets.inferenceMs}'),
                      ],
                    ),
                  );
                }),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Obx(
                    () => Row(
                      children: [
                        const Text(
                          'Conf',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: controller.confidence.value,
                            min: 0.15,
                            max: 0.7,
                            activeColor: const Color(0xFF69F0AE),
                            onChanged: controller.setConfidence,
                          ),
                        ),
                        Text(
                          controller.confidence.value.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final bottomInset = MediaQuery.paddingOf(context).bottom;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: bottomInset > 0 ? bottomInset + 16 : 28,
                      ),
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RoundBtn(
                              icon: Icons.photo_camera,
                              label: 'Capture',
                              onTap: controller.captureStill,
                            ),
                            _RoundBtn(
                              icon: controller.recording.value
                                  ? Icons.stop
                                  : Icons.videocam,
                              label: controller.recording.value
                                  ? 'Stop'
                                  : 'Record',
                              color: controller.recording.value
                                  ? Colors.redAccent
                                  : null,
                              onTap: controller.toggleRecording,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF69F0AE),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? const Color(0xFF1B4A3C),
              border: Border.all(color: const Color(0xFF69F0AE), width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
