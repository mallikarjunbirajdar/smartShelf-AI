import 'package:get/get.dart';

import '../../bindings/live_binding.dart';
import '../../bindings/main_shell_binding.dart';
import '../../bindings/photo_binding.dart';
import '../../bindings/splash_binding.dart';
import '../../views/live/live_detector_view.dart';
import '../../views/photo/photo_detect_view.dart';
import '../../views/shell/main_shell_view.dart';
import '../../views/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellView(),
      binding: MainShellBinding(),
    ),
    GetPage(
      name: AppRoutes.live,
      page: () => const LiveDetectorView(),
      binding: LiveBinding(),
    ),
    GetPage(
      name: AppRoutes.photo,
      page: () => const PhotoDetectView(),
      binding: PhotoBinding(),
    ),
  ];
}
