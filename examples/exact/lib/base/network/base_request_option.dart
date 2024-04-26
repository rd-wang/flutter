import 'dart:core';

import 'package:dio/dio.dart';
import 'package:exact/base/components/snackbar.dart';
import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:exact/base/network/api_exceptions.dart';
import 'package:get/get_utils/get_utils.dart';

enum RequestType {
  get,
  post,
  put,
  delete,
}

mixin RrNetOptionsMixin {
  /// handle unexpected error
  handleUnexpectedException({Function(ApiException)? onError, required String url, required Object error}) {
    if (onError != null) {
      onError(ApiException(
        message: error.toString(),
        url: url,
      ));
    } else {
      handleError(error.toString());
    }
  }

  /// handle timeout exception
  handleTimeoutException({Function(ApiException)? onError, required String url}) {
    if (onError != null) {
      onError(ApiException(
        message: Strings.serverNotResponding.tr,
        url: url,
      ));
    } else {
      handleError(Strings.serverNotResponding.tr);
    }
  }

  /// handle timeout exception
  handleSocketException({Function(ApiException)? onError, required String url}) {
    if (onError != null) {
      onError(ApiException(
        message: Strings.noInternetConnection.tr,
        url: url,
      ));
    } else {
      handleError(Strings.noInternetConnection.tr);
    }
  }

  /// handle Dio error
  handleDioError({required DioException error, Function(ApiException)? onError, required String url}) {
    // 404 error
    if (error.response?.statusCode == 404) {
      if (onError != null) {
        return onError(ApiException(
          message: Strings.urlNotFound.tr,
          url: url,
          statusCode: 404,
        ));
      } else {
        return handleError(Strings.urlNotFound.tr);
      }
    }

    // no internet connection
    if (error.message != null && error.message!.toLowerCase().contains('socket')) {
      if (onError != null) {
        return onError(ApiException(
          message: Strings.noInternetConnection.tr,
          url: url,
        ));
      } else {
        return handleError(Strings.noInternetConnection.tr);
      }
    }

    // check if the error is 500 (server problem)
    if (error.response?.statusCode == 500) {
      var exception = ApiException(
        message: Strings.serverError.tr,
        url: url,
        statusCode: 500,
      );

      if (onError != null) {
        return onError(exception);
      } else {
        return handleApiError(exception);
      }
    }

    var exception = ApiException(
        url: url,
        message: error.message ?? 'Un Expected Api Error!',
        response: error.response,
        statusCode: error.response?.statusCode);
    if (onError != null) {
      return onError(exception);
    } else {
      return handleApiError(exception);
    }
  }

  /// handle error automaticly (if user didnt pass onError) method
  /// it will try to show the message from api if there is no message
  /// from api it will show the reason (the dio message)
  handleApiError(ApiException apiException) {
    String msg = apiException.toString();
    RrSnackBar.showCustomErrorToast(message: msg);
  }

  /// handle errors without response (500, out of time, no internet,..etc)
  handleError(String msg) {
    RrSnackBar.showCustomErrorToast(message: msg);
  }
}
