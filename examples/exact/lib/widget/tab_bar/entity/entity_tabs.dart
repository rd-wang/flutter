import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';

part 'entity_tabs.g.dart';

@JsonSerializable()
class TabEntity {
  int? tabId;
  @JsonKey(defaultValue: "未知")
  String? tabName;
  int? count;
  bool? showCount;
  bool? isUnread;
  int? unReadCount;

  TabEntity(this.tabId, this.tabName, this.count, this.showCount, this.isUnread, this.unReadCount);

  @JsonKey(includeFromJson: false, includeToJson: false)
  IconData? leftIcon;
  @JsonKey(includeFromJson: false, includeToJson: false)
  var badge = 0.obs;
  @JsonKey(includeFromJson: false, includeToJson: false)
  var total = 0.obs;

  //弹层的内容
  String get title {
    if (tabName == null) return "";
    if ((count ?? 0) > 99) {
      return "$tabName 99+";
    }
    if (count == 0) {
      return "$tabName";
    }
    return "$tabName ${count ?? 0}";
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
