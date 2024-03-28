import 'package:get/get.dart';
import 'package:main/home/entity/entity_feature_botton.dart';

class HomePageController extends GetxController {
  var count = 0.obs;
  var crossAxisCount = 3.obs;
  List<FeatureButtonEntity> items = [
    FeatureButtonEntity(
      title: "Shop",
      image: "assets/images/ic_shop.png",
      route: "/shop",
    )
  ].obs;

  @override
  void onInit() {
    super.onInit();

    count.value++;
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
  }
}
