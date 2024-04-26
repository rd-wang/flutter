import 'package:exact/module/home/controller/controller_home.dart';
import 'package:exact/module/home/data_repo/repo_feature.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class HomeBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<FeaturePageController>(() => FeaturePageController()),
      Bind.lazyPut<FeatureRepo>(() => FeatureRepo()),
    ];
  }
}
