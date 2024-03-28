import 'package:exact/base/base/base_repository.dart';
import 'package:exact/base/config/translations/strings_enum.dart';
import 'package:exact/base/const_configs.dart';
import 'package:exact/base/network/base_request_option.dart';
import 'package:exact/routes/routes.dart';
import 'package:get/get.dart';

import '../entity/entity_feature.dart';

class FeatureRepo extends RrRepository {
  void feedBackList(Map<String, dynamic> data) {
    loadFromNet(
      "$baseUrl/api/ww/app/task/feedback/v1/page",
      RequestType.post,
      onSuccess: (re) {},
      queryParameters: data,
    );
  }

  List<FeatureEntity> getFeatureList() {
    return [
      FeatureEntity(
          title: Strings.goSetting.tr, description: "", imageUrl: "", onTap: () => Get.toNamed(Routes.settings)),
      FeatureEntity(title: Strings.login.tr, description: "", imageUrl: "", onTap: () => Get.toNamed(Routes.login)),
      FeatureEntity(
          title: Strings.notification.tr, description: "", imageUrl: "", onTap: () => Get.toNamed(Routes.notification)),
    ];
  }

  @override
  reloadData() {
    feedBackList(lastRequestParams!);
  }
}
