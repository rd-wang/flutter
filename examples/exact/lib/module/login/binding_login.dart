import 'package:exact/module/login/repo_login.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import 'controller_login.dart';

class LoginBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<LoginController>(() => LoginController()),
      Bind.lazyPut<LoginRepo>(() => LoginRepo()),
    ];
  }
}
