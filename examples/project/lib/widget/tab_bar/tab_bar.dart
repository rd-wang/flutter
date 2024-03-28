import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../values/colors.dart';
import 'common_tabbar_indicator.dart';

class RrTabBar extends StatelessWidget {
  final List<Widget> tabs;

  const RrTabBar({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      padding: EdgeInsets.symmetric(horizontal: 4.r),
      unselectedLabelColor: RrColor.color_858B9B,
      unselectedLabelStyle: TextStyle(
        fontSize: 14.sp,
        color: RrColor.color_858B9B,
        fontFamily: "PingFang SC",
        fontWeight: FontWeight.w400,
      ),
      labelColor: RrColor.color_2A2F3C,
      labelStyle: TextStyle(
        fontSize: 14.sp,
        color: RrColor.color_2A2F3C,
        fontFamily: "PingFang SC",
        fontWeight: FontWeight.w500,
      ),
      isScrollable: true,
      labelPadding: EdgeInsets.symmetric(horizontal: 12.r),
      indicatorPadding: EdgeInsets.only(bottom: 1),
      indicator: CommonUnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2.r,
            color: RrColor.color_5590F6,
          ),
          indicatorWidth: 24.r),
      tabs: tabs,
    );
  }
}
