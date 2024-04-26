import 'dart:io';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String url;
  final String message;
  final int? statusCode;
  final Response? response;

  ApiException({
    required this.url,
    required this.message,
    this.response,
    this.statusCode,
  });

  /// IMPORTANT NOTE
  /// here you can take advantage of toString() method to display the error for user
  /// lets make an example
  /// so in onError method when you make api you can just user apiExceptionInstance.toString() to get the error message from api
  @override
  toString() {
    String result = '';

    // TODO add error message field which is coming from api for you (For ex: response.data['error']['message']
    result += response?.data?['error'] ?? '';

    if (result.isEmpty) {
      result += message; // message is the (dio error message) so usualy its not user friendly
    }

    return result;
  }
}

class ResponseException implements Exception {
  final code;
  final message;
  final errorData;

  ResponseException({this.code, this.message, this.errorData});

  String toString() {
    if (message == null) return "Exception";
    return "$message errorData $errorData}";
  }
}

class HttpError {
  ///HTTP 状态码
  static const int UNAUTHORIZED = 401;
  static const int FORBIDDEN = 403;
  static const int NOT_FOUND = 404;
  static const int REQUEST_TIMEOUT = 408;
  static const int INTERNAL_SERVER_ERROR = 500;
  static const int BAD_GATEWAY = 502;
  static const int SERVICE_UNAVAILABLE = 503;
  static const int GATEWAY_TIMEOUT = 504;

  ///未知错误
  static const String UNKNOWN = "UNKNOWN";

  ///解析错误
  static const String PARSE_ERROR = "PARSE_ERROR";

  ///网络错误
  static const String NETWORK_ERROR = "NETWORK_ERROR";

  ///协议错误
  static const String HTTP_ERROR = "HTTP_ERROR";

  ///证书错误
  static const String SSL_ERROR = "SSL_ERROR";

  ///连接超时
  static const String CONNECT_TIMEOUT = "CONNECT_TIMEOUT";
  static const String CONNECT_ERROR = "CONNECT_ERROR";

  ///响应超时
  static const String RECEIVE_TIMEOUT = "RECEIVE_TIMEOUT";

  ///发送超时
  static const String SEND_TIMEOUT = "SEND_TIMEOUT";

  ///网络请求取消
  static const String CANCEL = "CANCEL";

  ///定义调用原生aop代码
  static const String ANDROID_AOP = "habit";
  static const String ANDROID_AOP_LOGIN_METHOD = "go2Login";

  String code = '';

  String message = '';

  HttpError(this.code, this.message);

  HttpError.checkNetError(dynamic error, {bool ignoreToast = false}) {
    if (error is DioException) {
      message = error.message!;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          code = CONNECT_TIMEOUT;
          message = netException;
          break;
        case DioExceptionType.receiveTimeout:
          code = RECEIVE_TIMEOUT;
          message = netException;
          break;
        case DioExceptionType.sendTimeout:
          code = SEND_TIMEOUT;
          message = netException;
          break;
        case DioExceptionType.badResponse:
          var statusCode = error.response?.statusCode;
          if (statusCode == HttpStatus.unauthorized) {}
          code = HTTP_ERROR + statusCode.toString();
          message = netException;
          break;
        case DioExceptionType.cancel:
          code = CANCEL;
          break;
        case DioExceptionType.unknown:
          code = UNKNOWN;
          message = netException;
          break;
        case DioExceptionType.badCertificate:
          code = SSL_ERROR;
          message = netException;
          break;
        case DioExceptionType.connectionError:
          code = CONNECT_ERROR;
          message = netException;
          break;
      }
    } else if (error is ResponseException) {
      code = error.code.toString();
      message = error.message;
    } else {
      code = UNKNOWN;
      message = error.toString();
    }
    if (!ignoreToast && message.isNotEmpty) {
      print(message);
      // RrToast.showShort(message);
    }
  }

  String get netException => "无网络，请检查网络";

  @override
  String toString() {
    return 'HttpError{code: $code, message: $message}';
  }
}
