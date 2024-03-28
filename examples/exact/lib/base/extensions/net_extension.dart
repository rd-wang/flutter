import 'package:exact/base/network/entity/base_response_entity.dart';
import 'package:exact/base/network/entity/json_convert_content.dart';

extension NetExtension<T> on Future<BaseResponseEntity<T>> {
  Future<T?> transform(T? Function(dynamic json) action) async {
    var baseResponseEntity = await this;
    return Future.value(action(baseResponseEntity.data));
  }

  Future<List<T?>?> transformList(T? Function(dynamic json) action) async {
    var baseResponseEntity = await this;
    var dataList = baseResponseEntity.data as List;
    return Future.value(dataList.map((e) => action(e)).toList());
  }

  Future<T> check() async {
    var baseResponseEntity = await this;
    return Future.value(JsonConvertUtil.fromJsonAsT<T>(baseResponseEntity.data));
  }

  Future<List<String>?> checkListStr() async {
    var baseResponseEntity = await this;
    if (baseResponseEntity.data == null) {
      return Future.value(null);
    }
    final data = baseResponseEntity.data as List;
    final result = data.map((e) => e.toString()).toList();
    return Future.value(result);
  }

// Future<List<T>?> checkList() async {
//   var baseResponseEntity = await this;
//   return Future.value(JsonConvertUtil.convertListNotNull(baseResponseEntity.data));
// }
}
