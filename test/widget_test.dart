import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shelf_ai_detector_new/app/routes/app_routes.dart';

void main() {
  test('App routes include splash', () {
    expect(AppRoutes.splash, '/');
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.live, '/live');
    expect(AppRoutes.photo, '/photo');
  });

  tearDown(Get.reset);
}
