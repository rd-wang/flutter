// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_tabs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TabEntity _$TabEntityFromJson(Map<String, dynamic> json) => TabEntity(
      json['tabId'] as int?,
      json['tabName'] as String? ?? '未知',
      json['count'] as int?,
      json['showCount'] as bool?,
      json['isUnread'] as bool?,
      json['unReadCount'] as int?,
    );

Map<String, dynamic> _$TabEntityToJson(TabEntity instance) => <String, dynamic>{
      'tabId': instance.tabId,
      'tabName': instance.tabName,
      'count': instance.count,
      'showCount': instance.showCount,
      'isUnread': instance.isUnread,
      'unReadCount': instance.unReadCount,
    };
