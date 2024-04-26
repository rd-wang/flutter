import 'package:get/get.dart';

import 'base_repository.dart';

///注册子类传入repo，注册类型为子类传入的泛型，repo由子Controller实例化
///可以通过Get.find<T>()获取repo 或者直接引用repo
abstract class RrController<T extends RrRepository> extends GetxController {
  // late final T repo;

  final String? tag = null;

  T get repo => Get.find<T>(tag: tag);

  get pageState => repo.apiCallStatus;

  // RrController(T t) {
  //   repo = t;
  //   Get.put<T>(t);
  // }

  @override
  void onClose() {
    repo.onClear();
    super.onClose();
  }
}
