import 'package:exact/base/base/base_controller.dart';
import 'package:get/get.dart';

import 'repo_login.dart';

class LoginController extends RrController<LoginRepo> {
  @override
  onInit() {
    super.onInit();
    Get.log('Login created with then: ${Get.parameters['then'] ?? ''}');
    repo.loadNothing();
  }
}
