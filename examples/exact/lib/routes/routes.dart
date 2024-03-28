import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/module/home/binding/binding_home.dart';
import 'package:exact/module/login/binding_login.dart';
import 'package:exact/module/login/view_login.dart';
import 'package:exact/module/notification/view_notification.dart';
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
  ];

  static getPages() {
    List<GetPage<dynamic>> routes = [];
    routeMap.forEach((element) {
      routes.add(GetPage(
        name: element.item1,
        page: () => element.item2,
        transition: getRandomEnumValue(Transition.values),
        bindings: [element.item3],
        middlewares: [element.item4 ? EnsureAuthMiddleware() : EnsureNotAuthedMiddleware()],
      ));
    });
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

  static const profile = _Paths.home + _Paths.profile;
  static const settings = _Paths.settings;

  static const products = _Paths.home + _Paths.products;

  static const login = _Paths.login;
  static const dashboard = _Paths.home + _Paths.dashboard;
  static const notification = _Paths.notification;
  static const notificationDetail = _Paths.notification + _Paths.notificationDetail;
  static const PAGE_MEDIA_DETAILS = _Paths.PAGE_MEDIA_DETAILS;
  static const PAGE_NOTIFICATION_DETAILS = _Paths.PAGE_NOTIFICATION_DETAILS;
  static const PAGE_FIREBASE_TESTS = _Paths.PAGE_FIREBASE_TESTS;
  static const PAGE_PHONE_CALL = _Paths.PAGE_PHONE_CALL;

  Routes._();

  static String LOGIN_THEN(String afterSuccessfulLogin) =>
      '$login?then=${Uri.encodeQueryComponent(afterSuccessfulLogin)}';

  static String PRODUCT_DETAILS(String productId) => '$products/$productId';

  static String NOTIFICATION_DETAILS(ReceivedAction notification_action) => '$notification/$notification_action';
}

abstract class _Paths {
  static const home = '/';
  static const products = '/products';
  static const profile = '/profile';
  static const settings = '/settings';
  static const productDetails = '/:productId';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const notification = '/notification';
  static const notificationDetail = '/:notification_action';
  static const PAGE_MEDIA_DETAILS = '/media-details';
  static const PAGE_NOTIFICATION_DETAILS = '/notification-details';
  static const PAGE_FIREBASE_TESTS = '/firebase-tests';
  static const PAGE_PHONE_CALL = '/phone-call';
}
