import 'package:exact/base/base/base_controller.dart';

import 'repo_login.dart';

class LoginController extends RrController<LoginRepo> {
  @override
  onInit() {
    super.onInit();
    repo.loadNothing();
  }
}
