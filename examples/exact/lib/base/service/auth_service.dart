import 'package:exact/base/components/loading_overlay.dart';
import 'package:exact/base/local/shared_pref.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  /// Mocks a login process
  final isLoggedIn = RrSharedPref.isLogin().obs;

  get isLogin => isLoggedIn.value;

  login() async {
    await showLoadingOverLay(asyncFunction: () async {
      await Future.delayed(const Duration(seconds: 2));
      isLoggedIn.value = true;
      RrSharedPref.setLoginToken("token");
    });
  }

  logout() async {
    await showLoadingOverLay(asyncFunction: () async {
      await Future.delayed(const Duration(seconds: 2));
      isLoggedIn.value = false;
      RrSharedPref.clearLoginToken();
    });
  }
}
