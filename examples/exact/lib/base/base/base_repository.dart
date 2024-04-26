import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:exact/base/network/api_call_status.dart';
import 'package:exact/base/network/api_exceptions.dart';
import 'package:exact/base/network/base_request_option.dart';
import 'package:exact/base/network/net_work_client.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:logger/logger.dart';

abstract class RrRepository with RrNetOptionsMixin {
  late RrNetClient _netClient;
  var cancelToken = CancelToken();
  var apiCallStatus = ApiCallStatus.loading.obs;

  Dio get dioClient => _netClient.dioService!;

  RrRepository() {
    _netClient = RrNetClient();
  }

  void onClear() {
    cancelToken.cancel();
  }

  Map<String, dynamic>? lastRequestParams;

  reloadData();

  loadNothing() async {
    apiCallStatus.value = ApiCallStatus.success;
  }

  loadFromNet(
    String url,
    RequestType requestType, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    required Function(Response response) onSuccess,
    Function(ApiException)? onError,
    Function(int value, int progress)? onReceiveProgress,
    Function(int total, int progress)? onSendProgress, // while sending (uploading) progress
    Function? onLoading,
    dynamic data,
  }) async {
    try {
      // 1) indicate loading state
      await onLoading?.call();
      apiCallStatus.value = ApiCallStatus.loading;
      lastRequestParams = queryParameters;
      await Future.delayed(const Duration(seconds: 2));
      // 2) try to perform http request
      late Response response;
      if (requestType == RequestType.get) {
        response = await dioClient.get(
          url,
          onReceiveProgress: onReceiveProgress,
          queryParameters: queryParameters,
          options: Options(
            headers: headers,
          ),
          cancelToken: cancelToken,
        );
      } else if (requestType == RequestType.post) {
        response = await dioClient.post(
          url,
          data: data,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
      } else if (requestType == RequestType.put) {
        response = await dioClient.put(
          url,
          data: data,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
      } else {
        response = await dioClient.delete(
          url,
          data: data,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
      }
      // 3) return response (api done successfully)
      await onSuccess(response);
      apiCallStatus.value = ApiCallStatus.success;
    } on DioException catch (error) {
      // dio error (api reach the server but not performed successfully
      apiCallStatus.value = ApiCallStatus.error;
      handleDioError(error: error, url: url, onError: onError);
    } on SocketException {
      // No internet connection
      apiCallStatus.value = ApiCallStatus.error;
      handleSocketException(url: url, onError: onError);
    } on TimeoutException {
      // Api call went out of time
      apiCallStatus.value = ApiCallStatus.error;
      handleTimeoutException(url: url, onError: onError);
    } catch (error, stackTrace) {
      // print the line of code that throw unexpected exception
      Logger().e(stackTrace);
      // unexpected error for example (parsing json error)
      apiCallStatus.value = ApiCallStatus.error;
      handleUnexpectedException(url: url, onError: onError, error: error);
    }
  }

  /// download file
  download(
      {required String url, // file url
      required String savePath, // where to save file
      Function(ApiException)? onError,
      Function(int value, int progress)? onReceiveProgress,
      required Function onSuccess}) async {
    try {
      await dioClient.download(
        url,
        savePath,
        options: Options(
          receiveTimeout: RrNetClient.RECEIVE_TIMEOUT,
          sendTimeout: RrNetClient.RECEIVE_TIMEOUT,
        ),
        onReceiveProgress: onReceiveProgress,
      );
      onSuccess();
    } catch (error) {
      var exception = ApiException(url: url, message: error.toString());
      onError?.call(exception) ?? handleError(error.toString());
    }
  }
}

enum AppEnv { dev, online, pre }
