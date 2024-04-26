import 'package:exact/module/notification_detail/repo_notification_detail.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

import 'controller_call.dart';

class NotificationDetailBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<CallController>(() => CallController()),
      Bind.lazyPut<NotificationDetailRepo>(() => NotificationDetailRepo()),
    ];
  }
}
