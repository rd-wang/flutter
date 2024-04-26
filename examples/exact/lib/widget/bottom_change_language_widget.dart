import 'package:exact/base/config/translations/localization_service.dart';
import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:exact/values/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ChangeLanguagePage extends StatelessWidget {
  bool landscape = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    if (width > height && !kIsWeb) {
      landscape = true;
    }
    if (landscape) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24.h), bottomLeft: Radius.circular(24.h)),
          boxShadow: [
            BoxShadow(color: RrColor.color_26000000, blurRadius: 32.h, spreadRadius: 0, offset: Offset(0, 8.h)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        width: landscape ? 0.48.sw : 1.sw,
        alignment: Alignment.topRight,
        child: body(context),
      );
    } else {
      return body(context);
    }
  }

  Container body(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  height: kToolbarHeight,
                  margin: const EdgeInsets.only(left: kToolbarHeight),
                  child: Text(
                    Strings.changeLanguage.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: kToolbarHeight,
                height: kToolbarHeight,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.close,
                    size: 24.h,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: landscape ? 0.48.sw : 1.sw,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.h),
            child: Text(
              "${Strings.currentLanguage.tr}: ${RrLocalizationService.getCurrentLocal().languageCode}",
            ),
          ),
          Flexible(
            child: ListView.builder(
              itemCount: RrLocalizationService.supportedLanguages.values.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return getItem(index, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getItem(int index, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        var chooseCode = RrLocalizationService.supportedLanguages.values.elementAt(index).languageCode;
        Navigator.of(context).pop(chooseCode);
        // Get.back(result: chooseCode);
      },
      child: Padding(
        padding: EdgeInsets.only(top: 14.h, left: 16.h, right: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  getLabel(index),
                ],
              ),
            ),
            const Divider(
              height: 1,
            )
          ],
        ),
      ),
    );
  }

  getLabel(int i) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.h),
      decoration: BoxDecoration(
        color: getLabelBgColor(i),
        borderRadius: BorderRadius.all(Radius.circular(3.h)),
      ),
      child: Text(
        getLabelText(i),
        style: TextStyle(color: getLabelTextColor(i), fontSize: 10.sp, fontWeight: FontWeight.w400),
      ),
    );
  }

  getLabelBgColor(int i) {
    switch (i) {
      // case 1:
      //   return RrColor.color_5590F6;
      // case 2:
      //   return RrColor.color_145590F6;
      // case 3:
      //   return RrColor.color_F6F7F8;
      default:
        return RrColor.color_5590F6;
    }
  }

  getLabelTextColor(int i) {
    switch (i) {
      // case 1:
      //   return RrColor.color_FFFFFF;
      // case 2:
      //   return RrColor.color_5590F6;
      // case 3:
      //   return Color(0xffA0A6B5);
      default:
        return RrColor.color_FFFFFF;
    }
  }

  String getLabelText(int i) {
    var languageCode = RrLocalizationService.supportedLanguages.values.elementAt(i).languageCode;
    switch (languageCode) {
      case "zh":
        return Strings.zh.tr;
      case "en":
        return Strings.en.tr;
      case "ar":
        return Strings.ar.tr;

      default:
        return Strings.zh.tr;
    }
  }
}
