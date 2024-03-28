import 'package:exact/base/base/base_controller.dart';
import 'package:exact/module/home/data_repo/repo_feature.dart';
import 'package:exact/widget/tab_bar/entity/entity_tabs.dart';
import 'package:get/get.dart';

class FeaturePageController extends RrController<FeatureRepo> {
  var count = 0.obs;
  var crossAxisCount = 3.obs;
  List<TabEntity> items = [];

  // FeaturePageController() : super(FeatureRepo());

  @override
  void onInit() {
    super.onInit();
    repo.feedBackList({});
    count.value++;
  }

  reloadData() {
    repo.feedBackList({});
  }
}
