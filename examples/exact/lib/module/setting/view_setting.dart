import 'package:exact/base/base/base_view.dart';
import 'package:exact/base/service/global_service.dart';
import 'package:exact/module/setting/controller_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../base/config/theme/theme.dart';
import '../../base/config/theme/theme_extensions/header_container_theme_data.dart';
import '../../base/config/translations/localization_service.dart';
import '../../base/config/translations/strings_enum.dart';

class SettingView extends RrView<SettingController> {
  const SettingView({super.key});

  // SettingView({super.key}) : super(SettingController());
  @override
  String setTitle() {
    return Strings.settings.tr;
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(children: [
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
        child: InkWell(
          onTap: () => Get.find<GlobalService>().changeTheme(),
          child: Ink(
            child: Container(
              height: 39.h,
              width: 39.h,
              decoration: Theme.of(context).extension<HeaderContainerThemeData>()?.decoration,
              child: SvgPicture.asset(
                Get.isDarkMode ? 'assets/vectors/moon.svg' : 'assets/vectors/sun.svg',
                fit: BoxFit.none,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 10,
                width: 10,
              ),
            ),
          ),
        ),
      ),

      10.horizontalSpace,

      //----------------Language Button----------------//
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
        child: InkWell(
          onTap: () => Get.find<GlobalService>().changeLanguage(),
          child: Ink(
            child: Container(
              height: 39.h,
              width: 39.h,
              decoration: Theme.of(context).extension<HeaderContainerThemeData>()?.decoration,
              child: SvgPicture.asset(
                'assets/vectors/language.svg',
                fit: BoxFit.none,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                height: 10,
                width: 10,
              ),
            ),
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
        child: GestureDetector(
          onTap: () => RrTheme.changeTheme(),
          child: Text(Strings.changeTheme.tr),
        ),
      ),
    ]);
  }
}
