import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/main_shell_controller.dart';
import '../../models/recent_scan_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _bg = Color(0xFFF3F4F6);
  static const _cardBlue = Color(0xFFDCECFF);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _accent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }
          if (controller.error.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load models:\n${controller.error.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _Header(),
              const SizedBox(height: 20),
              _ScanHeroCard(onStart: controller.startLiveDetection),
              const SizedBox(height: 28),
              Text(
                'Quick actions',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.photo_camera_outlined,
                      label: 'Capture photo',
                      onTap: controller.openCapturePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.videocam_outlined,
                      label: 'Record video',
                      onTap: controller.openRecordVideo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'Recent scans',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (Get.isRegistered<MainShellController>()) {
                        Get.find<MainShellController>().changeTab(1);
                      }
                    },
                    child: Text(
                      'View all',
                      style: GoogleFonts.dmSans(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (controller.recentScans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    'No scans yet.\nCapture a photo or start live detection to see results here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.4,
                      color: _muted,
                    ),
                  ),
                )
              else
                ...controller.recentScans.map(_RecentScanTile.new),
            ],
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  static const logoAsset = 'assets/images/shelf_ai_logo.jpg';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            logoAsset,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartShelf AI',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HomeView._ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AI-Powered Shelf Intelligence',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: HomeView._muted,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Icon(Icons.person_outline, color: HomeView._ink, size: 22),
        ),
      ],
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomeView._cardBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.view_week_rounded,
                  color: HomeView._ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan a shelf',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: HomeView._ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Point the camera at a shelf',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: HomeView._muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.videocam_rounded, size: 20),
              label: Text(
                'Start live detection',
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
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: HomeView._ink),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HomeView._ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile(this.scan);
  final RecentScan scan;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        scan.imagePath != null && scan.imagePath!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              color: const Color(0xFFF3F4F6),
              child: hasImage
                  ? Image.file(
                      File(scan.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: HomeView._muted,
                      ),
                    )
                  : Icon(
                      scan.source == 'video'
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                      color: HomeView._muted,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HomeView._ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scan.summary,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: HomeView._muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            scan.whenLabel,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: HomeView._muted,
            ),
          ),
        ],
      ),
    );
  }
}
