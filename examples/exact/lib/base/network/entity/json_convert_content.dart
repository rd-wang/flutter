import 'base_request_entity.dart';

mixin class JsonConvertUtil<T> {
  T fromJson(Map<String, dynamic> json) {
    return _getFromJson<T>(runtimeType, this, json);
  }

  Map<String, dynamic> toJson() {
    return _getToJson<T>(runtimeType, this);
  }

  static _getFromJson<T>(Type type, data, json) {
    switch (type) {
      case BaseRequestEntity _:
        return baseRequestEntityFromJson(data as BaseRequestEntity, json) as T;
    }
    return data as T;
  }

  static _getToJson<T>(Type type, data) {
    switch (type) {
      case BaseRequestEntity _:
        return baseRequestEntityToJson(data as BaseRequestEntity);
    }
    return data as T;
  }

  //Go back to a single instance by type
  static _fromJsonSingle(String type, json) {
    switch (type) {
      case 'BaseRequestEntity':
        return BaseRequestEntity().fromJson(json);
    }
    return null;
  }

  //empty list is returned by type
  static _getListFromType(String type) {
    switch (type) {
      case 'BaseRequestEntity':
        return List<BaseRequestEntity>.empty(growable: true);
    }
    return null;
  }

  static M fromJsonAsT<M>(json) {
    String type = M.toString();
    if (json is List && type.contains("List<")) {
      String itemType = type.substring(5, type.length - 1);
      List tempList = _getListFromType(itemType);
      json.forEach((itemJson) {
        tempList.add(_fromJsonSingle(type.substring(5, type.length - 1), itemJson));
      });
      return tempList as M;
    } else {
      return _fromJsonSingle(M.toString(), json) as M;
    }
  }
}

baseRequestEntityFromJson(BaseRequestEntity data, Map<String, dynamic> json) {
  if (json['params'] != null) {
    data.params = json['params']?.toString();
  }
  if (json['sign'] != null) {
    data.sign = json['sign']?.toString();
  }
  if (json['timeStamp'] != null) {
    data.timeStamp = json['timeStamp']?.toString();
  }
  return data;
}

Map<String, dynamic> baseRequestEntityToJson(BaseRequestEntity entity) {
  final Map<String, dynamic> data = <String, dynamic>{};
  data['params'] = entity.params;
  data['sign'] = entity.sign;
  data['timeStamp'] = entity.timeStamp;
  return data;
}