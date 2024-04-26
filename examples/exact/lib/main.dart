import 'package:dio/dio.dart';
import 'package:exact/base/config/theme/theme.dart';
import 'package:exact/base/config/translations/localization_service.dart';
import 'package:exact/base/network/net_work_client.dart';
import 'package:exact/base/service/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ume/flutter_ume.dart'; // UME 框架
import 'package:flutter_ume_kit_console/flutter_ume_kit_console.dart'; // debugPrint 插件包
import 'package:flutter_ume_kit_device/flutter_ume_kit_device.dart'; // 设备信息插件包
import 'package:flutter_ume_kit_dio/flutter_ume_kit_dio.dart'; // Dio 网络请求调试工具
import 'package:flutter_ume_kit_perf/flutter_ume_kit_perf.dart'; // 性能插件包
import 'package:flutter_ume_kit_show_code/flutter_ume_kit_show_code.dart'; // 代码查看插件包
import 'package:flutter_ume_kit_ui/flutter_ume_kit_ui.dart'; // UI 插件包
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import 'base/local/shared_pref.dart';
import 'base/notifications/notifications_controller.dart';
import 'base/service/global_service.dart';
import 'routes/routes.dart';

Future<void> main() async {
  // wait for bindings
  WidgetsFlutterBinding.ensureInitialized();

  // initialize local db (hive) and register our custom adapters
  // await MyHive.init(registerAdapters: (hive) {
  //   hive.registerAdapter(UserModelAdapter());
  //   //myHive.registerAdapter(OtherAdapter());
  // });
  await RrSharedPref.init();
  // inti fcm services
  // await FcmHelper.initFcm();

  // initialize local notifications service
  // Always initialize Awesome Notifications
  await NotificationsController.initializeLocalNotifications();
  if (kDebugMode) {
    PluginManager.instance
      ..register(const WidgetInfoInspector())
      ..register(const WidgetDetailInspector())
      ..register(const ColorSucker())
      ..register(AlignRuler())
      ..register(const ColorPicker())
      ..register(const TouchIndicator())
      ..register(Performance())
      ..register(const ShowCode())
      ..register(const MemoryInfoPage())
      ..register(CpuInfoPage())
      ..register(const DeviceInfoPanel())
      ..register(Console())
      ..register(DioInspector(dio: RrNetClient().dioService ?? Dio()));
    runApp(const UMEWidget(enable: true, child: MyApp())); // 初始化
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // todo add your (Xd / Figma) artboard size
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      rebuildFactor: (old, data) => true,
      builder: (context, widget) {
        return OKToast(
          child: GetMaterialApp(
            // todo add your app name
            title: "exact",
            useInheritedMediaQuery: true,
            debugShowCheckedModeBanner: false,
            builder: (context, widget) {
              bool themeIsLight = RrSharedPref.getThemeIsLight();
              return Theme(
                data: RrTheme.getThemeData(isLight: themeIsLight),
                child: MediaQuery(
                  // prevent font from scalling (some people use big/small device fonts)
                  // but we want our app font to still the same and dont get affected
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: widget!,
                ),
              );
            },
            initialRoute: RrRoutes.initial,
            // first screen to show when app is running
            getPages: RrRoutes.getPages(),
            // app screens
            locale: RrSharedPref.getCurrentLocal(),
            // app language
            translations: RrLocalizationService.getInstance(),
            // localization services in app (controller app language)
            binds: [
              Bind.put(AuthService()),
              Bind.put(GlobalService()),
            ],
          ),
        );
      },
    );
  }
}
