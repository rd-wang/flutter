import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

/// 此方法将显示黑色覆盖层，看起来像对话框，并且内部有加载动画，
/// 这将确保用户无法与 ui 交互，直到任何（异步）方法正在执行，因为它将等待异步函数结束，然后它将关闭覆盖层
showLoadingOverLay({
  required Future<dynamic> Function() asyncFunction,
  String? msg,
}) async {
  await Get.showOverlay(
    asyncFunction: () async {
      try {
        await asyncFunction();
      } catch (error) {
        Logger().e(error);
        Logger().e(StackTrace.current);
      }
    },
    loadingWidget: Center(
      child: _getLoadingIndicator(msg: msg),
    ),
    opacity: 0.7,
    opacityColor: Colors.black,
  );
  return Future.value(true);
}

Widget _getLoadingIndicator({String? msg}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: 20.w,
      vertical: 10.h,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10.r),
      color: Colors.white,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/app_icon.png',
          height: 45.h,
        ),
        SizedBox(
          width: 8.h,
        ),
        Text(msg ?? Strings.loading.tr, style: Get.theme.textTheme.bodyLarge),
      ],
    ),
  );
}
