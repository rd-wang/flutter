import 'dart:convert';

import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:exact/base/extensions/date_extension.dart';
import 'package:exact/base/extensions/number_extension.dart';
import 'package:exact/values/colors.dart';
import 'package:exact/widget/person_time_detail_bean.dart';
import 'package:exact/widget/task_timer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/get_utils.dart';

/// 工时明细列表列表
class TaskManHourDetailListPage extends StatefulWidget {
  PersonTimeDetailBean? itemBean;

  TaskManHourDetailListPage();

  @override
  State<StatefulWidget> createState() {
    return TaskManHourDetailListState();
  }
}

class TaskManHourDetailListState extends State<TaskManHourDetailListPage> {
  late TaskTimer _timer;
  bool landscape = false;
  PersonTimeDetailBean? bean = PersonTimeDetailBean.fromJson(json.decode(
      '{"employeeCode":"oa1356438706047647746","dateStr":"2024-01-23","taskDetailLaborTimePageVOList":[{"id":4152,"laborTimeStartTime":1705999600000,"laborTimeEndTime":1705999629000,"laborTimeValue":29,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":1,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"1732242936222241013","executionContent":"执行内容 (默认)"},{"id":4151,"laborTimeStartTime":1705999544000,"laborTimeEndTime":1705999596000,"laborTimeValue":52,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"1732242936222241013","executionContent":"执行内容 (默认)"},{"id":4150,"laborTimeStartTime":1705998162000,"laborTimeEndTime":1705999540000,"laborTimeValue":1378,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"1732242936222241013","executionContent":"执行内容 (默认)"},{"id":4149,"laborTimeStartTime":1705997472000,"laborTimeEndTime":1705998095000,"laborTimeValue":623,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"","executionContent":""},{"id":4148,"laborTimeStartTime":1705996959000,"laborTimeEndTime":1705997327000,"laborTimeValue":368,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"","executionContent":""},{"id":4147,"laborTimeStartTime":1705996767000,"laborTimeEndTime":1705996937000,"laborTimeValue":170,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"","executionContent":""},{"id":4146,"laborTimeStartTime":1705996321000,"laborTimeEndTime":1705996748000,"laborTimeValue":427,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"","executionContent":""},{"id":4145,"laborTimeStartTime":1705996289000,"laborTimeEndTime":1705996299000,"laborTimeValue":10,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"1732242936222241013","executionContent":"执行内容 (默认)"},{"id":4144,"laborTimeStartTime":1705995850000,"laborTimeEndTime":1705996289000,"laborTimeValue":439,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"","executionContent":""},{"id":4143,"laborTimeStartTime":1705995703000,"laborTimeEndTime":1705995822000,"laborTimeValue":119,"executorCode":"oa1356438706047647746","executorPhoto":{},"sex":null,"executorName":"","memberType":1,"laborTimeType":1,"laborTimeStatus":null,"createUser":"","deleteAdditionLaborTimeAuth":false,"taskCode":"1717734109504540674","taskName":"测试190-父任务","createEmployeeCode":"","executionContentCode":"","executionContent":""}]}'));

  // bean = PersonTimeDetailBean.fromJson(json
  //     .decode('{"employeeCode":"oa1356438706047647746","dateStr":"2024-01-23","taskDetailLaborTimePageVOList":[]}'));
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.destroyTimer();
    }
    super.dispose();
  }

  void initTimer(int timerSecond) {
    _timer = TaskTimer(initSeconds: timerSecond ?? 0);
    _timer.startTimer();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    if (width > height && landscape == false) {
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
              "",
            ),
          ),
          Flexible(
            child: ListView.builder(
              itemCount: bean?.taskDetailLaborTimePageVoList?.length ?? 0,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return getTimeDetailItem(bean!.taskDetailLaborTimePageVoList![index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getTimeDetailItem(TaskDetailLaborTimePageVoList item) {
    if (item.laborTimeStatus == 1) {
      // initTimer(item.laborTimeValue ?? 0);
      initTimer(
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(item.laborTimeStartTime!)).inSeconds ?? 0);
    }
    return GestureDetector(
      onTap: () async {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
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
                  getLabel(getTabIndex(item)),
                  item.laborTimeStatus == 1
                      ? ValueListenableBuilder<int>(
                          valueListenable: _timer.totalSeconds,
                          builder: (BuildContext context, int value, Widget? child) {
                            return Padding(
                              padding: EdgeInsets.only(left: 8.h, bottom: 1.h),
                              child: Text(
                                _timer.timeString(_timer.currentSeconds),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          })
                      : Container(),
                  Padding(
                    padding: EdgeInsets.only(left: 8.h, right: 8.h, top: 1.h),
                    child: Text(
                      getDatetime(item),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Text(
                    item.laborTimeValue.toHHMMSS(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 执行内容，一会要一会不要 留着吧
            // Text(
            //   item.executionContent ?? "",
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            //   style: TextStyle(
            //     fontSize: 12.sp,
            //     fontWeight: FontWeight.w400,
            //   ),
            // ).visibility(visible: !item.executionContent.isNullOrEmpty()),
            Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.taskName ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3.h)),
                    ),
                    child: Text(
                      "aaaa",
                    ),
                  ),
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

  String getDatetime(TaskDetailLaborTimePageVoList item) {
    String? endTimeStr = item.laborTimeEndTime?.toDateContent("HH:mm");
    return "${item.laborTimeStartTime?.toDateContent("HH:mm")}~${endTimeStr == '00:00' ? "24:00" : endTimeStr}";
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
      case 1:
        return RrColor.color_5590F6;
      case 2:
        return RrColor.color_145590F6;
      case 3:
        return RrColor.color_F6F7F8;
    }
  }

  getLabelTextColor(int i) {
    switch (i) {
      case 1:
        return RrColor.color_FFFFFF;
      case 2:
        return RrColor.color_5590F6;
      case 3:
        return Color(0xffA0A6B5);
    }
  }

  int getTabIndex(TaskDetailLaborTimePageVoList item) {
    if (item.memberType == 3) {
      return 3;
    }
    if (item.laborTimeStatus == 1) {
      return 1;
    }
    return 2;
  }

  String getLabelText(int i) {
    switch (i) {
      case 1:
        return Strings.hello.tr;
      case 2:
        return Strings.hello.tr;
      default:
        return Strings.hello.tr;
    }
  }
}
