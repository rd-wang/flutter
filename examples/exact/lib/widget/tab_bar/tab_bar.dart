import 'package:exact/widget/tab_bar/entity/entity_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../values/colors.dart';
import 'common_tabbar_indicator.dart';

class RrTabBar extends StatelessWidget {
  final List<TabEntity> tabs;

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
        indicatorPadding: EdgeInsets.only(bottom: 1.h),
        indicator: CommonUnderlineTabIndicator(
            borderSide: BorderSide(
              width: 2.r,
              color: RrColor.color_5590F6,
            ),
            indicatorWidth: 24.r),
        tabs: tabs.map((e) {
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: e.leftIcon != null,
                  child: Padding(
                    padding: EdgeInsets.only(top: 3.w, right: 2.w),
                    child: Icon(e.leftIcon, size: 16),
                  ),
                ),
                Text(e.title),
                Visibility(
                    visible: e.isUnread ?? false,
                    child: Container(
                      margin: EdgeInsets.only(left: 2.w),
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFf55656),
                      ),
                    ))
              ],
            ),
          );
        }).toList());
  }
}
