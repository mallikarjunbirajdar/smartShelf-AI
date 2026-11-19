import 'package:get/get.dart';

class MainShellController extends GetxController {
  final selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}
