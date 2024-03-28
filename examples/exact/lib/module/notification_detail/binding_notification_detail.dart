import 'package:exact/module/notification_detail/repo_notification_detail.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import 'controller_notification_detail.dart';

class NotificationBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<NotificationDetailPageController>(() => NotificationDetailPageController()),
      Bind.lazyPut<NotificationDetailRepo>(() => NotificationDetailRepo()),
    ];
  }
}
