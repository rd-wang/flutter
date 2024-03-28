import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:exact/base/const_configs.dart';
import 'package:exact/base/network/api_exceptions.dart';
import 'package:exact/base/network/interceptor/token_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class RrNetClient {
  ///超时时间
  static const Duration CONNECT_TIMEOUT = Duration(seconds: 10);
  static const Duration RECEIVE_TIMEOUT = Duration(seconds: 10);
  static const int HTTP_SUCCEED = 10000;
  static const String contentType = 'application/json; charset=UTF-8';

  static final RrNetClient _instance = RrNetClient._internal();

  factory RrNetClient() => _instance;
  Dio? _client;

  Dio? get dioService => _client;

  /// 创建 dio 实例对象
  RrNetClient._internal() {
    if (_client == null) {
      _setClient();
    }
  }

  /// 设置Client
  void _setClient() {
    /// 全局属性：请求前缀、连接超时时间、响应超时时间
    _client =
        Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: CONNECT_TIMEOUT, receiveTimeout: RECEIVE_TIMEOUT, headers: {
      HttpHeaders.userAgentHeader: userAgent,
      HttpHeaders.contentTypeHeader: contentType,
      HttpHeaders.acceptLanguageHeader: acceptLanguage.isEmpty ? _getDefaultAcceptLanguage : acceptLanguage,
      HttpHeaders.authorizationHeader: authorizationStr ?? '',
      'os': kIsWeb ? "web" : Platform.operatingSystem,
      'version': appVersion,
      'X-Channel': appChannel,
      'X-Udid': appUuid,
      'uc': userCode,
    }));
    if (!isRelease) {
      _client!.interceptors.add(PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90));
    }
    _client!.interceptors.add(TokenInterceptor());
    if (ConstantConfig.localProxy.isNotEmpty) {
      _client!.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) {
            // 将请求代理至 localhost:8888。
            // 请注意，代理会在你正在运行应用的设备上生效，而不是在宿主平台生效。
            return ConstantConfig.localProxy;
          };
          return client;
        },
      );
    }
  }

  /// 重置Client
  void resetClient() {
    _client = null;
    _setClient();
  }

  /// 获取默认请求头信息
  String get _getDefaultAcceptLanguage {
    String appLanguage = currentLanguage;
    if (appLanguage.contains('zh')) {
      return 'zh-CN,zh;q=0.9';
    } else {
      return 'en-US,en;q=0.9,en;q=0.8';
    }
  }
}

///http请求成功回调
typedef HttpSuccessCallback<T> = void Function(T result);

///失败回调
typedef HttpFailureCallback = void Function(HttpError err);
