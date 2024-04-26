import 'package:exact/base/base/base_repository.dart';
import 'package:exact/base/config/theme/theme.dart';
import 'package:exact/base/config/translations/localization_service.dart';
import 'package:exact/base/const_configs.dart';
import 'package:exact/widget/bottom_change_language_widget.dart';
import 'package:exact/widget/bottom_sheet_widget.dart';
import 'package:exact/widget/bottom_work_time_detail_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../base/base_service.dart';

class GlobalService extends RrService {
  static GlobalService get to => Get.find();

  AppEnv get currentEnv => GlobalConfig.env;

  void changeTheme() {
    RrTheme.changeTheme();
  }

  changeLanguage() {
    // Get.bottomSheet(
    //   ChangeLanguagePage(),
    //   backgroundColor: Colors.transparent,
    //   isScrollControlled: true,
    // ).then((value) => RrLocalizationService.updateLanguage(value));
    showBottomSheetDialog(context: Get.context!, body: ChangeLanguagePage())
        .then((value) => RrLocalizationService.updateLanguage(value));
  }
}
