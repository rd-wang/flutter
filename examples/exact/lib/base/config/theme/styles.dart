import 'package:exact/base/config/theme/theme_extensions/header_container_theme_data.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dark_theme_colors.dart';
import 'fonts.dart';
import 'light_theme_colors.dart';
import 'theme_extensions/employee_list_item_theme_data.dart';

class RrStyles {
  /// 自定义员工列表项主题
  ///    var theme = Theme.of(context);
  //     var employeeItemTheme = theme.extension<EmployeeListItemThemeData>();
  static EmployeeListItemThemeData getEmployeeListItemTheme({required bool isLightTheme}) {
    return EmployeeListItemThemeData(
      backgroundColor: isLightTheme
          ? LightThemeColors.employeeListItemBackgroundColor
          : DarkThemeColors.employeeListItemBackgroundColor,
      iconTheme: IconThemeData(
        color: isLightTheme ? LightThemeColors.employeeListItemIconsColor : DarkThemeColors.employeeListItemIconsColor,
      ),
      nameTextStyle: RrFonts.bodyTextStyle.copyWith(
        fontSize: RrFonts.employeeListItemNameSize,
        fontWeight: FontWeight.bold,
        color: isLightTheme ? LightThemeColors.employeeListItemNameColor : DarkThemeColors.employeeListItemNameColor,
      ),
      subtitleTextStyle: RrFonts.bodyTextStyle.copyWith(
        fontSize: RrFonts.employeeListItemSubtitleSize,
        fontWeight: FontWeight.normal,
        color: isLightTheme
            ? LightThemeColors.employeeListItemSubtitleColor
            : DarkThemeColors.employeeListItemSubtitleColor,
      ),
    );
  }

  /// custom header theme
  static HeaderContainerThemeData getHeaderContainerTheme({required bool isLightTheme}) => HeaderContainerThemeData(
          decoration: BoxDecoration(
        color: isLightTheme
            ? LightThemeColors.headerContainerBackgroundColor
            : DarkThemeColors.headerContainerBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ));

  ///icons theme
  static IconThemeData getIconTheme({required bool isLightTheme}) => IconThemeData(
        color: isLightTheme ? LightThemeColors.iconColor : DarkThemeColors.iconColor,
      );

  ///app bar theme
  static AppBarTheme getAppBarTheme({required bool isLightTheme}) => AppBarTheme(
        elevation: 0,
        titleTextStyle: getTextTheme(isLightTheme: isLightTheme).bodyMedium!.copyWith(
              color: Colors.white,
              fontSize: RrFonts.appBarTittleSize,
            ),
        iconTheme:
            IconThemeData(color: isLightTheme ? LightThemeColors.appBarIconsColor : DarkThemeColors.appBarIconsColor),
        backgroundColor: isLightTheme ? LightThemeColors.appBarColor : DarkThemeColors.appbarColor,
      );

  ///text theme
  static TextTheme getTextTheme({required bool isLightTheme}) => TextTheme(
        labelLarge: RrFonts.buttonTextStyle.copyWith(
          fontSize: RrFonts.buttonTextSize,
        ),
        bodyLarge: (RrFonts.bodyTextStyle).copyWith(
          fontWeight: FontWeight.bold,
          fontSize: RrFonts.bodyLargeSize,
          color: isLightTheme ? LightThemeColors.bodyTextColor : DarkThemeColors.bodyTextColor,
        ),
        bodyMedium: (RrFonts.bodyTextStyle).copyWith(
          fontSize: RrFonts.bodyMediumSize,
          color: isLightTheme ? LightThemeColors.bodyTextColor : DarkThemeColors.bodyTextColor,
        ),
        displayLarge: (RrFonts.displayTextStyle).copyWith(
          fontSize: RrFonts.displayLargeSize,
          fontWeight: FontWeight.bold,
          color: isLightTheme ? LightThemeColors.displayTextColor : DarkThemeColors.displayTextColor,
        ),
        bodySmall: TextStyle(
            color: isLightTheme ? LightThemeColors.bodySmallTextColor : DarkThemeColors.bodySmallTextColor,
            fontSize: RrFonts.bodySmallTextSize),
        displayMedium: (RrFonts.displayTextStyle).copyWith(
            fontSize: RrFonts.displayMediumSize,
            fontWeight: FontWeight.bold,
            color: isLightTheme ? LightThemeColors.displayTextColor : DarkThemeColors.displayTextColor),
        displaySmall: (RrFonts.displayTextStyle).copyWith(
          fontSize: RrFonts.displaySmallSize,
          fontWeight: FontWeight.bold,
          color: isLightTheme ? LightThemeColors.displayTextColor : DarkThemeColors.displayTextColor,
        ),
      );

  static ChipThemeData getChipTheme({required bool isLightTheme}) {
    return ChipThemeData(
      backgroundColor: isLightTheme ? LightThemeColors.chipBackground : DarkThemeColors.chipBackground,
      brightness: Brightness.light,
      labelStyle: getChipTextStyle(isLightTheme: isLightTheme),
      secondaryLabelStyle: getChipTextStyle(isLightTheme: isLightTheme),
      selectedColor: Colors.black,
      disabledColor: Colors.green,
      padding: const EdgeInsets.all(5),
      secondarySelectedColor: Colors.purple,
    );
  }

  ///Chips text style
  static TextStyle getChipTextStyle({required bool isLightTheme}) {
    return RrFonts.chipTextStyle.copyWith(
      fontSize: RrFonts.chipTextSize,
      color: isLightTheme ? LightThemeColors.chipTextColor : DarkThemeColors.chipTextColor,
    );
  }

  // elevated button text style
  static MaterialStateProperty<TextStyle?>? getElevatedButtonTextStyle(bool isLightTheme,
      {bool isBold = true, double? fontSize}) {
    return MaterialStateProperty.resolveWith<TextStyle>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return RrFonts.buttonTextStyle.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize ?? RrFonts.buttonTextSize,
            color: isLightTheme ? LightThemeColors.buttonTextColor : DarkThemeColors.buttonTextColor,
          );
        } else if (states.contains(MaterialState.disabled)) {
          return RrFonts.buttonTextStyle.copyWith(
            fontSize: fontSize ?? RrFonts.buttonTextSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isLightTheme ? LightThemeColors.buttonDisabledTextColor : DarkThemeColors.buttonDisabledTextColor,
          );
        }
        return RrFonts.buttonTextStyle.copyWith(
          fontSize: fontSize ?? RrFonts.buttonTextSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isLightTheme ? LightThemeColors.buttonTextColor : DarkThemeColors.buttonTextColor,
        ); // Use the component's default.
      },
    );
  }

  //elevated button theme data
  static ElevatedButtonThemeData getElevatedButtonTheme({required bool isLightTheme}) => ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.r),
              //side: BorderSide(color: Colors.teal, width: 2.0),
            ),
          ),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.symmetric(vertical: 8.h)),
          textStyle: getElevatedButtonTextStyle(isLightTheme),
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return isLightTheme
                    ? LightThemeColors.buttonColor.withOpacity(0.5)
                    : DarkThemeColors.buttonColor.withOpacity(0.5);
              } else if (states.contains(MaterialState.disabled)) {
                return isLightTheme ? LightThemeColors.buttonDisabledColor : DarkThemeColors.buttonDisabledColor;
              }
              return isLightTheme
                  ? LightThemeColors.buttonColor
                  : DarkThemeColors.buttonColor; // Use the component's default.
            },
          ),
        ),
      );

  /// list tile theme data
  static ListTileThemeData getListTileThemeData({required bool isLightTheme}) {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      iconColor: isLightTheme ? LightThemeColors.listTileIconColor : DarkThemeColors.listTileIconColor,
      tileColor: isLightTheme ? LightThemeColors.listTileBackgroundColor : DarkThemeColors.listTileBackgroundColor,
      titleTextStyle: TextStyle(
        fontSize: RrFonts.listTileTitleSize,
        color: isLightTheme ? LightThemeColors.listTileTitleColor : DarkThemeColors.listTileTitleColor,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: RrFonts.listTileSubtitleSize,
        color: isLightTheme ? LightThemeColors.listTileSubtitleColor : DarkThemeColors.listTileSubtitleColor,
      ),
    );
  }
}
