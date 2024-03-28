import 'package:exact/base/base/base_repository.dart';

const bool isRelease = bool.fromEnvironment("dart.vm.product");

/// 请求路径
String baseUrl = 'https://uat-bj.vvtechnology.cn';

/// 当前语言
String currentLanguage = "zh";

/// 请求头部信息
String? authorizationStr = "";

/// 当前渠道
String appChannel = "Other";

/// 用户代理
String userAgent = "";

/// 当前版本
String appVersion = "";

/// 当前设备号
String appUuid = "";

/// 用户信息
String userCode = "";

/// 语言请求头
String acceptLanguage = "";

class GlobalConfig {
  static const env = AppEnv.dev;
}

class ConstantConfig {
  /// 请求头校验支付
  static const String authorization = "authorization";

  ///格式：PROXY 192.168.5.5:8888
  static String localProxy = '';
}
