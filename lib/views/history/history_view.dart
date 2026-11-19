import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'History',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: Obx(() {
        if (home.recentScans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No detection history yet.\nScan a shelf with photo or live camera.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  height: 1.4,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: home.recentScans.length,
          itemBuilder: (context, index) {
            final scan = home.recentScans[index];
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
                                Icons.history,
                                color: Color(0xFF6B7280),
                              ),
                            )
                          : Icon(
                              scan.source == 'video'
                                  ? Icons.videocam_outlined
                                  : Icons.history,
                              color: const Color(0xFF6B7280),
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
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scan.summary,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    scan.whenLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
