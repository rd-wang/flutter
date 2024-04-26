import 'dart:convert';

PersonTimeDetailBean personTimeDetailBeanFromJson(String str) =>
    PersonTimeDetailBean.fromJson(json.decode(str));

String personTimeDetailBeanToJson(PersonTimeDetailBean data) =>
    json.encode(data.toJson());

class PersonTimeDetailBean {
  String? employeeCode;
  String? dateStr;
  List<TaskDetailLaborTimePageVoList>? taskDetailLaborTimePageVoList;

  PersonTimeDetailBean({
    this.employeeCode,
    this.dateStr,
    this.taskDetailLaborTimePageVoList,
  });

  PersonTimeDetailBean copyWith({
    String? employeeCode,
    String? dateStr,
    List<TaskDetailLaborTimePageVoList>? taskDetailLaborTimePageVoList,
  }) =>
      PersonTimeDetailBean(
        employeeCode: employeeCode ?? this.employeeCode,
        dateStr: dateStr ?? this.dateStr,
        taskDetailLaborTimePageVoList:
            taskDetailLaborTimePageVoList ?? this.taskDetailLaborTimePageVoList,
      );

  factory PersonTimeDetailBean.fromJson(Map<String, dynamic> json) =>
      PersonTimeDetailBean(
        employeeCode: json["employeeCode"],
        dateStr: json["dateStr"],
        taskDetailLaborTimePageVoList:
            json["taskDetailLaborTimePageVOList"] == null
                ? []
                : List<TaskDetailLaborTimePageVoList>.from(
                    json["taskDetailLaborTimePageVOList"]!
                        .map((x) => TaskDetailLaborTimePageVoList.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "employeeCode": employeeCode,
        "dateStr": dateStr,
        "taskDetailLaborTimePageVOList": taskDetailLaborTimePageVoList == null
            ? []
            : List<dynamic>.from(
                taskDetailLaborTimePageVoList!.map((x) => x.toJson())),
      };
}

class TaskDetailLaborTimePageVoList {
  int? id;
  int? laborTimeStartTime;
  int? laborTimeEndTime;
  int? laborTimeValue;
  String? executorCode;
  ExecutorPhoto? executorPhoto;
  int? sex;
  String? executorName;

  /// 1. 负责人 2.执行人 3参与人
  int? memberType;
  int? laborTimeType;

  ///0 结束  1进行中
  int? laborTimeStatus;
  String? createUser;
  bool? deleteAdditionLaborTimeAuth;
  String? taskCode;
  String? taskName;
  String? createEmployeeCode;
  String? executionContentCode;
  String? executionContent;

  ///1.参与工时 2.执行工时 3.正在进行中的工时
  int executoType() {
    if (memberType == 1 || memberType == 2) {
      if (laborTimeStatus == 1) {
        return 3;
      } else {
        return 2;
      }
    }
    if (memberType == 3) {
      return 1;
    }

    if (laborTimeStatus == 1) {
      return 3;
    }

    return 2;
  }

  TaskDetailLaborTimePageVoList({
    this.id,
    this.laborTimeStartTime,
    this.laborTimeEndTime,
    this.laborTimeValue,
    this.executorCode,
    this.executorPhoto,
    this.sex,
    this.executorName,
    this.memberType,
    this.laborTimeType,
    this.laborTimeStatus,
    this.createUser,
    this.deleteAdditionLaborTimeAuth,
    this.taskCode,
    this.taskName,
    this.createEmployeeCode,
    this.executionContentCode,
    this.executionContent,
  });

  TaskDetailLaborTimePageVoList copyWith({
    int? id,
    int? laborTimeStartTime,
    int? laborTimeEndTime,
    int? laborTimeValue,
    String? executorCode,
    ExecutorPhoto? executorPhoto,
    int? sex,
    String? executorName,
    int? memberType,
    int? laborTimeType,
    int? laborTimeStatus,
    String? createUser,
    bool? deleteAdditionLaborTimeAuth,
    String? taskCode,
    String? taskName,
    String? createEmployeeCode,
    String? executionContentCode,
    String? executionContent,
  }) =>
      TaskDetailLaborTimePageVoList(
        id: id ?? this.id,
        laborTimeStartTime: laborTimeStartTime ?? this.laborTimeStartTime,
        laborTimeEndTime: laborTimeEndTime ?? this.laborTimeEndTime,
        laborTimeValue: laborTimeValue ?? this.laborTimeValue,
        executorCode: executorCode ?? this.executorCode,
        executorPhoto: executorPhoto ?? this.executorPhoto,
        sex: sex ?? this.sex,
        executorName: executorName ?? this.executorName,
        memberType: memberType ?? this.memberType,
        laborTimeType: laborTimeType ?? this.laborTimeType,
        laborTimeStatus: laborTimeStatus ?? this.laborTimeStatus,
        createUser: createUser ?? this.createUser,
        deleteAdditionLaborTimeAuth:
            deleteAdditionLaborTimeAuth ?? this.deleteAdditionLaborTimeAuth,
        taskCode: taskCode ?? this.taskCode,
        taskName: taskName ?? this.taskName,
        createEmployeeCode: createEmployeeCode ?? this.createEmployeeCode,
        executionContentCode: executionContentCode ?? this.executionContentCode,
        executionContent: executionContent ?? this.executionContent,
      );

  factory TaskDetailLaborTimePageVoList.fromJson(Map<String, dynamic> json) =>
      TaskDetailLaborTimePageVoList(
        id: json["id"],
        laborTimeStartTime: json["laborTimeStartTime"],
        laborTimeEndTime: json["laborTimeEndTime"],
        laborTimeValue: json["laborTimeValue"],
        executorCode: json["executorCode"],
        executorPhoto: json["executorPhoto"] == null
            ? null
            : ExecutorPhoto.fromJson(json["executorPhoto"]),
        sex: json["sex"],
        executorName: json["executorName"],
        memberType: json["memberType"],
        laborTimeType: json["laborTimeType"],
        laborTimeStatus: json["laborTimeStatus"],
        createUser: json["createUser"],
        deleteAdditionLaborTimeAuth: json["deleteAdditionLaborTimeAuth"],
        taskCode: json["taskCode"],
        taskName: json["taskName"],
        createEmployeeCode: json["createEmployeeCode"],
        executionContentCode: json["executionContentCode"],
        executionContent: json["executionContent"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "laborTimeStartTime": laborTimeStartTime,
        "laborTimeEndTime": laborTimeEndTime,
        "laborTimeValue": laborTimeValue,
        "executorCode": executorCode,
        "executorPhoto": executorPhoto?.toJson(),
        "sex": sex,
        "executorName": executorName,
        "memberType": memberType,
        "laborTimeType": laborTimeType,
        "laborTimeStatus": laborTimeStatus,
        "createUser": createUser,
        "deleteAdditionLaborTimeAuth": deleteAdditionLaborTimeAuth,
        "taskCode": taskCode,
        "taskName": taskName,
        "createEmployeeCode": createEmployeeCode,
        "executionContentCode": executionContentCode,
        "executionContent": executionContent,
      };
}

class ExecutorPhoto {
  int? id;
  String? relationCode;
  String? keyName;
  String? sysCode;
  int? seq;
  int? s3Type;
  DateTime? createTime;
  DateTime? updateTime;
  String? extra;
  String? fileName;
  String? url;
  Thumbnails? thumbnails;

  ExecutorPhoto({
    this.id,
    this.relationCode,
    this.keyName,
    this.sysCode,
    this.seq,
    this.s3Type,
    this.createTime,
    this.updateTime,
    this.extra,
    this.fileName,
    this.url,
    this.thumbnails,
  });

  ExecutorPhoto copyWith({
    int? id,
    String? relationCode,
    String? keyName,
    String? sysCode,
    int? seq,
    int? s3Type,
    DateTime? createTime,
    DateTime? updateTime,
    String? extra,
    String? fileName,
    String? url,
    Thumbnails? thumbnails,
  }) =>
      ExecutorPhoto(
        id: id ?? this.id,
        relationCode: relationCode ?? this.relationCode,
        keyName: keyName ?? this.keyName,
        sysCode: sysCode ?? this.sysCode,
        seq: seq ?? this.seq,
        s3Type: s3Type ?? this.s3Type,
        createTime: createTime ?? this.createTime,
        updateTime: updateTime ?? this.updateTime,
        extra: extra ?? this.extra,
        fileName: fileName ?? this.fileName,
        url: url ?? this.url,
        thumbnails: thumbnails ?? this.thumbnails,
      );

  factory ExecutorPhoto.fromJson(Map<String, dynamic> json) => ExecutorPhoto(
        id: json["id"],
        relationCode: json["relationCode"],
        keyName: json["keyName"],
        sysCode: json["sysCode"],
        seq: json["seq"],
        s3Type: json["s3Type"],
        createTime: json["createTime"] == null
            ? null
            : DateTime.parse(json["createTime"]),
        updateTime: json["updateTime"] == null
            ? null
            : DateTime.parse(json["updateTime"]),
        extra: json["extra"],
        fileName: json["fileName"],
        url: json["url"],
        thumbnails: json["thumbnails"] == null
            ? null
            : Thumbnails.fromJson(json["thumbnails"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "relationCode": relationCode,
        "keyName": keyName,
        "sysCode": sysCode,
        "seq": seq,
        "s3Type": s3Type,
        "createTime": createTime?.toIso8601String(),
        "updateTime": updateTime?.toIso8601String(),
        "extra": extra,
        "fileName": fileName,
        "url": url,
        "thumbnails": thumbnails?.toJson(),
      };
}

class Thumbnails {
  String? key;

  Thumbnails({
    this.key,
  });

  Thumbnails copyWith({
    String? key,
  }) =>
      Thumbnails(
        key: key ?? this.key,
      );

  factory Thumbnails.fromJson(Map<String, dynamic> json) => Thumbnails(
        key: json["key"],
      );

  Map<String, dynamic> toJson() => {
        "key": key,
      };
}
