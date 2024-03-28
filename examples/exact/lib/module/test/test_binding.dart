import 'package:get/get.dart';

import 'test_logic.dart';

class TestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TestLogic());
  }
}
