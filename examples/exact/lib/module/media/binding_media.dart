import 'package:exact/module/media/repo_media.dart';
import 'package:exact/module/notification_detail/repo_notification_detail.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import 'controller_media.dart';

class MediaBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<MediaController>(() => MediaController()),
      Bind.lazyPut<MediaRepo>(() => MediaRepo()),
    ];
  }
}
