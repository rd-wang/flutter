import 'package:exact/module/setting/repo_setting.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import 'controller_setting.dart';

class SettingBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<SettingController>(() => SettingController()),
      Bind.lazyPut<SettingRepo>(() => SettingRepo()),
    ];
  }
}
