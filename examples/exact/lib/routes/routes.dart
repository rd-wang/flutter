import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/module/call/binding_call.dart';
import 'package:exact/module/call/view_call.dart';
import 'package:exact/module/home/binding/binding_home.dart';
import 'package:exact/module/login/binding_login.dart';
import 'package:exact/module/login/view_login.dart';
import 'package:exact/module/media/binding_media.dart';
import 'package:exact/module/media/view_media.dart';
import 'package:exact/module/notification/view_notification.dart';
import 'package:exact/module/notification_detail/binding_notification_detail.dart';
import 'package:exact/module/notification_detail/view_notification_detail.dart';
import 'package:exact/module/setting/binding_setting.dart';
import 'package:exact/module/setting/view_setting.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tuple/tuple.dart';

import '../base/middleware/auth_middleware.dart';
import '../module/home/page/page_home.dart';
import '../module/notification/binding_notification.dart';

typedef RrPageBuilder = Widget Function(String pageName);

class RrRoutes {
  // static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  //   "/": (BuildContext context) => HomePage(),
  //   "/shop": (BuildContext context) => ShopPage(),
  // };

  RrRoutes._();

  static const initial = Routes.home;

  //静态配置表
  static final List<Tuple4<String, Widget, Binding, bool>> routeMap = [
    Tuple4(Routes.home, HomePage(), HomeBinding(), true),
    Tuple4(Routes.settings, const SettingView(), SettingBinding(), true),
    Tuple4(Routes.login, const LoginView(), LoginBinding(), false),
    Tuple4(Routes.notification, NotificationView(), NotificationBinding(), true),
    Tuple4(Routes.notificationDetail, NotificationDetailView(), NotificationDetailBinding(), true),
    Tuple4(Routes.phoneCall, CallView(), CallBinding(), true),
    Tuple4(Routes.mediaDetail, MediaView(), MediaBinding(), true),
  ];

  static getPages() {
    List<GetPage<dynamic>> routes = [];
    for (var element in routeMap) {
      routes.add(GetPage(
        name: element.item1,
        page: () => element.item2,
        transition: getRandomEnumValue(Transition.values),
        bindings: [element.item3],
        middlewares: [element.item4 ? EnsureAuthMiddleware() : EnsureNotAuthedMiddleware()],
      ));
    }
    return routes;
    // return [
    //   GetPage(
    //       name: '/',
    //       page: () => HomePage(),
    //       bindings: [HomeBinding()],
    //       participatesInRootNavigator: true,
    //       preventDuplicates: true,
    //       middlewares: [EnsureAuthMiddleware()],
    //       children: routes),
    //   GetPage(
    //     name: Routes.login,
    //     page: () => const LoginView(),
    //     binding: LoginBinding(),
    //   ),
    // ];
  }

  static Transition getRandomEnumValue(List<Transition> values) {
    Random random = Random();
    int index = random.nextInt(values.length);
    return values[index];
  }
}
//todo auto network entity convert

abstract class Routes {
  static const home = _Paths.home;

  static const settings = home + _Paths.settings;
  static const login = home + _Paths.login;
  static const notification = home + _Paths.notification;
  static const notificationDetail = notification + _Paths.notificationDetail;
  static const phoneCall = home + _Paths.phoneCall;
  static const mediaDetail = home + _Paths.mediaDetail;

  static const products = home + _Paths.products;
  static const dashboard = home + _Paths.dashboard;
  static const PAGE_FIREBASE_TESTS = _Paths.PAGE_FIREBASE_TESTS;

  Routes._();

  static String LOGIN_THEN(String afterSuccessfulLogin) =>
      '$login?then=${Uri.encodeQueryComponent(afterSuccessfulLogin)}';

  static String PRODUCT_DETAILS(String productId) => '$products/$productId';

  // 这种写法需要再route中指定全路径或者getpage嵌套，因为是模版生成，没有嵌套关系，所以要指定全路径，
  // 参数是放在parameters中，类型 Map<String, String>? parameters, 使用Uri的path的queryParameters生成类似html的链接
  // 应使用Get.parameters['productId'] ?? '' 获取参数，类型只能是字符串。
  static String NOTIFICATION_DETAILS(ReceivedAction receivedAction) => '$notification/$receivedAction';
}

abstract class _Paths {
  static const home = '/home';
  static const products = '/products';
  static const profile = '/profile';
  static const settings = '/settings';
  static const productDetails = '/:productId';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const notification = '/notification';
  static const notificationDetail = '/notificationDetail';
  static const mediaDetail = '/media-details';
  static const PAGE_FIREBASE_TESTS = '/firebase-tests';
  static const phoneCall = '/phone-call';
}
