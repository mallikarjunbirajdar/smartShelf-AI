import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/main_shell_controller.dart';
import '../history/history_view.dart';
import '../home/home_view.dart';

class MainShellView extends GetView<MainShellController> {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.selectedIndex.value;
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: IndexedStack(
          index: index,
          children: const [
            HomeView(),
            HistoryView(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: index == 0,
                    onTap: () => controller.changeTab(0),
                  ),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    selected: index == 1,
                    onTap: () => controller.changeTab(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
