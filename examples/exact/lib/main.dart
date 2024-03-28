import 'package:exact/base/config/theme/theme.dart';
import 'package:exact/base/config/translations/localization_service.dart';
import 'package:exact/base/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  await NotificationsController.initializeIsolateReceivePort();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
