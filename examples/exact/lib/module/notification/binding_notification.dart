import 'package:exact/module/notification/repo_notification.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import 'controller_notification.dart';

class NotificationBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<NotificationPageController>(() => NotificationPageController()),
      Bind.lazyPut<NotificationRepo>(() => NotificationRepo()),
    ];
  }
}
