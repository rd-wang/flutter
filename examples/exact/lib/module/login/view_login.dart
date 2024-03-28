import 'package:exact/base/base/base_view.dart';
import 'package:exact/base/service/auth_service.dart';
import 'package:exact/module/login/controller_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../base/config/translations/strings_enum.dart';
import '../../routes/routes.dart';

class LoginView extends RrView<LoginController> {
  const LoginView({super.key});

  @override
  String setTitle() {
    return Strings.login.tr;
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(children: [
      Obx(
        () {
          final isLoggedIn = AuthService.to.isLogin;
          return Text(
            'You are currently:'
            ' ${isLoggedIn ? "Logged In" : "Not Logged In"}'
            "\nIt's impossible to enter this "
            "route when you are logged in!",
          );
        },
      ),
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
        child: InkWell(
          onTap: () async {
            await AuthService.to.login();
            final thenTo = context.params['then'];
            Get.offNamed(thenTo ?? Routes.home);
          },
          child: Ink(
            child: Text(Strings.login.tr),
          ),
        ),
      ),

      10.horizontalSpace,

      //----------------Language Button----------------//
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
        child: InkWell(
          onTap: () async {
            await Get.find<AuthService>().logout();
            Get.offNamed(Routes.home);
          },
          child: Ink(
            child: Text(Strings.logout.tr),
          ),
        ),
      ),
    ]);
  }
}
