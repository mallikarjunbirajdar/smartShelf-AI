import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/photo_detect_controller.dart';
import '../../models/capture_mode.dart';
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
      body: Obx(() {
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
          const SizedBox(height: 24),
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
            return const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF69F0AE)),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.retake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: controller.process,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4A3C),
                      foregroundColor: const Color(0xFF69F0AE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Process'),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final dets = controller.detections.value;
          if (dets == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Chip('Shelves', dets.shelves.length),
                _Chip('Products', dets.productCount),
                _Chip('Empty', dets.emptyCount),
                _Chip('${dets.inferenceMs} ms', null),
              ],
            ),
          );
        }),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Obx(() {
                final bytes = controller.previewBytes.value;
                if (bytes == null) return const SizedBox.shrink();
                return Image.memory(bytes, fit: BoxFit.contain);
              }),
              Obx(() {
                final dets = controller.detections.value;
                if (dets == null) return const SizedBox.shrink();
                return CustomPaint(
                  painter: DetectionPainter(
                    detections: dets.all,
                    imageSize: Size(
                      dets.imageWidth.toDouble(),
                      dets.imageHeight.toDouble(),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.retake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: controller.goToCamera,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4A3C),
                    foregroundColor: const Color(0xFF69F0AE),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('New Capture'),
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
  final int? value;

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
