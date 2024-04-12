import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/base/base/base_controller.dart';
import 'package:get/get.dart';

import 'repo_notification_detail.dart';

class NotificationDetailPageController extends RrController<NotificationDetailRepo> {
  late ReceivedAction receivedAction;

  @override
  onInit() {
    receivedAction = Get.arguments;
    super.onInit();
    repo.loadNothing();
  }
}
