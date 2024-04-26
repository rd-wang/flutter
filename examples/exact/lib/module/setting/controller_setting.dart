import 'package:exact/base/base/base_controller.dart';
import 'package:exact/base/config/theme/theme.dart';
import 'package:exact/base/config/translations/localization_service.dart';

import 'repo_setting.dart';

class SettingController extends RrController<SettingRepo> {
  // SettingController() : super(SettingRepo());
  @override
  onInit() {
    super.onInit();
    repo.loadNothing();
  }
}
