import 'dart:convert';

import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:null/generated/json/base/json_field.dart';
import 'package:null/generated/json/tab_entity_entity.g.dart';
export 'package:null/generated/json/tab_entity_entity.g.dart';

@JsonSerializable()
class TabEntity {
  String? fieldCode;
  @JsonKey(defaultValue: "未知")
  String? fieldName;
  bool? checked;
  bool? mustCheck;
  int? count;
  int? unreadCount;

  TabEntity({this.fieldCode, this.fieldName, this.checked, this.mustCheck, this.count, this.unreadCount});

  @JsonKey(includeFromJson: false, includeToJson: false)
  var badge = 0.obs;
  @JsonKey(includeFromJson: false, includeToJson: false)
  var total = 0.obs;

  //弹层的内容
  String? get title {
    if (fieldName == null) return null;
    if ((count ?? 0) > 99) {
      return "$fieldName 99+";
    }
    if (count == 0) {
      return "$fieldName";
    }
    return "$fieldName ${count ?? 0}";
  }

  String get countString {
    if ((count ?? 0) > 99) {
      return " 99+";
    }
    if (count == 0) {
      return "";
    }
    return " ${count ?? 0}";
  }

  factory TabEntity.fromJson(Map<String, dynamic> json) => _$TabEntityFromJson(json);

  Map<String, dynamic> toJson() => _$TabEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
