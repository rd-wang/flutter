//stateless widget for the feature tab
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:main/home/controller/controller_home.dart';

class FeatureTab extends StatelessWidget {
  const FeatureTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Get.find<HomePageController>().crossAxisCount.value,
          crossAxisSpacing: 10.h,
          mainAxisSpacing: 10.h,
          childAspectRatio: 1.3,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Stack(
            children: <Widget>[
              Container(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12.r)),
                  child: Image.network(
                    width: double.infinity,
                    height: double.infinity,
                    "https://picsum.photos/350/400?image=${index + 10}",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 10.h,
                top: 30.h,
                right: 10.h,
                bottom: 30.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8.r)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4.h, sigmaY: 4.h),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        "Item ${Get.find<HomePageController>().count.value} $index",
                        style: TextStyle(fontSize: 14.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
