import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:exact/base/base/base_controller.dart';
import 'package:exact/base/notifications/notifications_controller.dart';
import 'package:get/get.dart';

import 'repo_call.dart';

class CallController extends RrController<CallRepo> {
  late ReceivedAction receivedAction;

  @override
  onInit() {
    receivedAction = Get.arguments ?? NotificationsController.initialCallAction;
    super.onInit();
    repo.loadNothing();
  }
}
