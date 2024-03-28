import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';

class RrToast {
  /// 3.5秒
  static const int _longDuration = 3500;

  /// 2秒
  static const int _shortDuration = 2000;

  /// 通用的显示吐司方法，显示时长2秒
  static void showShort(String text,
      {BuildContext? context,
      ToastPosition? position,
      TextStyle? textStyle,
      EdgeInsetsGeometry? textPadding,
      Color? backgroundColor,
      double? radius,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool? dismissOtherToast,
      TextAlign? textAlign,
      OKToastAnimationBuilder? animationBuilder,
      Duration? animationDuration,
      Curve? animationCurve}) {
    _show(text,
        textStyle: textStyle,
        dismissOtherToast: dismissOtherToast,
        context: context,
        duration: Duration(milliseconds: _shortDuration),
        position: position,
        backgroundColor: backgroundColor,
        radius: radius,
        onDismiss: onDismiss,
        textDirection: textDirection,
        textAlign: textAlign,
        animationBuilder: animationBuilder,
        animationDuration: animationDuration,
        animationCurve: animationCurve);
  }

  /// 通用的显示吐司方法，显示时长3.5秒
  static void showLong(String text,
      {BuildContext? context,
      ToastPosition? position,
      TextStyle? textStyle,
      EdgeInsetsGeometry? textPadding,
      Color? backgroundColor,
      double? radius,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool? dismissOtherToast,
      TextAlign? textAlign,
      OKToastAnimationBuilder? animationBuilder,
      Duration? animationDuration,
      Curve? animationCurve}) {
    _show(text,
        textStyle: textStyle,
        dismissOtherToast: dismissOtherToast,
        context: context,
        duration: Duration(milliseconds: _longDuration),
        position: position,
        backgroundColor: backgroundColor,
        radius: radius,
        onDismiss: onDismiss,
        textDirection: textDirection,
        textAlign: textAlign,
        animationBuilder: animationBuilder,
        animationDuration: animationDuration,
        animationCurve: animationCurve);
  }

  static void _show(String text,
      {BuildContext? context,
      TextStyle? textStyle,
      Duration? duration,
      ToastPosition? position,
      Color? backgroundColor,
      double? radius,
      VoidCallback? onDismiss,
      TextDirection? textDirection,
      bool? dismissOtherToast,
      TextAlign? textAlign,
      OKToastAnimationBuilder? animationBuilder,
      Duration? animationDuration,
      Curve? animationCurve}) {
    showToast(text,
        textStyle: textStyle ?? TextStyle(fontSize: 14.r, color: Colors.white),
        textPadding: EdgeInsets.only(left: 30.r, right: 30.r, top: 10.r, bottom: 10.r),
        dismissOtherToast: dismissOtherToast ?? true,
        backgroundColor: const Color(0xBD000000),
        radius: 8.0,
        context: context,
        duration: duration,
        position: position,
        onDismiss: onDismiss,
        textDirection: textDirection,
        textAlign: textAlign,
        animationBuilder: animationBuilder,
        animationDuration: animationDuration,
        animationCurve: animationCurve);
  }
}
