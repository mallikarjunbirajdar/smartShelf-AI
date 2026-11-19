import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  static const logoAsset = 'assets/images/shelf_ai_logo.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF07151B),
              Color(0xFF0B1C24),
              Color(0xFF12303A),
              Color(0xFF1B4A3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.28),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(logoAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'SmartShelf AI',
                style: GoogleFonts.dmSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE8F6F1),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Intelligent Shelf & Product Detection',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: const Color(0xFFB7D0C8),
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Obx(
                  () => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: controller.progress.value,
                          minHeight: 6,
                          backgroundColor: const Color(0x3322C58B),
                          color: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        controller.statusText.value,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: const Color(0xFF9CBBB0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
